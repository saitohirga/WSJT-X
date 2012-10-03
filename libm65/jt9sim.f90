program jt9sim

! Generate simulated data for testing of WSJT-X

  parameter (NMAX=1800*12000)
  integer ihdr(11)
  integer*2 iwave                  !Generated waveform (no noise)
  real*8 f0,f,dt,twopi,phi,dphi,baud,fspan
  character msg*22,msg0*22,message*22,msgsent*22,arg*8,fname*11

  integer*4 itone(85)              !Channel symbols (values 0-8)
  integer*4 i4DataSymNoGray(69)    !Data Symbols, values 0-7
  integer*1 i1ScrambledBits(207)   !Hard-decision demodulated bits, interleaved
  integer*1 i1Bits(207)          !Encoded information-carrying bits
  integer*1 i1SoftSymbols(207)
  integer*1 i1
  equivalence (i1,i4)

  integer isync(85)                !Sync vector
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/
  common/acom/dat(NMAX),iwave(NMAX)

  nargs=iargc()
  if(nargs.ne.6) then
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
  npts=12000*(60*minutes-6)
  nsps=0
  if(minutes.eq.1)  nsps=6912
  if(minutes.eq.2)  nsps=15360
  if(minutes.eq.5)  nsps=40960
  if(minutes.eq.10) nsps=82944
  if(minutes.eq.30) nsps=252000
  if(nsps.eq.0) stop 'Bad value for minutes.'
  ihdr=0                             !Temporary ###
  
  open(12,file='msgs.txt',status='old')

  write(*,1000)
1000 format('File  N    freq      S/N  Message'/    &
            '---------------------------------------------------')

  do ifile=1,nfiles
     nmin=(ifile-1)*2*minutes
     ihr=nmin/60
     imin=mod(nmin,60)
     write(fname,1002) ihr,imin                !Create the output filenames
1002 format('000000_',2i2.2)
     open(10,file=fname//'.wav',access='stream',status='unknown')

     if(snrdb.lt.90) then
        do i=1,npts
           dat(i)=gran()
        enddo
     else
        dat(1:npts)=0.
     endif

     if(msg0.ne.'                      ') then
        call genjt9(message,minutes,msgsent,itone)
     endif

     rewind 12
     do isig=1,nsigs

        if(msg0.eq.'                      ') then
           read(12,1004) message
1004       format(a22)
           call genjt9(message,minutes,msgsent,itone)
        endif

        f=f0
        if(nsigs.gt.1) f=f0 - 0.5d0*fspan + fspan*(isig-1.d0)/(nsigs-1.d0)
        snrdbx=snrdb
!        if(snrdb.ge.-1.0) snrdbx=-15.0 - 15.0*(isig-1.0)/nsigs
        sig=sqrt(2500.0/6000.0) * 10.0**(0.05*snrdbx)
        write(*,1020) ifile,isig,f,snrdbx,msgsent
1020    format(i3,i4,f10.3,f7.1,2x,a22)

        phi=0.
        baud=12000.0/nsps
        k=12000                             !Start at t = 1 s
        do isym=1,85
           freq=f + itone(isym)*baud
           dphi=twopi*freq*dt
           do i=1,nsps
              phi=phi + dphi
              if(phi.lt.-twopi) phi=phi+twopi
              if(phi.gt.twopi) phi=phi-twopi
              xphi=phi
              k=k+1
              dat(k)=dat(k) + sig*sin(xphi)  !Use lookup table for i*2 sin(x) ?
           enddo
        enddo
     enddo

     do i=1,npts
        iwave(i)=nint(rms*dat(i))
     enddo

     write(10) ihdr,iwave(1:npts)
     close(10)

! We're done!  Now decode the data symbols from itone, as a test.
     j=0
     do i=1,85
        if(isync(i).eq.1) cycle
        j=j+1
        i4DataSymNoGray(j)=igray(itone(i)-1,-1)
     enddo

     call unpackbits(i4DataSymNoGray,69,3,i1ScrambledBits)
     call interleave9(i1ScrambledBits,-1,i1Bits)

     do i=1,206
        i4=-10
        if(i1Bits(i).eq.1) i4=10
        i4=i4+128
        i1SoftSymbols(i)=i1
     enddo

     call decode9(i1SoftSymbols,msg)

     if(msg.ne.msg0) print*,'Decode error: ',msg0,' ',msg

  enddo

999 end program jt9sim
