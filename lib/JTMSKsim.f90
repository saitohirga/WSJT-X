program JTMSKsim

  use wavhdr
  parameter (NMAX=15*12000)
  real pings(0:NMAX-1)
  character arg*8,msg*22,msgsent*22,fname*40
  character*3 rpt(0:7)
  complex cmsg(0:1404-1)               !Waveform of message (once)
  complex cwave(0:NMAX-1)              !Simulated received waveform
  real*8 dt,twopi,freq,phi,dphi0,dphi1,dphi
  type(hdr) h                          !Header for .wav file
  integer*2 iwave(0:NMAX-1)
  integer itone(234)                   !Message bits
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
  sig=10.0**(0.05*snrdb)
  twopi=8.d0*atan(1.d0)
  h=default_header(12000,NMAX)

  ichk=0
  call genmsk(msg,ichk,msgsent,itone,itype)       !Check message type
  if(itype.lt.1 .or. itype.gt.7) then
     print*,'Illegal message'
     go to 999
  endif
  dt=1.d0/12000.d0                                !Sample interval
  dphi0=twopi*(freq-500.d0)*dt                    !Phase increment, lower tone
  dphi1=twopi*(freq+500.d0)*dt                    !Phase increment, upper tone

  nsym=234
  if(itype.eq.7) nsym=35
  nspm=6*nsym                               !Samples per message
  k=-1
  phi=0.d0
  do j=1,nsym
     dphi=dphi0
     if(itone(j).eq.1) dphi=dphi1
     do i=1,6
        k=k+1
        phi=phi + dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        cmsg(k)=cmplx(cos(xphi),sin(xphi))
     enddo
  enddo

  call makepings(pings,NMAX,width,sig)

  do ifile=1,nfiles                  !Loop over requested number of files
     write(fname,1002) ifile         !Output filename
1002 format('000000_',i4.4)
     open(10,file=fname(1:11)//'.wav',access='stream',status='unknown')

     fac=sqrt(6000.0/2500.0)
     j=-1
     do i=0,NMAX-1
        j=j+1
        if(j.ge.6*nsym) j=j-6*nsym
        xx=0.707*gran()
        yy=0.707*gran()
        cwave(i)=pings(i)*cmsg(j) + fac*cmplx(xx,yy)
        iwave(i)=30.0*real(cwave(i))
!        write(88,3003) i,i/12000.d0,cwave(i)
!3003    format(i8,f12.6,2f10.3)
     enddo

     write(10) h,iwave               !Save the .wav file
     close(10)

!     call jtmsk_short(cwave,NMAX,msg)

  enddo

999 end program JTMSKsim
