program msk144sim

  use wavhdr
  parameter (NMAX=15*12000)
  real pings(0:NMAX-1)
  real waveform(0:NMAX-1)
  character*6 mygrid
  character arg*8,msg*37,msgsent*37,fname*40
  character*77 c77
  real wave(0:NMAX-1)              !Simulated received waveform
  real*8 twopi,freq,phi,dphi0,dphi1,dphi
  type(hdr) h                          !Header for .wav file
  integer*2 iwave(0:NMAX-1)
  integer itone(144)                   !Message bits
  logical*1 bcontest
  data mygrid/"EN50wc"/

  nargs=iargc()
  if(nargs.ne.6) then
     print*,'Usage:   msk144sim       message      freq width nslow snr nfiles'
     print*,'Example: msk144sim "K1ABC W9XYZ EN37" 1500  0.12   1    2    1'
     print*,'         msk144sim "K1ABC W9XYZ EN37" 1500  2.5   32   15    1'
     go to 999
  endif
  call getarg(1,msg)
  call getarg(2,arg)
  read(arg,*) freq
  call getarg(3,arg)
  read(arg,*) width
  call getarg(4,arg)
  read(arg,*) nslow
  call getarg(5,arg)
  read(arg,*) snrdb
  call getarg(6,arg)
  read(arg,*) nfiles

!sig is the peak amplitude of the ping. 
  sig=sqrt(2.0)*10.0**(0.05*snrdb)
  h=default_header(12000,NMAX)
  i1=len(trim(msg))-5
  bcontest=.false.
  if(msg(i1:i1+1).eq.'R ') bcontest=.true.
  ichk=0
  call genmsk_128_90(msg,mygrid,ichk,bcontest,msgsent,itone,itype) 
  twopi=8.d0*atan(1.d0)

  nsym=144
  nsps=6*nslow
  if( itone(41) .lt. 0 ) nsym=40
  baud=2000.d0/nslow
  dphi0=twopi*(freq-0.25d0*baud)/12000.d0
  dphi1=twopi*(freq+0.25d0*baud)/12000.d0
  phi=0.0
  k=0
  nreps=NMAX/(nsym*nsps)
  print*,nsym,nslow,nsps,baud,freq
  do jrep=1,nreps
    do i=1,nsym
      if( itone(i) .eq. 0 ) then
        dphi=dphi0
      else
        dphi=dphi1
      endif
      do j=1,nsps
        waveform(k)=cos(phi)
        k=k+1
        phi=mod(phi+dphi,twopi)
      enddo 
    enddo
  enddo 

  if(itype.lt.1 .or. itype.gt.7) then
     print*,'Illegal message'
     go to 999
  endif

  if(nslow.eq.1) call makepings(pings,NMAX,width,sig)

!  call sgran()
  do ifile=1,nfiles                  !Loop over requested number of files
     write(fname,1002) ifile         !Output filename
1002 format('000000_',i6.6)
     open(10,file=fname(1:13)//'.wav',access='stream',status='unknown')

     wave=0.0
     iwave=0
     fac=sqrt(6000.0/2500.0)
     do i=0,NMAX-1
        xx=gran()
        if(nslow.eq.1) wave(i)=pings(i)*waveform(i) + fac*xx
        if(nslow.gt.1) wave(i)=sig*waveform(i) + fac*xx
        iwave(i)=30.0*wave(i)
     enddo

     write(10) h,iwave               !Save the .wav file
     close(10)

  enddo

999 end program msk144sim
