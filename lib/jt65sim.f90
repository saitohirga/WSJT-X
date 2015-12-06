program jt65sim

! Generate simulated JT65 data for testing WSJT-X

  use wavhdr
  use packjt
  parameter (NMAX=54*12000)              ! = 648,000
  parameter (NFFT=10*65536,NH=NFFT/2)
  type(hdr) h                            !Header for .wav file
  integer*2 iwave(NMAX)                  !Generated waveform
  integer*4 itone(126)                   !Channel symbols (values 0-65)
  integer dgen(12)                       !Twelve 6-bit data symbols
  integer sent(63)                       !RS(63,12) codeword
  real*4 xnoise(NMAX)                    !Generated random noise
  real*4 dat(NMAX)                       !Generated real data
  complex cdat(NMAX)                     !Generated complex waveform
  complex cspread(0:NFFT-1)              !Complex amplitude for Rayleigh fading
  complex z
  real*8 f0,dt,twopi,phi,dphi,baud,fsample,freq,sps
  character msg*22,arg*8,fname*11,csubmode*1,call1*5,call2*5
  integer nprc(126)                                      !Sync pattern
  data nprc/1,0,0,1,1,0,0,0,1,1,1,1,1,1,0,1,0,1,0,0,  &
            0,1,0,1,1,0,0,1,0,0,0,1,1,1,0,0,1,1,1,1,  &
            0,1,1,0,1,1,1,1,0,0,0,1,1,0,1,0,1,0,1,1,  &
            0,0,1,1,0,1,0,1,0,1,0,0,1,0,0,0,0,0,0,1,  &
            1,0,0,0,0,0,0,0,1,1,0,1,0,0,1,0,1,1,0,1,  &
            0,1,0,1,0,0,1,1,0,0,1,0,0,1,0,0,0,0,1,1,  &
            1,1,1,1,1,1/

  nargs=iargc()
  if(nargs.ne.6) then
     print*,'Usage:   jt65sim mode nsigs fspread  SNR   DT  nfiles'
     print*,'Example: jt65sim   A    10    0.2   -24.5  0.0   1'
     print*,'Enter SNR = 0 to generate a range of SNRs.'
     go to 999
  endif

  csubmode='A'
  call getarg(1,csubmode)
  mode65=1
  if(csubmode.eq.'B') mode65=2
  if(csubmode.eq.'C') mode65=4
  call getarg(2,arg)
  read(arg,*) nsigs                  !Number of signals in each file
  call getarg(3,arg)
  read(arg,*) fspread                !Doppler spread (Hz)
  call getarg(4,arg)
  read(arg,*) snrdb                  !S/N in dB (2500 hz reference BW)
  call getarg(5,arg)
  read(arg,*) xdt                    !Generated DT
  call getarg(6,arg)
  read(arg,*) nfiles                 !Number of files     

  rms=100.
  fsample=12000.d0                   !Sample rate (Hz)
  dt=1.d0/fsample                    !Sample interval (s)
  twopi=8.d0*atan(1.d0)
  npts=54*12000                      !Total samples in .wav file
  baud=11025.d0/4096.d0              !Keying rate
  sps=12000.d0/baud                  !Samples per symbol, at fsample=12000 Hz
  nsym=126                           !Number of channel symbols
  h=default_header(12000,npts)
  dfsig=2000.0/nsigs                 !Freq spacing between sigs in file (Hz)

! generate new random number seed for each run using /dev/urandom on linux and os x
  nerr=sgran()

  do ifile=1,nfiles                  !Loop over requested number of files
     write(fname,1002) ifile         !Output filename
