subroutine specjtms(k)

! Starting code for a JTMS3 decoder.

  parameter (NSMAX=30*48000)
  parameter (NFFT=16384,NH=NFFT/2)
  character*22 decoded
  character*72 c72
  integer*2 id
  real x(NFFT),w(NFFT)
  real p(24)
  real rsent(258),softsym(683),sym2(258)
  integer nsum(24)
  complex cx(NFFT),cx2(NFFT),cx0(NFFT)
  complex covx(NH)
  real s1a(NH),s2a(NH)
  integer mettab(0:255,0:1)             !Metric table
  integer data4a(9)                     !Decoded data (8-bit byte values)
  integer data4(12)                     !Decoded data (6-bit byte values)
  integer*1 data1(13)
  integer*1 isync(43)
  integer*1 chansym1(258),datsym2(215)
  logical first,window
  integer*1 i1
  equivalence (i1,i4)
  common/mscom/id(1440000),s1(215,703),s2(215,703)
  data first/.true./
  save

  if(first) then
     pi=4.0*atan(1.0)
     twopi=2.0*pi
     do i=1,nfft
        w(i)=(sin(i*pi/nfft))**2
     enddo
     df=48000.0/nfft
     ja=nint(2600.0)/df
     jb=nint(3400.0)/df
     iz=3000.0/df
     covx=0.
     kstep=4096
     read(10,3001) rsent
3001 format(50f1.0)
     do i=1,258,6
        rsent(i)=0.
     enddo
     rsent=2.0*rsent - 1.0

     open(11,file='bpskmetrics.dat',status='old')
     bias=0.5
     scale=20.0
     do i=0,255
        read(11,*) xjunk,x0,x1
        mettab(i,0)=nint(scale*(x0-bias))
        mettab(i,1)=nint(scale*(x1-bias))
     enddo
     close(11)
     window=.false.
     first=.false.
  endif

  ib=k
  ia=k-kstep+1
  i0=k-nfft+1
  sq=0.
  do i=ia,ib
     sq=sq + (0.001*id(i))**2
  enddo
  write(13,1010) t,sq,db(sq)
1010 format(3f12.3)
  if(k.lt.nfft) return

  x(1:nfft)=0.001*id(i0:ib)

  fac=2.0/nfft
  cx=fac*x
  if(window) cx=w*cx
  call four2a(cx,nfft,1,-1,1)                    !Forward c2c FFT

  do i=1,iz                                      !Save spectrum for plot
     s1a(i)=real(cx(i+1))**2 + aimag(cx(i+1))**2
  enddo

  cx(1)=0.5*cx(1)
  cx(nh+2:nfft)=0.
  call four2a(cx,nfft,1,1,1)                     !Inverse c2c FFT
  if(window) then
     cx(1:nh)=cx(1:nh)+covx(1:nh)               !Add previous segment's 2nd half
     covx(1:nh)=cx(nh+1:nfft)                    !Save 2nd half
  endif

  t=k/48000.0
  cx2=cx*cx
  call four2a(cx2,nfft,1,-1,1)                   !Forward c2c FFT of cx2

  spk0=0.
  do j=ja,jb
     sq=1.e-6*(real(cx2(j))**2 + aimag(cx2(j))**2)
     s2a(j)=sq
     f=(j-1)*df
     if(sq.gt.spk0) then
        spk0=sq
        f0=0.5*(f-3000.0)
        phi0=0.5*atan2(aimag(cx2(j)),real(cx2(j)))
     endif
     write(15,1020) f,sq
1020 format(f10.3,f12.3)
  enddo

  slimit=2.5
!  if(spk0.gt.slimit) then
  if(abs(spk0-43.5).lt.0.1) then
     write(*,1030) t,f0,phi0,spk0
1030 format('t:',f6.2,'   f0:',f7.1,'   phi0:',f6.2,'   spk0:',f8.1)

     phi=phi0
     phi=3.9                                   !### test ###
     dphi=twopi*(f0+1500.0 -1.1)/48000.0
     p=0.
     nsum=0
     do i=1,nfft
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi        
        cx0(i)=cx(i)*cmplx(cos(phi),-sin(phi))
        pha=atan2(aimag(cx0(i)),real(cx0(i)))
!        write(18,1060) i,cx0(i),pha
!1060    format(i6,5f12.3)
        j=mod(i-1,24) + 1
!        p(j)=p(j)+abs(cx0(i))
        p(j)=p(j) + real(cx0(i))**2 + aimag(cx0(i))**2
        nsum(j)=nsum(j)+1
     enddo

     do i=1,24
        p(i)=p(i)/nsum(i)
        write(20,1070) i,p(i)
1070    format(i6,f12.3)
     enddo

     do i=19,nfft,24
        amp=abs(cx0(i))
        pha=atan2(aimag(cx0(i)),real(cx0(i)))
        j=(i+23)/24
        write(21,1060) j,cx0(i),pha,pha+twopi,amp
1060    format(i6,5f12.3)
        softsym(j)=real(cx0(i))
     enddo

!     do iter=1,5
     rsent=cshift(rsent,86)
     lagmax=nfft/24 - 258
     do lag=0,lagmax
        sum=dot_product(rsent,softsym(lag+1:lag+258))
        if(abs(sum).gt.smax) then
           smax=abs(sum)
           lagpk=lag
        endif
        write(22,1080) lag,sum
1080    format(i3,f12.3)
     enddo
!     rsent=cshift(rsent,43)
!     enddo

     do i=1,258
        j=mod(i-1+2580,258) + 1
        prod=rsent(j)*softsym(lagpk+i)
        nchsym=nint(0.5*(rsent(j)+1.0))
        write(23,1090) i,prod,rsent(j),softsym(lagpk+i),j,nchsym,lagpk+i
1090    format(i5,3f10.3,3i5)
        
     enddo
     
     sym2=softsym(lagpk+1:lagpk+258)
     sym2=cshift(sym2,-86)
     do i=1,258
        i4=128 + nint(6.0*sym2(i))
        if(i4.lt.0) i4=0
        if(i4.gt.255) i4=255
        chansym1(i)=i1
        write(24,2001) i,sym2(i),i4,chansym1(i)
2001    format(i6,f8.3,2i6)
     enddo
  endif

end subroutine specjtms
