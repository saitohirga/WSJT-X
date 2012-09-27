program jt9sim

! Generate simulated data for testing of MAP65

  parameter (NMAX=1800*12000)
  real*4 d4(NMAX)                     !Floating-point data
  integer ihdr(11)
  integer*2 id2(NMAX)                 !i*2 data
  integer*2 iwave(NMAX)               !Generated waveform (no noise)
  real*8 f0,f,dt,twopi,phi,dphi,baud
  character msg0*22,message*22,msgsent*22,arg*8,fname*11
  logical lwave
  integer*1 d7(81)

  nargs=iargc()
  if(nargs.ne.9) then
     print*,'Usage: jt9sim "message" fspan nsigs minutes SNR nfiles'
     print*,'Example:  "CQ K1ABC FN42" 200  20      2    -28    1'
     print*,' '
     print*,'Enter message = "" to use entries in msgs.txt.'
     print*,'Enter SNR = 0 to generate a range of SNRs.'
     go to 999
  endif

  call getarg(1,msg0)
  message=msg0                       !Transmitted message
  call getarg(2,arg)
  read(arg,*) fspan                  !Total freq range (Hz)
  call getarg(3,arg)
  read(arg,*) nsigs                  !Number of signals in each file
  call getarg(4,arg)
  read(arg,*) minutes                !Length of file (1 2 5 10 30 minutes)
  call getarg(5,arg)
  read(arg,*) snrdb                  !S/N in dB (2500 hz reference BW)
  call getarg(6,arg)
  read(arg,*) nfiles                 !Number of files

  rmsdb=25.
  rms=10.0**(0.05*rmsdb)
  f0=1500.d0                         !Center frequency (MHz)
  fsample=12000.d0                   !Sample rate (Hz)
  dt=1.d0/fsample                    !Sample interval (s)
  twopi=8.d0*atan(1.d0)
  rad=360.0/twopi
  npts=12000*(60*minutes-6)
  lwave=.false.
  nsps1=0
  if(minutes.eq.1)  nsps1=7168
  if(minutes.eq.2)  nsps1=16000
  if(minutes.eq.5)  nsps1=42336
  if(minutes.eq.10) nsps1=86400
  if(minutes.eq.30) nsps1=262144
  if(nsps1.eq.0) stop 'Bad value for minutes.'
  
  open(12,file='msgs.txt',status='old')

  write(*,1000)
1000 format('File  N   freq     S/N  Message'/    &
            '---------------------------------------------------')

  do ifile=1,nfiles
     nmin=(ifile-1)*minutes
     ihr=nmin/60
     imin=mod(nmin,60)
     write(fname,1002) ihr,imin                !Create the output filenames
1002 format('000000_',2i2.2)
     open(10,file=fname//'.wav',access='stream',status='unknown')

     call noisegen(d4,npts)                      !Generate Gaussian noise

     if(msg0.ne.'                      ') then
        call genjt9(message,minutes,lwave,msgsent,d7,iwave,nwave)
     endif

     rewind 12
     do isig=1,nsigs

        if(msg0.eq.'                      ') then
           read(12,1004) message
1004       format(a22)
           call genjt9(message,minutes,lwave,msgsent,d7,iwave,nwave)
        endif
           
        f=1500.d0
        if(nsigs.gt.1) f=1500.0 - 0.5* fspan + fspan*(isig-1.0)/(nsigs-1.0)
        snrdbx=snrdb
        if(snrdb.ge.-1.0) snrdbx=-15.0 - 15.0*(isig-1.0)/nsigs
        sig=sqrt(2.2*2500.0/96000.0) * 10.0**(0.05*snrdbx)
        write(*,1020) ifile,isig,0.001*f,snrdbx,msgsent
1020    format(i3,i4,f8.3,f7.1,2x,a22)

        phi=0.
        baud=12000.0/nsps1
        k=12000                             !Start at t = 1 s
        do isym=1,81
           freq=f + d7(isym)*baud
           dphi=twopi*freq*dt + 0.5*twopi
           do i=1,nsps1
              phi=phi + dphi
              if(phi.lt.-twopi) phi=phi+twopi
              if(phi.gt.twopi) phi=phi-twopi
              xphi=phi
              k=k+1
              d4(k)=d4(k) + sin(phi)
           enddo
        enddo
     enddo

     do i=1,npts
        id2(i)=nint(rms*d4(i))
     enddo

     write(10) ihdr,id2(1:npts)
     close(10)
  enddo

999 end program jt9sim
