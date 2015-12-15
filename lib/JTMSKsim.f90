program JTMSKsim

  use wavhdr
  parameter (NSPM=1404)
  parameter (NFFT=256*1024)
  parameter (NMAX=15*12000)
  type(hdr) h
  complex cb11(0:NSPM-1)
  complex cmsg(0:NSPM-1)
  complex c(0:NFFT-1)
  complex c1(0:NSPM-1)
  complex c2(0:NSPM-1)
  integer i4tone(NSPM)
  integer*2 iwave(NMAX)
  real w(0:255)
  character*8 arg

  nargs=iargc()
  if(nargs.ne.2) then
     print*,'Usage: JTMSK freq dB'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) fmid
  call getarg(2,arg)
  read(arg,*) snrdb

  open(10,file='JTMSKcode.out',status='old')
  do j=1,234
     read(10,*) junk,i4tone(j)
  enddo
  close(10)

  npts=NMAX
  h=default_header(12000,npts)
  twopi=8.0*atan(1.0)
  dt=1.0/12000.0
  df=12000.0/NFFT
  k=-1
  phi=0.
  phi0=0.
  sig=10.0**(0.05*snrdb)

  call init_random_seed(1)      ! seed Fortran RANDOM_NUMBER generator
  call sgran()                  ! see C rand generator (used in gran)

! Generate the Tx waveform
  cb11=0.
  do j=1,234
     dphi=twopi*(fmid-500.0)*dt
     if(i4tone(j).eq.1) dphi=twopi*(fmid+500.0)*dt
     dphi0=twopi*1000.0*dt
     if(i4tone(j).eq.1) dphi0=twopi*2000.0*dt
     do i=1,6
        k=k+1
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        cmsg(k)=cmplx(cos(phi),sin(phi))
        phi0=phi0+dphi0
        if(phi0.gt.twopi) phi0=phi0-twopi
!        if((k.ge.1 .and. k.le.66) .or. (k.ge.283 .and. k.le.348) .or.      &
!             (k.ge.769 .and.k.le.834)) cb11(k)=cmplx(cos(phi0),sin(phi0))
        if(k.ge.1 .and. k.le.66) cb11(k)=cmplx(cos(phi0),sin(phi0))
!        write(11,3001) k*dt,cmsg(k),phi
!3001    format(4f12.6)
     enddo
  enddo

! Generate noise with B=2500 Hz, rms=1.0 
  c=0.
  ia=nint(250.0/df)
  ib=nint(2759.0/df)
  do i=ia,ib
     x=gran()
     y=gran()
     c(i)=cmplx(x,y)
  enddo
  call four2a(c,NFFT,1,1,1)
  sq=0.
  do i=0,npts-1
     sq=sq + real(c(i))**2 + aimag(c(i))**2
  enddo
  rms=sqrt(0.5*sq/npts)
  c=c/rms

  i0=3*12000
  ncopy=NSPM
!  ncopy=0.5*NSPM
  c(i0:i0+ncopy-1)=c(i0:i0+ncopy-1) + sig*cmsg(0:ncopy-1)
  do i=1,npts
     iwave(i)=100.0*real(c(i))
  enddo

  open(12,file='150901_000000.wav',status='unknown',access='stream')
  write(12) h,iwave(1:npts)

  smax=0.
  fpk=0.
  jpk=0
  nfft1=256
  w=0.
  do i=0,65
     w(i)=sin(i*twopi/132.0)
  enddo

  do ia=0,npts-nfft1
     c1(0:nfft1-1)=c(ia:ia+nfft1-1)*conjg(cb11(0:nfft1-1))
     c2(0:nfft1-1)=w(0:nfft1-1)*c1(0:nfft1-1)
     call four2a(c2,nfft1,1,-1,1)
     do i=0,nfft1-1
!        write(21,1100) i,c1(i)
!1100    format(i6,2f12.3)
     enddo

     df1=12000.0/nfft1
     do i=-20,20
        j=i
        if(i.lt.0) j=j+nfft1
        f=j*df1
        if(i.lt.0) f=f-12000.0
        s=1.e-3*(real(c2(j))**2 + aimag(c2(j))**2)
        if(abs(ia-i0).lt.1404) write(22,1110) f,c2(j),s,ia
1110    format(4f12.3,i6)
        if(s.gt.smax) then
           smax=s
           jpk=ia
           fpk=f
        endif
     enddo
  enddo
  print*,smax,jpk*dt,fpk

999 end program JTMSKsim

