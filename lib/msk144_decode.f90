subroutine msk144_decode(id2,npts,nutc,nprint,pchk_file,mycall,hiscall,   &
     bShMsgs,ntol,t0,line)

! Calls the experimental decoder for MSK 72ms/16ms messages
  use timer_module, only: timer
  parameter (NMAX=30*12000)
  parameter (NFFTMAX=512*1024)
  integer*2 id2(0:NMAX)                !Raw i*2 data, up to T/R = 30 s
  integer hist(0:32868)
  real d(0:NMAX)                       !Raw r*4 data
  complex c(NFFTMAX)                   !Complex (analytic) data
  character*80 line(100)               !Decodes passed back to caller
  character*512 pchk_file
  character*6 mycall,hiscall
  logical*1 bShMsgs

  line(1:100)(1:1)=char(0)
  if(maxval(id2(1:npts)).eq.0 .and. minval(id2(1:npts)).eq.0) go to 900

  hist=0
  do i=0,npts-1
     n=abs(id2(i))
     hist(n)=hist(n)+1
  enddo
  ns=0
  do n=0,32768
     ns=ns+hist(n)
     if(ns.gt.npts/2) exit
  enddo
  fac=1.0/(1.5*n)
  d(0:npts-1)=fac*id2(0:npts-1)

  n=log(float(npts))/log(2.0) + 1.0
  nfft=min(2**n,1024*1024)
  call timer('analytic',0)
  call analytic(d,npts,nfft,c)         !Convert to analytic signal and filter
  call timer('analytic',1)
  call timer('detec144',0)
  call detectmsk144(c,npts,pchk_file,line,nline,nutc,ntol,t0)
  call timer('detec144',1)
  if( nprint .ne. 0 ) then
    do i=1,nline
      write(*,'(a80)') line(i)
    enddo 
  endif


  if(nline.eq.0 .and. bShMsgs) then
    call timer('detect40',0)
    call detectmsk40(c,npts,mycall,hiscall,line,nline,nutc,ntol,t0)
    call timer('detect40',1)
    if( nprint .ne. 0 ) then
      do i=1,nline
        write(*,'(a80)') line(i)
      enddo
    endif
  endif

  if(line(1)(1:6).eq.'      ') line(1)(1:1)=char(0)

900 return
end subroutine msk144_decode
