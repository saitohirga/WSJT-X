program synctest

  use timer_module, only: timer
  use timer_impl, only: init_timer, fini_timer
  parameter (NFFT=32768)
  parameter (MAX_CANDIDATES=20)
  real ss(4,322,NFFT),savg(4,NFFT)
  real candidate(MAX_CANDIDATES,5)             !snr1,f0,xdt0,ipol,flip
  character*8 arg

  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   synctest iutc nfa nfb nts_jt65 nts_q65'
     print*,'Example: synctest 1814  23  83      2        1'
     go to 999
  endif
  call getarg(1,arg)
  read (arg,*) iutc
  call getarg(2,arg)
  read (arg,*) nfa
  call getarg(3,arg)
  read (arg,*) nfb
  call getarg(4,arg)
  read (arg,*) nts_jt65
  call getarg(5,arg)
  read (arg,*) nts_q65

  open(50,file='50.a',form='unformatted',status='old')
  do ifile=1,9999
     read(50,end=998) nutc,npol,ss(1:npol,:,:),savg(1:npol,:)
     if(nutc.eq.iutc) exit
  enddo
  close(50)

  call init_timer('timer.out')
  call timer('synctest',0)

  call timer('get_cand',0)
  call  get_candidates(ss,savg,nfa,nfb,nts_jt65,nts_q65,candidate,ncand)
  call timer('get_cand',1)

  do k=1,ncand
     snr1=candidate(k,1)
     f0=candidate(k,2)
     xdt0=candidate(k,3)
     ipol=nint(candidate(k,4))
     iflip=nint(candidate(k,5))
     write(*,1010) k,snr1,f0,f0+77,xdt0,ipol,iflip
1010 format(i3,4f10.3,2i3,f8.3)
  enddo

998 call timer('synctest',1)
  call timer('synctest',101)
  call fini_timer()

999 end program synctest

subroutine get_candidates(ss,savg,nfa,nfb,nts_jt65,nts_q65,candidate,ncand)

  use wideband2_sync
  parameter (MAX0=1000,MAX_CANDIDATES=20)
  real ss(4,322,NFFT),savg(4,NFFT)
  real candidate(MAX_CANDIDATES,5)             !snr1,f0,xdt0,ipol,flip
  integer indx(NFFT)
  logical skip

  call wb2_sync(ss,savg,nfa,nfb)

  df3=96000.0/NFFT
  ia=nint(1000*nfa/df3)
  ib=nint(1000*nfb/df3)
  iz=ib-ia+1
  do i=ia,ib
     f0=0.001*i*df3
     write(13,1000) f0,sync_dat(i,2:5)
1000 format(3f10.3,2f5.0)
  enddo
  call indexx(sync_dat(ia:ib,2),iz,indx)

  k=0
  do i=1,MAX0
     j=indx(iz+1-i) + ia - 1
     f0=0.001*j*df3
     snr1=sync_dat(j,2)
     if(snr1.lt.5.0) exit
     flip=sync_dat(j,5)
     if(flip.ne.0.0 .and. nts_jt65.eq.0) cycle
     if(flip.eq.0.0 .and. nts_q65.eq.0) cycle
     if(sync_dat(j,6).lt.3.0) cycle
     bw=nts_q65*108.0
     if(flip.ne.0) bw=nts_jt65*177.0
     skip=.false.
     do n=1,k
        diffhz=1000.0*(f0-candidate(n,2))
        if(diffhz.gt.-10.0 .and. diffhz.lt.bw) skip=.true.
     enddo
     if(skip) cycle
     k=k+1
     xdt0=sync_dat(j,3)
     ipol=nint(sync_dat(j,4))
     candidate(k,1)=snr1                !snr1
     candidate(k,2)=f0                  !f0
     candidate(k,3)=xdt0
     candidate(k,4)=ipol
     candidate(k,5)=flip
     if(k.ge.MAX_CANDIDATES) exit
  enddo
  ncand=k

  return
end subroutine get_candidates
