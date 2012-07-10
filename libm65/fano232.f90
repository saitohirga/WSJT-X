subroutine fano232(symbol,nbits,mettab,ndelta,maxcycles,dat,     &
     ncycles,metric,ierr,maxmetric,maxnp)

! Sequential decoder for K=32, r=1/2 convolutional code using 
! the Fano algorithm.  Translated from C routine for same purpose
! written by Phil Karn, KA9Q.

  parameter (MAXBITS=103)
  parameter (MAXDAT=(MAXBITS+7)/8)
  integer*1 symbol(0:2*MAXBITS-1)
  integer*1 dat(MAXDAT)            !Decoded user data, 8 bits per byte
  integer mettab(0:255,0:1)        !Metric table

! These were the "node" structure in Karn's C code:
  integer nstate(0:MAXBITS-1)      !Encoder state of next node
  integer gamma(0:MAXBITS-1)       !Cumulative metric to this node
  integer metrics(0:3,0:MAXBITS-1) !Metrics indexed by all possible Tx syms
  integer tm(0:1,0:MAXBITS-1)      !Sorted metrics for current hypotheses
  integer ii(0:MAXBITS-1)          !Current branch being tested

  logical noback
  include 'conv232.f90'

  maxmetric=-9999999
  maxnp=-9999999
  ntail=nbits-31

! Compute all possible branch metrics for each symbol pair.
! This is the only place we actually look at the raw input symbols
  i4a=0
  i4b=0
  do np=0,nbits-1
     j=2*np
     i4a=symbol(j)
     i4b=symbol(j+1)
     if (i4a.lt.0) i4a=i4a+256
     if (i4b.lt.0) i4b=i4b+256
     metrics(0,np) = mettab(i4a,0) + mettab(i4b,0)
     metrics(1,np) = mettab(i4a,0) + mettab(i4b,1)
     metrics(2,np) = mettab(i4a,1) + mettab(i4b,0)
     metrics(3,np) = mettab(i4a,1) + mettab(i4b,1)
  enddo

  np=0
  nstate(np)=0

! Compute and sort branch metrics from the root node
  n=iand(nstate(np),npoly1)
  n=ieor(n,ishft(n,-16))
  lsym=partab(iand(ieor(n,ishft(n,-8)),255))
  n=iand(nstate(np),npoly2)
  n=ieor(n,ishft(n,-16))
  lsym=lsym+lsym+partab(iand(ieor(n,ishft(n,-8)),255))
  m0=metrics(lsym,np)
  m1=metrics(ieor(3,lsym),np)
  if(m0.gt.m1) then
     tm(0,np)=m0                      !0-branch has better metric
     tm(1,np)=m1
  else
     tm(0,np)=m1                      !1-branch is better
     tm(1,np)=m0
     nstate(np)=nstate(np) + 1        !Set low bit
  endif

! Start with best branch
  ii(np)=0
  gamma(np)=0
  nt=0

! Start the Fano decoder
  do i=1,nbits*maxcycles
! Look forward
     ngamma=gamma(np) + tm(ii(np),np)
     if(ngamma.ge.nt) then

! Node is acceptable.  If first time visiting this node, tighten threshold:
        if(gamma(np).lt.(nt+ndelta)) nt=nt + ndelta * ((ngamma-nt)/ndelta)

! Move forward
        gamma(np+1)=ngamma
        nstate(np+1)=ishft(nstate(np),1)
        np=np+1
!        if(ngamma.gt.maxmetric) then
        if(np.gt.maxnp) then
           maxmetric=ngamma
           maxnp=np
        endif
        if(np.eq.nbits-1) go to 100     !We're done!

        n=iand(nstate(np),npoly1)
        n=ieor(n,ishft(n,-16))
        lsym=partab(iand(ieor(n,ishft(n,-8)),255))
        n=iand(nstate(np),npoly2)
        n=ieor(n,ishft(n,-16))
        lsym=lsym+lsym+partab(iand(ieor(n,ishft(n,-8)),255))
            
        if(np.ge.ntail) then
           tm(0,np)=metrics(lsym,np)      !We're in the tail, all zeros
        else
           m0=metrics(lsym,np)
           m1=metrics(ieor(3,lsym),np)
           if(m0.gt.m1) then
              tm(0,np)=m0                 !0-branch has better metric
              tm(1,np)=m1
           else
              tm(0,np)=m1                 !1-branch is better
              tm(1,np)=m0
              nstate(np)=nstate(np) + 1   !Set low bit
           endif
        endif

        ii(np)=0                          !Start with best branch
        go to 99
     endif

! Threshold violated, can't go forward
10   noback=.false.
     if(np.eq.0) noback=.true.
     if(np.gt.0) then
        if(gamma(np-1).lt.nt) noback=.true.
     endif

     if(noback) then
! Can't back up, either.  Relax threshold and look forward again 
! to a better branch.
        nt=nt-ndelta
        if(ii(np).ne.0) then
           ii(np)=0
           nstate(np)=ieor(nstate(np),1)
        endif
        go to 99
     endif

! Back up
     np=np-1
     if(np.lt.ntail .and. ii(np).ne.1) then
! Search the next best branch
        ii(np)=ii(np)+1
        nstate(np)=ieor(nstate(np),1)
        go to 99
     endif
     go to 10
99   continue
  enddo
  i=nbits*maxcycles
  
100 metric=gamma(np)                       !Final path metric

! Copy decoded data to user's buffer
  nbytes=(nbits+7)/8
  np=7
  do j=1,nbytes-1
     i4a=nstate(np)
     dat(j)=i4a
     np=np+8
  enddo
  dat(nbytes)=0
  
  ncycles=i+1
  ierr=0
  if(i.ge.maxcycles*nbits) ierr=-1

  return
end subroutine fano232