1002 format('000000_',i4.4)
     open(10,file=fname//'.wav',access='stream',status='unknown')

     xnoise=0.
     cdat=0.
     if(snrdb.lt.90) then
        do i=1,npts
           xnoise(i)=gran()          !Generate gaussian noise
        enddo
     endif

     do isig=1,nsigs                        !Generate requested number of sigs
        if(mod(nsigs,2).eq.0) f0=1500.0 + dfsig*(isig-0.5-nsigs/2)
        if(mod(nsigs,2).eq.1) f0=1500.0 + dfsig*(isig-(nsigs+1)/2)
        xsnr=snrdb
        if(snrdb.eq.0.0) xsnr=-19 - isig
        if(csubmode.eq.'B' .and. snrdb.eq.0.0) xsnr=-21 - isig
        if(csubmode.eq.'C' .and. snrdb.eq.0.0) xsnr=-21 - isig

        call1="K1ABC"
        ic3=65+mod(isig-1,26)
        ic2=65+mod((isig-1)/26,26)
        ic1=65
        call2="W9"//char(ic1)//char(ic2)//char(ic3)
        write(msg,1010) call1,call2,nint(xsnr)
1010    format(a5,1x,a5,1x,i3.2)

        call packmsg(msg,dgen,itype)        !Pack message into 12 six-bit bytes
        call rs_encode(dgen,sent)           !Encode using RS(63,12)
        call interleave63(sent,1)           !Interleave channel symbols
        call graycode65(sent,63,1)          !Apply Gray code

        k=0
        do j=1,nsym                         !Insert sync and data into itone()
           if(nprc(j).eq.0) then
              k=k+1
              itone(j)=sent(k)+2
           else
              itone(j)=0
           endif
        enddo

        bandwidth_ratio=2500.0/6000.0
        sig=sqrt(2*bandwidth_ratio)*10.0**(0.05*xsnr)
        if(xsnr.gt.90.0) sig=1.0
        write(*,1020) ifile,isig,f0,csubmode,xsnr,sig,msg
1020    format(i4,i4,f10.3,2x,a1,2x,f5.1,f8.4,2x,a22)

        phi=0.d0
        dphi=0.d0
        k=12000 + xdt*12000                 !Start audio at t = xdt + 1.0 s
        isym0=-99
        do i=1,npts                         !Add this signal into cdat()
           isym=floor(i/sps)+1
           if(isym.gt.nsym) exit
           if(isym.ne.isym0) then
              freq=f0 + itone(isym)*baud*mode65
              dphi=twopi*freq*dt
              isym0=isym
           endif
           phi=phi + dphi
           if(phi.gt.twopi) phi=phi-twopi
           xphi=phi
           z=cmplx(cos(xphi),sin(xphi))
           k=k+1
           if(k.ge.1) cdat(k)=cdat(k) + sig*z
        enddo
     enddo

     if(fspread.ne.0) then                  !Apply specified Doppler spread
        df=12000.0/nfft
        twopi=8*atan(1.0)
        cspread(0)=1.0
        cspread(NH)=0.

        do i=1,NH
           f=i*df
           x=f/fspread
           z=0.
           a=0.
           if(x.lt.50.0) then
              a=sqrt(exp(-x*x))
              call random_number(r1)
              phi1=twopi*r1
              z=a*cmplx(cos(phi1),sin(phi1))
           endif
           cspread(i)=z
           z=0.
           if(x.lt.50.0) then
              call random_number(r2)
              phi2=twopi*r2
              z=a*cmplx(cos(phi2),sin(phi2))
           endif
           cspread(NFFT-i)=z
        enddo

        do i=0,NFFT-1
           f=i*df
           if(i.gt.NH) f=(i-nfft)*df
           s=real(cspread(i))**2 + aimag(cspread(i))**2
!          write(13,3000) i,f,s,cspread(i)
!3000      format(i5,f10.3,3f12.6)
        enddo
!        s=real(cspread(0))**2 + aimag(cspread(0))**2
!        write(13,3000) 1024,0.0,s,cspread(0)

        call four2a(cspread,NFFT,1,1,1)             !Transform to time domain

        sum=0.
        do i=0,NFFT-1
           p=real(cspread(i))**2 + aimag(cspread(i))**2
           sum=sum+p
        enddo
        avep=sum/NFFT
        fac=sqrt(1.0/avep)
        cspread=fac*cspread                   !Normalize to constant avg power
        cdat=cspread(1:npts)*cdat             !Apply Rayleigh fading

!        do i=0,NFFT-1
!           p=real(cspread(i))**2 + aimag(cspread(i))**2
!           write(14,3010) i,p,cspread(i)
!3010       format(i8,3f12.6)
!        enddo

     endif

     dat=aimag(cdat) + xnoise                 !Add the generated noise
     fac=32767.0/nsigs
     if(snrdb.ge.90.0) iwave(1:npts)=nint(fac*dat(1:npts))
     if(snrdb.lt.90.0) iwave(1:npts)=nint(rms*dat(1:npts))
     write(10) h,iwave(1:npts)                !Save the .wav file
     close(10)
  enddo

999 end program jt65sim
