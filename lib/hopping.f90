subroutine txbandtot(tx,ibtot)
  integer tx(10,6), ibtot(10)
  do j=1,10
    ibtot(j)=0
    do i=1,6
      ibtot(j)=ibtot(j)+tx(j,i)
    enddo
  enddo
  return
end subroutine txbandtot

subroutine txadd(tx,iband)
!add one tx to the requested band
  integer tx(10,6)
  isuccess=0
  do k=1,10
    call random_number(rr)
    islot=rr*6
    islot=islot+1
    if( islot .gt. 6 ) then  
      write(*,*) "should not happen" 
      islot=6 
    endif
    if( tx(iband,islot).eq.0 ) then
      tx(iband,islot)=1
      isuccess=1
    endif
    if( isuccess.eq.1 ) then
      exit
    endif
  enddo
  return
end subroutine txadd 
    
subroutine txtrim(tx,ntxmax,ntot)
!limit sequential runlength to ntxmax 
  integer tx(10,6)
  nrun=0
  do i=1,6
    do j=1,10
      if( tx(j,i).eq.1 ) then        
        nrun=nrun+1
        if(nrun.gt.ntxmax) then
          tx(j,i)=0  
          nrun=0 
        endif
      else
        nrun=0
      endif
    enddo
  enddo

  ntot=0
  do j=1,10
    do i=1,6
      if(tx(j,i).eq.1) then
        ntot=ntot+1
      endif
    enddo
  enddo
return
end subroutine txtrim

subroutine hopping(nyear,month,nday,uth,mygrid,nduration,npctx,isun,   &
     iband,ntxnext)

! Determine Rx or Tx in coordinated hopping mode.

  character*6 mygrid
  integer tx(10,6)    !T/R array for 2 hours: 10 bands, 6 time slots
  real r(6)           !Random numbers
  integer ii(1),ibtot(10)
  data n2hr0/-999/
  save n2hr0,tx

  call grayline(nyear,month,nday,uth,mygrid,nduration,isun)

  ns0=uth*3600.0
  pctx=npctx
  nrx=0
  ntxnext=0
  nsec=(ns0+10)/120                   !Round up to start of next 2-min slot
  nsec=nsec*120
  n2hr=nsec/7200                      !2-hour slot number

  if(n2hr.ne.n2hr0) then
! Compute a new Rx/Tx pattern for this 2-hour interval
     n2hr0=n2hr                       !Mark this one as done
     tx=0                             !Clear the tx array
     do j=1,10                        !Loop over all 10 bands
        call random_number(r)
        do i=1,6,2                    !Select one each of 3 pairs of the 
           if(r(i).gt.r(i+1)) then    !  6 slots for Tx
              tx(j,i)=1
              r(i+1)=0.
           else
              tx(j,i+1)=1
              r(i)=0.
           endif
        enddo

        if(pctx.lt.50.0) then         !If pctx < 50, we may kill one Tx slot
           ii=maxloc(r)
           i=ii(1)
           call random_number(rr)
           rrtest=(50.0-pctx)/16.667
           if(rr.lt.rrtest) then
              tx(j,i)=0
              r(i)=0.
           endif
        endif

        if(pctx.lt.33.333) then       !If pctx < 33, may kill another
           ii=maxloc(r)
           i=ii(1)
           call random_number(rr)
           rrtest=(33.333-pctx)/16.667
           if(rr.lt.rrtest) then
              tx(j,i)=0
              r(i)=0.
           endif
        endif
     enddo

! We now have 1 to 3 Tx periods per band in the 2-hour interval.
! Now, iteratively massage the array to try to satisfy the constraints
     ntxlimit=2
     if( pctx .lt. 33.333 ) then
       minperband=1
     elseif( (pctx .ge. 33.333) .and. (pctx .lt. 50.0) ) then 
       minperband=2
     else
       minperband=3
     endif
     n_needed=60*pctx/100+0.5
! Allow up to 20 iterations
     do k=1,20
       call txtrim(tx,ntxlimit,ntot)
       call txbandtot(tx,ibtot) 
!       write(*,3001) ibtot
       do j=1,10
         if( ibtot(j).le.minperband) then
           do m=1,minperband-ibtot(j) 
             call txadd(tx,j)
           enddo
         endif
       enddo
       call txtrim(tx,ntxlimit,ntot)
       if( abs(ntot-n_needed) .le. 1 ) then
!         write(*,*) "Success! Iteration converged"
         exit
       endif
!     write(*,*) "Iteration: ",k,ntot,n_needed
! iteration loop
     enddo 
     actual_pct=ntot/60.0 
!     write(*,*) "Actual percentage: ",actual_pct
  endif

  iband=mod(nsec/120,10) + 1
  iseq=mod(nsec/1200,6) + 1
  if(iseq.lt.1) iseq=1
  if(tx(iband,iseq).eq.1) then
     ntxnext=1
  else
     nrx=1
  endif
  iband=iband-1

!  write(*,3000) iband+1,iseq,nrx,ntxnext
!3000 format('Fortran iband, iseq,nrx,ntxnext:',4i5)
!     write(*,3001) int(tx)
!3001 format(10i2)

  return
end subroutine hopping
