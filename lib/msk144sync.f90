subroutine msk144sync(cdat,n,ntol,ndf,navmask,npeaks,fest,npklocs,nsuccess,c)

  parameter (NSPM=864)
  complex cdat(n)
  complex cdat2(n)
  complex c(NSPM)                    !Coherently averaged complex data
  complex ct2(2*NSPM)
  complex cs(NSPM)
  complex cb(42)                     !Complex waveform for sync word 
  complex cc(0:NSPM-1)

  integer s8(8)
  integer iloc(1)
  integer npklocs(npeaks)
  integer navmask(8)                 ! defines which frames to average

  real cbi(42),cbq(42)
  real pkamps(npeaks)
  real xcc(0:NSPM-1)
  real xccs(0:NSPM-1)
  real pp(12)                        !Half-sine pulse shape
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  save first,cb,fs,pi,twopi,dt,s8,pp

!  call system_clock(count0,clkfreq)
  if(first) then
     pi=4.0*atan(1.0)
     twopi=8.0*atan(1.0)
     fs=12000.0
     dt=1.0/fs

     do i=1,12                       !Define half-sine pulse
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
     enddo

! Define the sync word waveforms
     s8=2*s8-1  
     cbq(1:6)=pp(7:12)*s8(1)
     cbq(7:18)=pp*s8(3)
     cbq(19:30)=pp*s8(5)
     cbq(31:42)=pp*s8(7)
     cbi(1:12)=pp*s8(2)
     cbi(13:24)=pp*s8(4)
     cbi(25:36)=pp*s8(6)
     cbi(37:42)=pp(1:6)*s8(8)
     cb=cmplx(cbi,cbq)

     first=.false.
  endif

  navg=sum(navmask) 
  xmax=0.0
  bestf=0.0
  do ifr=-ntol,ntol,ndf            !Find freq that maximizes sync
     ferr=ifr
     call tweak1(cdat,n,-(1500+ferr),cdat2)
     c=0
     do i=1,8
        ib=(i-1)*NSPM+1
        ie=ib+NSPM-1
        if( navmask(i) .eq. 1 ) then
          c(1:NSPM)=c(1:NSPM)+cdat2(ib:ie)
        endif
     enddo

     cc=0
     ct2(1:NSPM)=c
     ct2(NSPM+1:2*NSPM)=c
     do ish=0,NSPM-1
        cc(ish)=dot_product(ct2(1+ish:42+ish)+ct2(336+ish:377+ish),cb(1:42))
     enddo

     xcc=abs(cc)
     xb=maxval(xcc)/(48.0*sqrt(float(navg)))
     if(xb.gt.xmax) then
        xmax=xb
        bestf=ferr
        cs=c
        xccs=xcc
     endif
  enddo

  fest=1500+bestf
  c=cs
  xcc=xccs

! Find npeaks largest peaks
  do ipk=1,npeaks
     iloc=maxloc(xcc)
     ic2=iloc(1)
     npklocs(ipk)=ic2
     pkamps(ipk)=xcc(ic2-1)
     xcc(max(0,ic2-7):min(NSPM-1,ic2+7))=0.0
  enddo

  if( xmax .lt. 0.7 ) then
    nsuccess=0
  else
    nsuccess=1
  endif

  return
end subroutine msk144sync
