program test_snr

! Test an algorithm for measuring SNR of EME echoes.

  use wavhdr
  parameter (NMAX=27648)           !27*1024
  parameter (NFFT=32768,NH=NFFT/2)
  parameter (NZ=4096)

  type(hdr) h                            !Header for the .wav file
  integer*2 id2(NMAX)                 !Buffer for Rx data  
  complex c(0:NH)
  real x(NFFT)
  real s(8192)
  character*80 infile
  integer ipkv(1)
  equivalence (x,c),(ipk,ipkv)

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage:    test_snr <infile>'
     go to 999
  endif
  call getarg(1,infile)
  i0=index(infile,'_')
  read(infile(1:i0-1),*) fspread0                    !Generated Doppler spread
  read(infile(i0+1:i0+3),*) snrdb0                   !Generated SNR
  open(10,file=trim(infile),status='old',access='stream')
  read(10) h
  npts=h%ndata/2
  npings=npts/NMAX
  nfsample=h%nsamrate
  df=12000.0/NFFT
  s=0.
  
  do iping=1,npings
     read(10) id2(1:NMAX)
     x(1:NMAX)=id2(1:NMAX)
     x(NMAX+1:)=0.
     rms=sqrt(dot_product(x(1:NMAX),x(1:NMAX))/NMAX)
     
     call four2a(x,NFFT,1,-1,0)
     do i=1,8192                             !Accumulate spectrum 0 - 3 kHz
        s(i)=s(i) + real(c(i))**2 + aimag(c(i))**2
     enddo
  enddo

  wh=0.5*fspread0+10.0
  i1=nint((1500.0 - 2.0*wh)/df)
  i2=nint((1500.0 - wh)/df)
  i3=nint((1500.0 + wh)/df)
  i4=nint((1500.0 + 2.0*wh)/df)

  baseline=(sum(s(i1:i2-1)) + sum(s(i3+1:i4)))/(i2+i4-i1-i3)
  s=s/baseline
  psig=sum(s(i2:i3)-1.0)
  pnoise_2500 = 2500.0/df
  snrdb=db(psig/pnoise_2500)

  smax=0.
  mh=max(1,nint(0.2*fspread0/df))
  do i=i2,i3
     ssum=sum(s(i-mh:i+mh))
     if(ssum.gt.smax) then
        smax=ssum
        ipk=i
     endif
  enddo
  fpeak=ipk*df - 1500.0

  call averms(s(i1:i2-1),i2-i1,-1,ave1,rms1)
  call averms(s(i3+1:i4),i4-i3,-1,ave2,rms2)
  perr=0.707*(rms1+rms2)*sqrt(float(i2-i1+i4-i3))
  snr_detect=psig/perr
  db_err=99.0
  if(psig.gt.perr) db_err=snrdb - db((psig-perr)/pnoise_2500)

  nsum=npings
  nqual=0
  if(nsum.ge.2 .and. nsum.lt.4)  nqual=(snr_detect-4)/5
  if(nsum.ge.4 .and. nsum.lt.8)  nqual=(snr_detect-3)/4
  if(nsum.ge.8 .and. nsum.lt.12) nqual=(snr_detect-3)/3
  if(nsum.ge.12) nqual=(snr_detect-2.5)/2.5
  if(nqual.lt.0)  nqual=0
  if(nqual.gt.10) nqual=10

  write(*,1010) fspread0,wh,snrdb0,snrdb,snrdb-snrdb0,db_err,fpeak,   &
       snr_detect,nqual

1010 format(6f6.1,2f7.1,i3)

  do i=1,8192
     write(12,1100) i*df,s(i)
1100 format(f10.3,e12.3)
  enddo

999 end program test_snr
