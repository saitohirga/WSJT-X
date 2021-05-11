program synctest

  use wideband2_sync
  use timer_module, only: timer
  use timer_impl, only: init_timer, fini_timer
  parameter (MAX0=1000,MAX_CANDIDATES=20)
  real ss(4,322,NFFT),savg(4,NFFT)
  real candidate(MAX_CANDIDATES,5)             !snr1,f0,xdt0,ipol,flip
  integer indx(NFFT)
  logical skip
  character*8 arg

  open(50,file='50.a',form='unformatted',status='old')
  call getarg(1,arg)
  read (arg,*) iutc
  
  do ifile=1,999
     read(50,end=999) nutc,npol,ss(1:npol,:,:),savg(1:npol,:)
     if(nutc.eq.iutc) exit
  enddo
  close(50)

  call init_timer('timer.out')
  call timer('synctest',0)
  
  print*,nutc,npol
  ntone_spacing=1
  call timer('wb_sync ',0)
  call wb2_sync(ss,savg,ntone_spacing)
  call timer('wb_sync ',1)

  df3=96000.0/NFFT
  ia=nint(7000.0/df3)
  ib=nint(89000.0/df3)
  iz=ib-ia+1
  do i=ia,ib
     f0=0.001*i*df3
     write(13,1000) f0,sync_dat(i,2:5)
1000 format(3f10.3,2f5.0)
  enddo

  call timer('indexx  ',0)
  call indexx(sync_dat(ia:ib,2),iz,indx)
  call timer('indexx  ',1)

  k=0
  do i=1,MAX0
     j=indx(iz+1-i) + ia - 1
     f0=0.001*j*df3
     snr1=sync_dat(j,2)
     if(snr1.lt.3.0) exit
     skip=.false.
     do n=1,k
        diffhz=1000.0*(f0-candidate(n,2))
        if(diffhz.gt.-10.0 .and. diffhz.lt.108.0) skip=.true.
     enddo
     if(skip) cycle
     k=k+1
     candidate(k,1)=snr1                !snr1
     candidate(k,2)=f0                  !f0
     candidate(k,3)=sync_dat(j,3)       !xdt0
     candidate(k,4)=sync_dat(j,4)       !ipol
     candidate(k,5)=sync_dat(j,5)       !flip
     write(*,1010) k,candidate(k,1:5)
1010 format(i3,3f10.3,2f6.0)
     if(k.ge.MAX_CANDIDATES) exit
  enddo

999 call timer('synctest',1)
  call timer('synctest',101)
  call fini_timer()

end program synctest
