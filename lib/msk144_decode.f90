subroutine msk144_decode(id2,npts,nutc,nprint,pchk_file,mycall,hiscall,line)

! Calls the experimental decoder for MSK 72ms/16ms messages

  parameter (NMAX=30*12000)
  parameter (NFFTMAX=512*1024)
  integer*2 id2(0:NMAX)                !Raw i*2 data, up to T/R = 30 s
  integer hist(0:32868)
  real d(0:NMAX)                       !Raw r*4 data
  complex c(NFFTMAX)                   !Complex (analytic) data
  character*80 line(100)               !Decodes passed back to caller
  character*512 pchk_file
  character*6 mycall,hiscall

  line(1:100)(1:1)=char(0)

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
  call analytic(d,npts,nfft,c)         !Convert to analytic signal and filter
  call detectmsk144(c,npts,pchk_file,line,nline,nutc)
  if( nprint .ne. 0 ) then
    do i=1,nline
      write(*,'(a80)') line(i)
    enddo 
  endif

  if(nline .eq. 0) then
    call detectmsk32(c,npts,mycall,hiscall,line,nline,nutc)
    if( nprint .ne. 0 ) then
      do i=1,nline
        write(*,'(a80)') line(i)
      enddo
    endif
  endif

  if(line(1)(1:6).eq.'      ') line(1)(1:1)=char(0)
  return
end subroutine msk144_decode
