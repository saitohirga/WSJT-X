program jt65sim

! Generate simulated data for testing of WSJT-X

  use wavhdr
  use packjt
  parameter (NTMAX=54)
  parameter (NMAX=NTMAX*12000)
  type(hdr) h
  integer*2 iwave(NMAX)                  !Generated waveform (no noise)
  integer*4 itone(126)                   !Channel symbols (values 0-65)
  integer dgen(12),sent(63)
  real*4 dat(NMAX)
  real*8 f0,dt,twopi,phi,dphi,baud,fsample,freq,sps
  character msg*22,arg*8,fname*11,csubmode*1
  integer nprc(126)
  data nprc/1,0,0,1,1,0,0,0,1,1,1,1,1,1,0,1,0,1,0,0,  &
            0,1,0,1,1,0,0,1,0,0,0,1,1,1,0,0,1,1,1,1,  &
            0,1,1,0,1,1,1,1,0,0,0,1,1,0,1,0,1,0,1,1,  &
            0,0,1,1,0,1,0,1,0,1,0,0,1,0,0,0,0,0,0,1,  &
            1,0,0,0,0,0,0,0,1,1,0,1,0,0,1,0,1,1,0,1,  &
            0,1,0,1,0,0,1,1,0,0,1,0,0,1,0,0,0,0,1,1,  &
            1,1,1,1,1,1/

  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   jt65sim mode nRay nsigs SNR nfiles'
     print*,'Example: jt65sim   B    0    10  -24    1'
     print*,'Enter SNR = 0 to generate a range of SNRs.'
     go to 999
  endif

  csubmode='A'
  call getarg(1,csubmode)
  mode65=1
  if(csubmode.eq.'B') mode65=2
  if(csubmode.eq.'C') mode65=4
  call getarg(2,arg)
  read(arg,*) nRay                   !1 ==> Rayleigh fading
  call getarg(3,arg)
  read(arg,*) nsigs                  !Number of signals in each file
  call getarg(4,arg)
  read(arg,*) snrdb                  !S/N in dB (2500 hz reference BW)
  call getarg(5,arg)
  read(arg,*) nfiles                 !Number of files     

  rmsdb=25.
  rms=10.0**(0.05*rmsdb)
  fsample=12000.d0                   !Sample rate (Hz)
  dt=1.d0/fsample                    !Sample interval (s)
  twopi=8.d0*atan(1.d0)
  npts=54*12000
  baud=11025.d0/4096.d0
  sps=12000.d0/baud                  !Samples per symbol, at fsample=12000 Hz
  nsym=126
  h=default_header(12000,npts)

  do ifile=1,nfiles                  !Loop over all files
     nmin=ifile
     ihr=nmin/60
     imin=mod(nmin,60)
     write(fname,1002) ihr,imin      !Output filename
1002 format('000000_',2i2.2)
     open(10,file=fname//'.wav',access='stream',status='unknown')

     if(snrdb.lt.90) then
        do i=1,npts
           dat(i)=gran()             !Generate AWGN
        enddo
     else
        dat(1:npts)=0.
     endif

     dfsig=2000.0/nsigs
     do isig=1,nsigs
        if(mod(nsigs,2).eq.0) f0=1500.0 + dfsig*(isig-0.5-nsigs/2)
        if(mod(nsigs,2).eq.1) f0=1500.0 + dfsig*(isig-(nsigs+1)/2)
        nsnr=nint(snrdb)
        if(snrdb.eq.0.0) nsnr=-19 - isig
        write(msg,1010) nsnr
1010    format('K1ABC W9XYZ ',i3.2)

        call packmsg(msg,dgen,itype)        !Pack message into 12 six-bit bytes
        call rs_encode(dgen,sent)           !RS encode
        call interleave63(sent,1)           !Interleave channel symbols
        call graycode65(sent,63,1)          !Apply Gray code

        k=0
        do j=1,nsym
           if(nprc(j).eq.0) then
              k=k+1
              itone(j)=sent(k)+2
           else
              itone(j)=0
           endif
        enddo

        sig=10.0**(0.05*nsnr)
        if(nsnr.gt.90.0) sig=1.0
        write(*,1020) ifile,isig,f0,csubmode,nsnr,sig,msg
1020    format(i3,i4,f10.3,1x,a1,i5,f8.4,2x,a22)

        phi=0.d0
        dphi=0.d0
        k=12000                             !Start audio at t = 1.0 s
        isym0=-99
        do i=1,npts
           isym=nint(i/sps)+1
           if(isym.gt.nsym) exit
           if(isym.ne.isym0) then
              freq=f0 + itone(isym)*baud*mode65
              dphi=twopi*freq*dt
              isym0=isym
           endif
           phi=phi + dphi
           if(phi.gt.twopi) phi=phi-twopi
           xphi=phi
           k=k+1
           dat(k)=dat(k) + sig*sin(xphi)
        enddo
     enddo

     fac=32767.0/nsigs                       !### ??? ###
     if(snrdb.ge.90.0) iwave(1:npts)=nint(fac*dat(1:npts))
     if(snrdb.lt.90.0) iwave(1:npts)=nint(rms*dat(1:npts))
     write(10) h,iwave(1:npts)
     close(10)

  enddo

999 end program jt65sim
