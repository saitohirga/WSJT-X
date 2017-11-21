subroutine foxgen(t)

  parameter (NN=79,KK=87,NSPS=4*1920)
  parameter (NWAVE=NN*NSPS,NFFT=614400,NH=NFFT/2)
  character*(*) t
  character*22 msg,msgsent
  character*12 t1
  character*6 MyCall,MyGrid
  logical bcontest
  integer itone(NN)
  integer*1 msgbits(KK)
  integer*8 count0,count1,clkfreq
  real wave(NWAVE)
  real x(NFFT),y(NFFT)
  real*8 dt,twopi,f0,fstep,dfreq,phi,dphi
  complex cx(0:NH),cy(0:NH)
  common/foxcom/wave
  equivalence (x,cx),(y,cy)

  call system_clock(count0,clkfreq)
  MyCall='KH1DX'
  MyGrid='AJ10  '
  bcontest=.false.
  i3bit=0
  fstep=60.d0
  dfreq=6.25d0
  dt=1.d0/48000.d0
  twopi=8.d0*atan(1.d0)
  wave=0.

  m=len(t)
  i=0
  i0=1
  do n=1,5
     do j=1,12
        i=i+1
        if(i.eq.m .or. ichar(t(i:i)).eq.10) then
           if(i.ne.m) t1=t(i0:i-1)
           if(i.eq.m) t1=t(i0:i)
           i1=index(t1,' ')
           msg=t1(1:i1)//MyCall//t1(i1:)
           iz=len(trim(msg))
           do iter=1,5                     !Collapse multiple blanks into one
              ib2=index(msg(1:iz),'  ')
              if(ib2.lt.1) exit
              msg=msg(1:ib2)//msg(ib2+2:)
              iz=iz-1
           enddo
           exit
        endif
     enddo
     i0=i+1
     call genft8(msg,mygrid,bcontest,i3bit,msgsent,msgbits,itone)
     
     f0=1500.d0 + fstep*(n-1)
     phi=0.d0
     k=0
     do j=1,NN
        f=f0 + dfreq*itone(j)
        dphi=twopi*f*dt
        do ii=1,NSPS
           k=k+1
           phi=phi+dphi
           xphi=phi
           wave(k)=wave(k)+sin(xphi)
        enddo
     enddo
     
     call system_clock(count1,clkfreq)
     time=float(count1-count0)/float(clkfreq)    !Cumulative execution time
     write(*,3001) n,k,i,time,msgsent
3001 format(i1,i8,i4,f10.6,2x,a22)
     if(i.ge.m) exit
  enddo

  sqx=0.
  do i=1,NWAVE
     sqx=sqx + wave(i)*wave(i)
  enddo
  sigmax=sqrt(sqx/NWAVE)
  wave=wave/sigmax                    !Force rms=1.0

  do i=1,NWAVE
     wave(i)=h1(wave(i))              !Compress the waveform
  enddo
  
  fac=1.0/maxval(abs(wave))           !Set maxval = 1.0
  wave=fac*wave

  if(NWAVE.ne.-99) go to 100             !### Omit filtering, for now ###

  x(1:k)=wave
  x(k+1:)=0.
  call four2a(x,nfft,1,-1,0)

  nadd=64
  k=0
  df=48000.0/NFFT
  rewind(29)
  do i=1,NH/nadd - 1
     sx=0.
!     sy=0.
     do j=1,nadd
        k=k+1
        sx=sx + real(cx(k))**2 + aimag(cx(k))**2
!        sy=sy + real(cy(k))**2 + aimag(cy(k))**2
     enddo
     freq=df*(k-nadd/2+0.5)
     write(29,1022) freq,sx,sy,db(sx)-90.0,db(sy)-90.0
1022 format(f10.3,2e12.3,2f10.3)
     if(freq.gt.3000.0) exit
  enddo
  flush(29)

100 call system_clock(count1,clkfreq)
  time=float(count1-count0)/float(clkfreq)    !Cumulative execution time
!  write(*,3010) time
!3010 format('Time:',f10.6)
  
  return
end subroutine foxgen

real function h1(x)

!  sigma=1.0/sqrt(2.0)
  sigma=1.0
  xlim=sigma/sqrt(6.0)
  ax=abs(x)
  sgnx=1.0
  if(x.lt.0) sgnx=-1.0
  if(ax.le.xlim) then
     h1=x
  else
     z=exp(1.0/6.0 - (ax/sigma)**2)
     h1=sgnx*sqrt(6.0)*sigma*(2.0/3.0 - 0.5*z)
  endif

  return
end function h1
