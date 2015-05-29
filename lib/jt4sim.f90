program jt4sim

! Generate simulated data for testing the JT4 decoder

  use wavhdr
  use packjt
  use jt4
  parameter (NMAX=60*12000)
  type(hdr) h
  integer*2 iwave(NMAX)                  !Generated waveform
  real*4 dat(NMAX)
  real*4 r(2)
  real*8 f0,f,dt,twopi,phi,dphi0,dphi,baud,fspread,fsample,freq,sps
  character message*22,msgsent*22,arg*8,fname*11,submode*1

  integer*4 itone(206)             !Channel symbols (values 0-8)

  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   jt4sim "message"       [A-G] fspread SNR nfiles'
     print*,'Example: jt4sim "CQ K1ABC FN42"   F     200   -17   1'
     go to 999
  endif

  call getarg(1,message)  
  call fmtmsg(message,iz)
  call getarg(2,arg)
  read(arg,*) submode
  mode4=ichar(submode) - ichar('A') + 1
  call getarg(3,arg)
  read(arg,*) fspread                !Frequency spread (Hz)
  call getarg(4,arg)
  read(arg,*) snrdb                  !S/N in dB (2500 hz reference BW)
  call getarg(5,arg)
  read(arg,*) nfiles                 !Number of files     

  rmsdb=25.
  rms=10.0**(0.05*rmsdb)
  fsample=12000.d0                   !Sample rate (Hz)
  dt=1.d0/fsample                    !Sample interval (s)
  twopi=8.d0*atan(1.d0)
  npts=60*12000
  sps=12000.d0/4.375d0               !2742.857...
  f0=1000.d0                         !Frequency of lowest tone (Hz)

  h=default_header(12000,npts)  

  if(message(1:3).eq.'sin') read(message(4:),*) sinfreq
  
  write(*,1000)
1000 format('File  S/N  Message'/    &
            '--------------------------------')

  call gen4(message,0,msgsent,itone,itype) !Encode message into tone #s
!  write(*,1030) itone
!1030 format(/'Channel symbols'/(30i2))


  do ifile=1,nfiles                            !Loop over all files
     nmin=(ifile-1)*2
     ihr=nmin/60
     imin=mod(nmin,60)
     write(fname,1002) ihr,imin                !Create output filename
1002 format('000000_',2i2.2)
     open(10,file=fname//'.wav',access='stream',status='unknown')

     if(snrdb.lt.90) then
        do i=1,npts
           dat(i)=gran()
        enddo
     else
        dat(1:npts)=0.
     endif

     snrdbx=snrdb 
     sig=10.0**(0.05*snrdbx)
     if(snrdb.gt.90.0) sig=1.0
     write(*,1020) ifile,snrdbx,msgsent
1020 format(i3,f7.1,2x,a22)

     phi=0.
     baud=12000.d0/sps
     isym0=0
     k0=12000
     do k=k0+1,npts
        isym=1.d0 + (k-k0)/sps
        if(isym.gt.206) exit
        if(isym.ne.isym0) then
           freq=f0 + itone(isym)*baud*nch(mode4)
           if(message(1:3).eq.'sin') freq=sinfreq
           dphi0=twopi*freq*dt
           dphi=dphi0
           isym0=isym
        endif

        if(fspread.gt.0.d0 .and. mod(k,120).eq.0) then
           call random_number(r)
           f=freq + 0.5*fspread*(r(1)+r(2)-1.0)
           dphi=twopi*f*dt
        endif

        phi=phi + dphi
        if(phi.gt.twopi) phi=phi-twopi
        xphi=phi
        dat(k)=dat(k) + sig*sin(xphi)
     enddo

     fac=32767.0
     if(snrdb.ge.90.0) iwave(1:npts)=nint(fac*dat(1:npts))
     if(snrdb.lt.90.0) iwave(1:npts)=nint(rms*dat(1:npts))
     
     write(10) h,iwave(1:npts)
     close(10)

  enddo

999 end program jt4sim
