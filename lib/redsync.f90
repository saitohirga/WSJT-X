subroutine redsync(ss,ntrperiod,ihsym,iz,red)

! Compute the red curve (approx JT9 sync amplitude).
! NB: red() is used for real-time display only.  A better ccfred() is
! computed during the decode procedure.

  Parameter (NSMAX=22000)
  real*4 ss(184,NSMAX)
  real*4 red(NSMAX)
  include 'jt9sync.f90'

  lagmax=9
  if(ntrperiod.eq.2) lagmax=5
  if(ntrperiod.eq.5) lagmax=2
  if(ntrperiod.eq.10) lagmax=1
  if(ntrperiod.eq.30) lagmax=1

  do i=1,iz                                !Loop over frequency range
     smax=0.
     do lag=-lagmax,lagmax                 !Loop over DT lags
        sig=0.
        do j=1,16
           k=ii2(j)+lag
           if(k.ge.5 .and. k.le.ihsym) then
              sig=sig + ss(k,i) - 0.5*(ss(k-2,i)+ss(k-4,i))
           endif
        enddo
        if(sig.gt.smax) smax=sig
     enddo
     red(i)=smax
  enddo
  call pctile(red,iz,40,xmed)
  if(xmed.le.0.0) xmed=1.0
  red=red/xmed
  smax=0.
  do i=1,iz
     red(i)=0.2*db(red(i))
     smax=max(smax,red(i))
  enddo
  h=10.
  if(smax.gt.h) red=red*(h/smax)

  return
end subroutine redsync
