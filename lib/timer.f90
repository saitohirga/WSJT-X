subroutine timer(dname,k)

! Times procedure number n between a call with k=0 (tstart) and with
! k=1 (tstop). Accumulates sums of these times in array ut (user time).
! Also traces all calls (for debugging purposes) if limtrace.gt.0

  !$ interface
  !$  integer function omp_get_thread_num()
  !$  end function
  !$ end interface

  parameter (MAXCALL=100)
  character*8 dname
  !$ character thread
  character*11 tname,ename
  character*16 sname
  character*11, save :: space
  integer, save :: level, nmax
  character*11, save :: name(MAXCALL)
  logical, save :: on(MAXCALL)
  real, save :: ut(MAXCALL),ut0(MAXCALL),dut(MAXCALL)
  integer, save :: ncall(MAXCALL),nlevel(MAXCALL),nparent(MAXCALL)
  integer, save :: onlevel(0:10)
  common/tracer/ limtrace,lu
  data eps/0.000001/,ntrace/0/
  data level/0/,nmax/0/,space/'        '/
  data limtrace/0/,lu/-1/
  !$omp threadprivate(level,space,onlevel)

  ! currently this module is broken if called from multiple threads
  !$ return ! diable if usinh OpenMP

  tname=dname
  !$ write(thread,'(i1)') omp_get_thread_num()
  !$ tname=trim(dname)//'('//thread//')' ! decorate name with thread number

  !$omp critical(timer)
  if(limtrace.lt.0) go to 999
  if(lu.lt.1) lu=6
  if(k.gt.1) go to 40                        !Check for "all done" (k>1)
  onlevel(0)=0

  do n=1,nmax                                !Check for existing name
     if(name(n).eq.tname) go to 20
  enddo

  nmax=nmax+1                                !This is a new one
  n=nmax
  ncall(n)=0
  on(n)=.false.
  ut(n)=eps
  name(n)=tname

20 if(k.eq.0) then                                !Get start times (k=0)
     if(on(n)) print*,'Error in timer: ',tname,' already on.'
     level=level+1                                !Increment the level
     on(n)=.true.
!     call system_clock(icount,irate)
!     ut0(n)=float(icount)/irate
!     call cpu_time(ut0(n))
     ut0(n)=secnds(0.0)

     ncall(n)=ncall(n)+1
     if(ncall(n).gt.1.and.nlevel(n).ne.level) then
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
1020 format(i8,': ',a11,3i5)
  go to 998

! Write out the timer statistics

40 write(lu,1040)
1040 format(/'     name                 time  frac     dtime',       &
             ' dfrac  calls level parent'/73('-'))

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
  do i=1,nmax
     dut(i)=ut(i)
     do j=i,nmax
        if(nparent(j).eq.i) dut(i)=dut(i)-ut(j)
     enddo
     if(dut(i).lt.0.0) dut(i)=0.0
     utf=ut(i)/total
     dutf=dut(i)/total
     sum=sum+dut(i)
     sumf=sumf+dutf
     kk=nlevel(i)
     sname=space(1:kk)//name(i)//space(1:11-kk)
     ename=space
     if(nparent(i).ge.1) ename=name(nparent(i))
     write(lu,1060) float(i),sname,ut(i),utf,dut(i),dutf,           &
          ncall(i),nlevel(i),ename
1060 format(f4.0,a16,2(f10.3,f6.2),i7,i5,2x,a11)
  enddo

  write(lu,1070) sum,sumf
1070 format(/36x,f10.2,f6.2)
  nmax=0
  eps=0.000001
  ntrace=0
  level=0
  space='        '
  onlevel(0)=0

998 flush(lu)

999 continue

  !$omp end critical(timer)
  return
end subroutine timer
