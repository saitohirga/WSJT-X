program JTMSKsim

  use wavhdr
  parameter (NMAX=15*12000)
  real pings(0:NMAX-1)
  real waveform(0:864-1)
  character arg*8,msg*22,msgsent*22,fname*40
  character*3 rpt(0:7)
  real wave(0:NMAX-1)              !Simulated received waveform
  real*8 dt,twopi,freq,phi,dphi0,dphi1,dphi
  type(hdr) h                          !Header for .wav file
  integer*2 iwave(0:NMAX-1)
  integer itone(144)                   !Message bits
  integer b11(11)                      !Barker-11 code
  data b11/1,1,1,0,0,0,1,0,0,1,0/
  data rpt /'26 ','27 ','28 ','R26','R27','R28','RRR','73 '/

  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:    JTMSKsim        message       freq width snr nfiles'
     print*,' '
     print*,'Examples: JTMSKsim  "K1ABC W9XYZ EN37"  1500  0.12  2   1'
     print*,'          JTMSKsim  "<K1ABC W9XYZ> R26" 1500  0.01  1   3'
     go to 999
  endif
  call getarg(1,msg)
  call getarg(2,arg)
  read(arg,*) freq
  call getarg(3,arg)
  read(arg,*) width
  call getarg(4,arg)
  read(arg,*) snrdb
  call getarg(5,arg)
  read(arg,*) nfiles
  sig=sqrt(2.0)*10.0**(0.05*snrdb)
  twopi=8.d0*atan(1.d0)
  h=default_header(12000,NMAX)

  ichk=0
  call genmsk(msg,ichk,msgsent,waveform,itype)   !this is genmsk144
  if(itype.lt.1 .or. itype.gt.7) then
     print*,'Illegal message'
     go to 999
  endif

  call makepings(pings,NMAX,width,sig)
!  pings=0.0
!  pings(12345:24000)=sig
  do ifile=1,nfiles                  !Loop over requested number of files
     write(fname,1002) ifile         !Output filename
1002 format('000000_',i4.4)
     open(10,file=fname(1:11)//'.wav',access='stream',status='unknown')

     fac=sqrt(6000.0/2500.0)
     j=-1
     do i=0,NMAX-1
        j=mod(j+1,864)
        xx=gran()
        wave(i)=pings(i)*waveform(j) + fac*xx
        write(*,*) pings(i),fac,waveform(j),wave(j)
        iwave(i)=30.0*wave(i)
     enddo

     write(10) h,iwave               !Save the .wav file
     close(10)

!     call jtmsk_short(cwave,NMAX,msg)

  enddo

999 end program JTMSKsim
