subroutine timer(dname,k)

! Times procedure number n between a call with k=0 (tstart) and with
! k=1 (tstop). Accumulates sums of these times in array ut (user time).
! Also traces all calls (for debugging purposes) if limtrace.gt.0
!
! If this is used with OpenMP than the /tracer_priv/ common block must
! be copyed into each thread of a thread team by using the copyin()
! clause on the !$omp parallel directive that creates the team.

  !$ use omp_lib

  character*8 dname
  !$ integer tid
  integer onlevel(0:10)
  common/tracer/ limtrace,lu
  common/tracer_priv/level,onlevel

  parameter (MAXCALL=100)
  character*8 name(MAXCALL),space
  logical on(MAXCALL)
  real ut(MAXCALL),ut0(MAXCALL)
  !$ integer ntid(MAXCALL)
  integer nmax,ncall(MAXCALL),nlevel(MAXCALL),nparent(MAXCALL)
  common/data/nmax,name,on,ut,ut0,dut,ntid,ncall,nlevel,nparent,total,sum,sumf,space

  data eps/0.000001/,ntrace/0/
  data level/0/,nmax/0/,space/'        '/
  data limtrace/0/,lu/-1/

  !$omp threadprivate(/tracer_priv/)

  !$omp critical(timer)
  if(limtrace.lt.0) go to 999
  if(lu.lt.1) lu=6
  if(k.gt.1) go to 40                        !Check for "all done" (k>1)
  onlevel(0)=0

  !$ tid=omp_get_thread_num()
  do n=1,nmax                                !Check for existing name/parent[/thread]
     if(name(n).eq.dname &
          !$ .and.ntid(n).eq.tid &
          ) then
        if (on(n)) then
             if (nparent(n).eq.onlevel(level-1)) goto 20
        else
           if (nparent(n).eq.onlevel(level)) goto 20
        end if
     end if
  enddo

  nmax=nmax+1                                !This is a new one
  n=nmax
  !$ ntid(n)=tid
  ncall(n)=0
  on(n)=.false.
  ut(n)=eps
  name(n)=dname

20 if(k.eq.0) then                                !Get start times (k=0)
     if(on(n)) then
        print*,'Error in timer: ',dname,' already on.'
     end if
     level=level+1                                !Increment the level
     on(n)=.true.
!     call system_clock(icount,irate)
!     ut0(n)=float(icount)/irate
!     call cpu_time(ut0(n))
     ut0(n)=secnds(0.0)

     ncall(n)=ncall(n)+1
     if(ncall(n).gt.1.and.nlevel(n).ne.level) then
        !recursion is happening
        !
        !TODO: somehow need to account for this deeper call at the
        !shallowest instance in the call chain and this needs to be
        !done without incrementing anything here other than counters
        !and timers
        !
        nlevel(n)=-1
     else
        nlevel(n)=level
     endif
     nparent(n)=onlevel(level-1)
     onlevel(level)=n

  else if(k.eq.1) then        !Get stop times and accumulate sums. (k=1)
     if(on(n)) then
        on(n)=.false.
!        call system_clock(icount,irate)
!        ut1=float(icount)/irate
!        call cpu_time(ut1)
        ut1=secnds(0.0)

        ut(n)=ut(n)+ut1-ut0(n)
     endif
     level=level-1
  endif

  ntrace=ntrace+1
  if(ntrace.lt.limtrace) write(lu,1020) ntrace,tname,k,level,nparent(n)
1020 format(i8,': ',a8,3i5)
  go to 998

! Write out the timer statistics

40 write(lu,1040)
1040 format(/' name                 time  frac     dtime',       &
             ' dfrac  calls'/56('-'))

  !$ !walk backwards through the database rolling up thread data by call chain
  !$ do i=nmax,1,-1
  !$    do j=1,i-1
  !$       l=j
  !$       m=i
  !$       do while (name(l).eq.name(m))
  !$          l=nparent(l)
  !$          m=nparent(m)
  !$          if (l.eq.0.or.m.eq.0) exit
  !$       end do
  !$       if (l.eq.0.and.m.eq.0) then
  !$          !same call chain so roll up data
  !$          ncall(j)=ncall(j)+ncall(i)
  !$          ut(j)=ut(j)+ut(i)
  !$          name(i)=space
  !$          exit
  !$       end if
  !$    end do
  !$ end do

  if(k.gt.100) then
     ndiv=k-100
     do i=1,nmax
        ncall(i)=ncall(i)/ndiv
        ut(i)=ut(i)/ndiv
     enddo
  endif

  total=ut(1)
  sum=0.
  sumf=0.
  i=1
  call print_root(i)
  write(lu,1070) sum,sumf
1070 format(/32x,f10.3,f6.2)
  nmax=0
  eps=0.000001
  ntrace=0
  level=0
  onlevel(0)=0

998 flush(lu)

999 continue

  !$omp end critical(timer)
  return
end subroutine timer

recursive subroutine print_root(i)
  character*16 sname

  common/tracer/ limtrace,lu

  parameter (MAXCALL=100)
  character*8 name(MAXCALL),space
  logical on(MAXCALL)
  real ut(MAXCALL),ut0(MAXCALL)
  !$ integer ntid(MAXCALL)
  integer nmax,ncall(MAXCALL),nlevel(MAXCALL),nparent(MAXCALL)
  common/data/nmax,name,on,ut,ut0,dut,ntid,ncall,nlevel,nparent,total,sum,sumf,space

  if (i.le.nmax) then
     if (name(i).ne.space) then
        dut=ut(i)
        do j=i,nmax
           if(nparent(j).eq.i) dut=dut-ut(j)
        enddo
        if(dut.lt.0.0) dut=0.0
        utf=ut(i)/total
        dutf=dut/total
        sum=sum+dut
        sumf=sumf+dutf
        kk=nlevel(i)
        sname=space(1:kk)//name(i)//space(1:8-kk)
        write(lu,2000) sname,ut(i),utf,dut,dutf,ncall(i)
        do j=i,nmax
           if(nparent(j).eq.i) call print_root(j)
        enddo
     end if
  end if
2000    format(a16,2(f10.3,f6.2),i7,i5)
  return
end subroutine print_root
