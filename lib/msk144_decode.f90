subroutine msk144_decode(id2,npts,nutc,nprint,line)

! Calls the experimental decoder for JTMSK 72ms ldpc messages

  parameter (NMAX=30*12000)
  parameter (NFFTMAX=512*1024)
  parameter (NSPM=864)               !Samples per JTMSK long message
  integer*2 id2(0:NMAX)                !Raw i*2 data, up to T/R = 30 s
  integer hist(0:32868)
  real d(0:NMAX)                       !Raw r*4 data
  real ty(NMAX/512)                    !Ping times
  real yellow(NMAX/512)
  complex c(NFFTMAX)                   !Complex (analytic) data
  complex cdat(24000)                  !Short segments, up to 2 s
  complex cdat2(24000)
  character*22 msg,msg0                !Decoded message
  character*80 line(100)               !Decodes passed back to caller
  equivalence (hist,d)

  nsnr0=-99
  nline=0
  line(1:100)(1:1)=char(0)
  msg0='                      '
  msg=msg0

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
!  rms=sqrt(dot_product(d(0:npts-1),d(0:npts-1))/npts)
!### Would it be better to set median rms to 1.0 ?
!  d(0:npts-1)=d(0:npts-1)/rms          !Normalize so that rms=1.0

  call mskdt(d,npts,ty,yellow,nyel)

  nyel=min(nyel,100)

  n=log(float(npts))/log(2.0) + 1.0
  nfft=min(2**n,1024*1024)
  call analytic(d,npts,nfft,c)         !Convert to analytic signal and filter

  nafter=NSPM
! Process ping list (sorted by S/N) from top down.
  do n=1,nyel
     ia=ty(n)*12000.0 - NSPM/2
     if(ia.lt.1) ia=1
     ib=ia + 2*nafter-1
     if(ib.gt.NFFTMAX) ib=NFFTMAX
     iz=ib-ia+1
     cdat2(1:iz)=c(ia:ib)               !Select nlen complex samples
     t0=ia/12000.0
     call syncmsk144(cdat2,iz,metric,msg,freq)
     if(metric.eq.-9999) cycle             !No output if no significant sync
     if(msg(1:1).ne.' ') then
!      if(msg.ne.msg0) then
         nline=nline+1
         nsnr0=-99
!      endif
       y=10.0**(0.1*(yellow(n)-1.5))
       nsnr=max(-5,nint(db(y)))
!      if(nsnr.gt.nsnr0 .and. nline.gt.0) then
      write(line(nline),1020) nutc,nsnr,t0,nint(freq),msg
      if(nprint.ne.0) write(*,1020) nutc,nsnr,t0,nint(freq),msg
1020   format(i6.6,i4,f5.1,i5,' & ',a22)
       nsnr0=nsnr
!      go to 900
!    endif
     msg0=msg
     endif
  enddo

900 continue

  return
end subroutine msk144_decode
