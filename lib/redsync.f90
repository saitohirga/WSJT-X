subroutine redsync(ss,ntrperiod,ihsym,iz,red)

  Parameter (NSMAX=22000)
  real*4 ss(184,NSMAX)
  real*4 red(NSMAX)
  include 'jt9sync.f90'

  lagmax=9
  if(ntrperiod.eq.2) lagmax=5
  if(ntrperiod.eq.5) lagmax=2
  if(ntrperiod.eq.10) lagmax=1
  if(ntrperiod.eq.30) lagmax=1

  do i=1,iz
     smax=0.
     do lag=-lagmax,lagmax
        sig=0.
        ns=0
        ref=0.
        nr=0
        do j=1,16
           k=ii2(j)+lag
           if(k.ge.1 .and. k.le.ihsym) then
              sig=sig + ss(k,i)
              ns=ns+1
           endif
           do n=k+2,k+8,2
              if(n.ge.1 .and. n.le.ihsym) then
                 ref=ref + ss(n,i)
                 nr=nr+1
              endif
           enddo
        enddo
        s=0.
        if(ref.gt.0.0) s=(sig/ns)/(ref/nr)
        if(s.gt.smax) smax=s
     enddo
!     red(i)=db(smax)
     red(i)=smax
  enddo

  return
end subroutine redsync
        
