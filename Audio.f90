! Fortran logical units used in WSJT6
!
!   10  wave files read from disk
!   11  decoded.txt
!   12  decoded.ave
!   13  tsky.dat
!   14  azel.dat
!   15  debug.txt
!   16  c:/wsjt.reg 
!   17  wave files written to disk
!   18  test file to be transmitted (wsjtgen.f90)
!   19
!   20
!   21  ALL.TXT
!   22  kvasd.dat
!   23  CALL3.TXT

!--------------------------------------------------- AudioInit
subroutine AudioInit


  return
end subroutine AudioInit

!---------------------------------------------------- a2d
subroutine a2d(iarg)

#ifdef Win32
! Start the PortAudio streams for audio input and output.
  integer nchin(0:20),nchout(0:20)
  include 'gcom1.f90'
  include 'gcom2.f90'

! This call does not normally return, as the background portion of
! JTaudio goes into a test-and-sleep loop.

  idevin=ndevin
  idevout=ndevout
  call padevsub(numdevs,ndefin,ndefout,nchin,nchout)
  
  write(*,1002) ndefin,ndefout
1002 format(/'Default   Input:',i3,'   Output:',i3)
  write(*,1004) idevin,idevout
1004 format('Requested Input:',i3,'   Output:',i3)
  if(idevin.lt.0 .or. idevin.ge.numdevs) idevin=ndefin
  if(idevout.lt.0 .or. idevout.ge.numdevs) idevout=ndefout
  if(idevin.eq.0 .and. idevout.eq.0) then
     idevin=ndefin
     idevout=ndefout
  endif
  ierr=jtaudio(idevin,idevout,y1,y2,NMAX,iwrite,iwave,nwave,    &
       11025,NSPB,TRPeriod,TxOK,ndebug,Transmitting,            &
       Tsec,ngo,nmode,tbuf,ibuf,ndsec)
  if(ierr.ne.0) then
     print*,'Error ',ierr,' in JTaudio, cannot continue.'
  else
     write(*,1006) 
1006 format('Audio streams terminated normally.')
  endif
#endif
  return
end subroutine a2d

!---------------------------------------------------- decode1
subroutine decode1(iarg)

! Get data and parameters from gcom, then call the decoders when needed.
! This routine runs in a background thread and will never return.

#ifdef Win32
  use dflib
#endif

  character sending0*28,fcum*80,mode0*6,cshort*11
  integer sendingsh0
  
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

  data sending0/'                      '/
  save

  ntr0=ntr
  ns0=999999

10 continue
  if(mode(1:4).eq.'JT65') then
     if(rxdone) then
        call savedata
        rxdone=.false.
     endif
  else
     if(ntr.ne.ntr0 .and. monitoring.gt.0) then
        if(ntr.ne.TxFirst .or. (lauto.eq.0)) call savedata
        ntr0=ntr
     endif
  endif

  if(ndecoding.gt.0) then
     ndecdone=0
     call decode2
     ndecdone=1
     if(mousebutton.eq.0) ndecoding0=ndecoding
     ndecoding=0
  endif

  if(ns0.lt.0) then
     rewind 21
     ns0=999999
  endif
  n=Tsec
  if(n.lt.ns0 .and. utcdate(1:1).eq.'2') then
     write(21,1001) utcdate(:11)
1001 format(/'UTC Date: ',a11/'---------------------')
     ns0=n
  endif

  if(transmitting.eq.1 .and. (sending.ne.sending0 .or.       &
       sendingsh.ne.sendingsh0 .or. mode.ne.mode0)) then
     ih=n/3600
     im=mod(n/60,60)
     is=mod(n,60)
     cshort='           '
     if(sendingsh.eq.1) cshort='(Shorthand)'
     write(21,1010) ih,im,is,mode,sending,cshort
1010 format(3i2.2,'  Transmitting: ',a6,2x,a28,2x,a11)
     sending0=sending
     sendingsh0=sendingsh
     mode0=mode
  endif
       
20 continue

#ifdef Win32
  call sleepqq(100)
#else
  call usleep(100*1000)
#endif

  go to 10

end subroutine decode1

!---------------------------------------------------- decode2
subroutine decode2

! Get data and parameters from gcom, then call the decoders

  character fnamex*24
  integer*2 d2d(30*11025)
  
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

! ndecoding  data  Action
!--------------------------------------
!    0             Idle
!    1       d2a   Standard decode, full file
!    2       y1    Mouse pick, top half
!    3       y1    Mouse pick, bottom half
!    4       d2c   Decode recorded file
!    5       d2a   Mouse pick, main window

  lenpick=22050                !Length of FSK441 mouse-picked region
  if(mode(1:4).eq.'JT6M') then
     lenpick=4*11025
     if(mousebutton.eq.3) lenpick=10*11025
  endif

  istart=1.0 + 11025*0.001*npingtime - lenpick/2
  if(istart.lt.2) istart=2
  if(ndecoding.eq.1) then
! Normal decoding at end of Rx period (or at t=53s in JT65)
     istart=1
     call decode3(d2a,jza,istart,fnamea)
  else if(ndecoding.eq.2) then

! Mouse pick, top half of waterfall
! The following is empirical:
     k=2048*ibuf0 + istart - 11025*mod(tbuf(ibuf0),dble(trperiod)) -3850
     if(k.le.0)      k=k+NRxMax
     if(k.gt.NrxMax) k=k-NRxMax
     nt=ntime/86400
     nt=86400*nt + tbuf(ibuf0)
     if(receiving.eq.0) nt=nt-trperiod
     call get_fname(hiscall,nt,trperiod,lauto,fnamex)
     do i=1,lenpick
        k=k+1
        if(k.gt.NrxMax) k=k-NRxMax
        d2b(i)=dgain*y1(k)
     enddo
     call decode3(d2b,lenpick,istart,fnamex)
  else if(ndecoding.eq.3) then

!Mouse pick, bottom half of waterfall
     ib0=ibuf0-161
     if(lauto.eq.1 .and. mute.eq.0 .and. transmitting.eq.1) ib0=ibuf0-323
     if(ib0.lt.1) ib0=ib0+1024
     k=2048*ib0 + istart - 11025*mod(tbuf(ib0),dble(trperiod)) - 3850
     if(k.le.0)      k=k+NRxMax
     if(k.gt.NrxMax) k=k-NRxMax
     nt=ntime/86400
     nt=86400*nt + tbuf(ib0)
     call get_fname(hiscall,nt,trperiod,lauto,fnamex)
     do i=1,lenpick
        k=k+1
        if(k.gt.NrxMax) k=k-NRxMax
        d2b(i)=dgain*y1(k)
     enddo
     call decode3(d2b,lenpick,istart,fnamex)

!Recorded file
  else if(ndecoding.eq.4) then
     jzz=jzc
     if(mousebutton.eq.0) istart=1
     if(mousebutton.gt.0) then
        jzz=lenpick
        if(mode(1:4).eq.'JT6M') jzz=4*11025
        istart=istart + 3300 - jzz/2
        if(istart.lt.2) istart=2
        if(istart+jzz.gt.jzc) istart=jzc-jzz
     endif
     call decode3(d2c(istart),jzz,istart,filename)

  else if(ndecoding.eq.5) then
! Mouse pick, main window (but not from recorded file)
     istart=istart - 1512
     if(istart.lt.2) istart=2
     if(istart+lenpick.gt.jza) istart=jza-lenpick
     call decode3(d2a(istart),lenpick,istart,fnamea)
  endif

  fnameb=fnamea

999 return

end subroutine decode2

!---------------------------------------------------- decode3
subroutine decode3(d2,jz,istart,filename)

#ifdef Win32
  use dfport
#endif

  integer*2 d2(jz),d2d(60*11025)
  real*8 sq
  character*24 filename
  character FileID*40
  character mycall0*12,hiscall0*12,hisgrid0*6
  logical savefile
  include 'gcom1.f90'
  include 'gcom2.f90'
  
  if(ichar(filename(1:1)).eq.0) go to 999
    
  FileID=filename
  decodedfile=filename
  lumsg=11
  nqrn=nclip+5
  nmode=1
  if(mode(1:4).eq.'JT65') then
     nmode=2
     if(mode(5:5).eq.'A') mode65=1
     if(mode(5:5).eq.'B') mode65=2
     if(mode(5:5).eq.'C') mode65=4
  endif
  if(mode.eq.'Echo') nmode=3
  if(mode.eq.'JT6M') nmode=4
  mode441=1

  sum=0.
  do i=1,jz
     sum=sum+d2(i)
  enddo
  nave=nint(sum/jz)
!    sq=0.d0
!    nsq=0
  do i=1,jz
     d2(i)=d2(i)-nave
     d2d(i)=d2(i)
!       if(abs(d2d(i)).gt.5) then
!          sq=sq+dfloat(d2d(i))**2
!          nsq=nsq+1
!       endif
  enddo
!    rms=sqrt(sq/nsq)
!    sig=(1.414/rms) * 10.0**(0.05*(-24.0)) * (2500.0/5512.5)
!    do i=1,jz
!       d2d(i)=nint(500.0 * (gasdev(idum) + sig*d2d(i)))
!    enddo

  if(nblank.ne.0) call blanker(d2d,jz)

  nseg=1
  if(mode(1:4).eq.'JT65') then
     i=index(FileID,'.')-3
     if(FileID(i:i).eq.'1'.or.FileID(i:i).eq.'3'.or.FileID(i:i).eq.'5'  &
          .or.FileID(i:i).eq.'7'.or.FileID(i:i).eq.'9') nseg=2
  endif

  open(23,file=appdir(:lenappdir)//'/CALL3.TXT',status='unknown')
  call wsjt1(d2d,jz,istart,samfacin,FileID,ndepth,MinSigdB,           &
       NQRN,DFTolerance,NSaveCum,MouseButton,NClearAve,               &
       nMode,NFreeze,NAFC,NZap,AppDir,utcdate,mode441,mode65,         &
       MyCall,HisCall,HisGrid,neme,nsked,naggressive,ntx2,s2,         &
       ps0,npkept,lumsg,basevb,rmspower,nslim2,psavg,ccf,Nseg,        &
       MouseDF,NAgain,LDecoded,nspecial,ndf,ss1,ss2)
  close(23)

! See whether this file should be saved or erased from disk
  if(nsave.eq.1 .and. ldecoded) filetokilla=''
  if(nsave.eq.3 .or. (nsave.eq.2 .and. lauto.eq.1)) then
     filetokilla=''
     filetokillb=''
  endif
  if(mousebutton.ne.0) filetokilla=''
  if(nsavelast.eq.1) filetokillb=''
  nsavelast=0
  ierr=unlink(filetokillb)
  
  nclearave=0
  nagain=0
  if(mode(1:4).eq.'JT65') then
     call pix2d65(d2d,jz)
  else if(mode.eq.'FSK441') then
     nz=s2(1,1)
     call pix2d(d2d,jz,mousebutton,s2,64,nz,b)
  else if(mode(1:4).eq.'JT6M' .and. mousebutton.eq.0) then
     nz=s2(1,1)
     call pix2d(d2d,jz,mousebutton,s2,64,nz,b)
  endif

! Compute red and magenta cutves for small plot area, FSK441/JT6M only
  if(mode.eq.'FSK441' .or. mode.eq.'JT6M') then
     do i=1,128
        if(mode.eq.'FSK441' .and. ps0(i).gt.0.0) ps0(i)=10.0*log10(ps0(i))
        if(psavg(i).gt.0.0) psavg(i)=10.0*log10(psavg(i))
     enddo
  endif

999 return
end subroutine decode3

include 'pix2d.f90'
include 'pix2d65.f90'
include 'blanker.f90'

!----------------------------------------------------------- savedata
subroutine savedata

#ifdef Win32
  use dfport
#endif

  character fname*24,longname*80
  data ibuf0z/1/
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  save

  if(mode(1:4).eq.'JT65') then
     call get_fname(hiscall,ntime,trperiod,lauto,fname0)
     ibuf1=ibuf0
     ibuf2=ibuf
     go to 1
  else
     call get_fname(hiscall,ntime-trperiod,trperiod,lauto,fname0)
  endif

  if(ibuf0.eq.ibuf0z) go to 999         !Startup condition, do not save
  if(ntrbuf(ibuf0z).eq.1) go to 999     !We were transmitting, do not save

! Get buffer pointers, then copy completed Rx sequence from y1 to d2a:
  ibuf1=ibuf0z
  ibuf2=ibuf0-1
1 jza=2048*(ibuf2-ibuf1)
  if(jza.lt.0) jza=jza+NRxMax
  lenok=1
  if(jza.lt.110250) go to 999           !Don't save files less than 10 s
  if(jza.gt.60*11025) go to 999         !Don't save if something's fishy
  k=2048*(ibuf1-1)
  if(mode(1:4).ne.'JT65') k=k+3*2048
  if(mode(1:4).ne.'JT65' .and. jza.gt.30*11025) then
     k=k + (jza-30*11025)
     if(k.gt.NRxMax) k=k-NRxMax
     jza=30*11025
  endif

! Check timestamps of buffers used for this data
  msbig=0
  i=k/2048
  if(msmax.eq.0) i=i+1
  nz=jza/2048
  if(msmax.eq.0) then
     i=i+1
     nz=nz-1
  endif
  do n=1,nz
     i=i+1
     if(i.gt.1024) i=i-1024
     i0=i-1
     if(i0.lt.1) i0=i0+1024
     dtt=tbuf(i)-tbuf(i0)
     ms=0
     if(dtt.gt.0.d0 .and. dtt.lt.80000.0) ms=1000.d0*dtt
     msbig=max(ms,msbig)
  enddo

  if(ndebug.gt.0 .and. msbig.gt.msmax .and. msbig.gt.330) then
     write(*,1020) msbig
1020 format('Warning: interrupt service interval',i11,' ms.')
  endif
  msmax=max(msbig,msmax)

  do i=1,jza
     k=k+1
     if(k.gt.NRxMax) k=k-NRxMax
     xx=dgain*y1(k)
     xx=min(32767.0,max(-32767.0,xx))
     d2a(i)=nint(xx)
  enddo
  fnamea=fname0

  npingtime=0
  fname=fnamea                   !Save filename for output to disk
  nagain=0
  ndecoding=1                    !Request decoding
  
! Generate file name and write data to file
!    if(nsave.ge.2 .and. ichar(fname(1:1)).ne.0) then
  if(ichar(fname(1:1)).ne.0) then

! Generate header for wavefile:
     ariff='RIFF'
     awave='WAVE'
     afmt='fmt '
     adata='data'
     lenfmt=16
     nfmt2=1
     nchan2=1
     nsamrate=11025
     nbytesam2=2
     nbytesec=nchan2*nsamrate*nbytesam2
     nbitsam2=16
     ndata=2*jza
     nbytes=ndata+44
     nchunk=nbytes-8
     
     do i=80,1,-1
        if(appdir(i:i).ne.' ') go to 10
     enddo
10   longname=AppDir(1:i)//'/RxWav/'//fname

#ifdef Win32
     open(17,file=longname,status='unknown',form='binary',err=20)
#else
     open(17,file=longname,status='unknown',form='unformatted',err=20)
#endif
     write(17) ariff,nchunk,awave,afmt,lenfmt,nfmt2,nchan2,nsamrate, &
          nbytesec,nbytesam2,nbitsam2,adata,ndata,(d2a(j),j=1,jza)
     close(17)
     filetokillb=filetokilla
     filetokilla=longname
     go to 30
20   print*,'Error opening Fortran unit 17.'
     print*,longname
30   continue
  endif

999 if(mode(1:4).ne.'JT65') then
     ibuf0z=ibuf0
     ntime0=ntime
     call get_fname(hiscall,ntime,trperiod,lauto,fname0)
  endif

  return
end subroutine savedata

subroutine get_fname(hiscall,ntime,trperiod,lauto,fname)

#ifdef Win32
  use dfport
#endif

  character hiscall*12,fname*24,tag*7
  integer ntime
  integer trperiod
  integer it(9)

  n1=ntime
  n2=(n1+2)/trperiod
  n3=n2*trperiod
  call gmtime(n3,it)
  it(5)=it(5)+1
  it(6)=mod(it(6),100)
  write(fname,1000) (it(j),j=6,1,-1)
1000 format('_',3i2.2,'_',3i2.2,'.WAV')
  tag=hiscall
  i=index(hiscall,'/')
  if(i.ge.5) tag=hiscall(1:i-1)
  if(i.ge.2.and.i.le.4) tag=hiscall(i+1:)
  if(lauto.eq.0) tag='Mon'
  i=index(tag,' ')
  fname=tag(1:i-1)//fname
  
  return
end subroutine get_fname

!---------------------------------------------------- End Module Audio1

!---------------------------------------------------- spec
subroutine spec(brightness,contrast,logmap,ngain,nspeed,a)

! Called by SpecJT in its TopLevel Python code.  
! Probably should use the "!f2py intent(...)" structure here.

! Input:
  integer brightness,contrast   !Display parameters
  integer ngain                 !Digital gain for input audio
  integer nspeed                !Scrolling speed index
! Output:
  integer*2 a(225000)           !Pixel values for 750 x 300 array

  real psa(750)                 !Grand average spectrum
  real ref(750)                 !Ref spect: smoothed ave of lower half
  real birdie(750)              !Spec (with birdies) for plot, in dB
  real variance(750)            !Variance in each spectral channel

  real a0(225000)               !Save the last 300 spectra
  integer*2 idat(11025)         !Sound data, read from file
  integer nstep(5)
  integer b0,c0
  real x(4096)                  !Data for FFT
  complex c(0:2048)             !Complex spectrum
  real ss(1024)                 !Bottom half of power spectrum
  logical first
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'
  data jz/0/                    !Number of spectral lines available
  data nstep/15,10,5,2,1/       !Integration limits
  data first/.true./

  equivalence (x,c)
  save

  if(first) then
     call zero(ss,nq)
     istep=2205
     nfft=4096
     nq=nfft/4
     df=11025.0/nfft
     fac=2.0/10000.
     nsum=0
     iread=0
     cversion='5.5.0   '
     first=.false.
     b0=-999
     c0=-999
     logmap0=-999
     nspeed0=-999
     nx=0
     ncall=0
     jza=0
     rms=0.
  endif

  nmode=1
  if(mode(1:4).eq.'JT65') nmode=2
  if(mode.eq.'Echo') nmode=3
  if(mode.eq.'JT6M') nmode=4

  nlines=0
  newdat=0
  npts=iwrite-iread
  if(ndiskdat.eq.1) then
     npts=jzc/2048
     npts=2048*npts
     kread=0
     if(nspeed.ge.6) then
        call hscroll(a,nx)
        nx=0
     endif
  endif
  if(npts.lt.0) npts=npts+nmax
  if(npts.lt.nfft) go to 900               !Not enough data available

10 continue
  if(ndiskdat.eq.1) then
! Data read from disk
     k=kread
     do i=1,nfft
        k=k+1
        x(i)=0.4*d2c(k)
     enddo
     kread=kread+istep                       !Update pointer
  else
! Real-time data
     dgain=2.0*10.0**(0.005*ngain)
     k=iread
     do i=1,nfft
        k=k+1
        if(k.gt.nmax) k=k-nmax
        x(i)=0.5*dgain*y1(k)
     enddo
     iread=iread+istep                       !Update pointer
     if(iread.gt.nmax) iread=iread-nmax
  endif

  sum=0.                                     !Get ave, rms of data
  do i=1,nfft
     sum=sum+x(i)
  enddo
  ave=sum/nfft
  sq=0.
  do i=1,nfft
     d=x(i)-ave
     sq=sq+d*d
     x(i)=fac*d
  enddo
  rms1=sqrt(sq/nfft)
  if(rms.eq.0) rms=rms1
  rms=0.25*rms1 + 0.75*rms
  
  if(ndiskdat.eq.0) then
     level=0                                    !Compute S-meter level
     if(rms.gt.0.0) then                        !Scale 0-100, steps = 0.4 dB
        dB=20.0*log10(rms/800.0)
        level=50 + 2.5*dB
        if(level.lt.0) level=0
        if(level.gt.100) level=100
     endif
  endif

  if(nspeed.ge.6) then
     call horizspec(x,brightness,contrast,a)
     ncall=Mod(ncall+1,5)
     if(ncall.eq.1 .or. nspeed.eq.7) newdat=1
     if(ndiskdat.eq.1) then
        npts=jzc-kread
     else
        npts=iwrite-iread
        if(npts.lt.0) npts=npts+nmax
     endif
     if(npts.ge.4096) go to 10
     go to 900
  endif

  call xfft(x,nfft)

  do i=1,nq                               !Accumulate power spectrum
     ss(i)=ss(i) + real(c(i))**2 + imag(c(i))**2
  enddo
  nsum=nsum+1

  if(nsum.ge.nstep(nspeed)) then      !Integrate for specified time
     nlines=nlines+1
     do i=225000,751,-1               !Move spectra up one row
        a0(i)=a0(i-750)               ! (will be "down" on display)
     enddo
     if(ndiskdat.eq.1 .and. nlines.eq.1) then
        do i=1,750
           a0(i)=255
        enddo
        do i=225000,751,-1
           a0(i)=a0(i-750)
        enddo
     endif

     if(nflat.gt.0) call flat2(ss,1024,nsum)

     do i=1,750                       !Insert new data in top row
        j=i+182                       ! ?? was 186 ??
        a0(i)=5*ss(j)/nsum
        xdb=-40.
        if(a0(i).gt.0.) xdb=10*log10(a0(i))
     enddo
     nsum=0
     newdat=1                          !Flag for new spectrum available
     call zero(ss,nq)                  !Zero the accumulating array
     if(jz.lt.300) jz=jz+1
  endif

  if(ndiskdat.eq.1) then
     npts=jzc-kread
  else
     npts=iwrite-iread
     if(npts.lt.0) npts=npts+nmax
  endif

  if(npts.ge.4096) go to 10

!  Compute pixel values 
  iz=750
  logmap=0
  if(brightness.ne.b0 .or. contrast.ne.c0 .or. logmap.ne.logmap0 .or.    &
          nspeed.ne.nspeed0 .or. nlines.gt.1) then
     iz=225000
     gain=40*sqrt(nstep(nspeed)/5.0) * 5.0**(0.01*contrast)
     gamma=1.3 + 0.01*contrast
     offset=(brightness+64.0)/2
     b0=brightness
     c0=contrast
     logmap0=logmap
     nspeed0=nspeed
  endif

!  print*,brightness,contrast,logmap,gain,gamma,offset
  do i=1,iz
     n=0
     if(a0(i).gt.0.0 .and. logmap.eq.1) n=gain*log10(0.001*a0(i)) + offset + 20
     if(a0(i).gt.0.0 .and. logmap.eq.0) n=(0.01*a0(i))**gamma + offset
     n=min(252,max(0,n))
     a(i)=n
  enddo

900 continue
  return
end subroutine spec

!------------------------------------------------------ horizspec
subroutine horizspec(x,brightness,contrast,a)

  real x(4096)
  integer brightness,contrast
  integer*2 a(750,300)
  real y(512),ss(128)
  complex c(0:256)
  equivalence (y,c)
  include 'gcom1.f90'
  include 'gcom2.f90'
  save

  nfft=512
  nq=nfft/4
  gain=50.0 * 3.0**(0.36+0.01*contrast)
  gamma=1.3 + 0.01*contrast
  offset=0.5*(brightness+30.0)
!  offset=0.5*(brightness+60.0)
  df=11025.0/512.0
  if(ntr.ne.ntr0) then
     if(lauto.eq.0 .or. ntr.eq.TxFirst) then
        call hscroll(a,nx)
        nx=0
     endif
     ntr0=ntr
  endif

  i0=0
  do iter=1,5
     if(nx.lt.750) nx=nx+1
     if(nx.eq.1) then
        t0curr=Tsec
     endif
     do i=1,nfft
        y(i)=1.4*x(i+i0)
     enddo
     call xfft(y,nfft)
     nq=nfft/4
     do i=1,nq
        ss(i)=real(c(i))**2 + imag(c(i))**2
     enddo

     p=0.
     do i=21,120
        p=p+ss(i)
        n=0
! Use the gamma formula here!
        if(ss(i).gt.0.) n=gain*log10(0.05*ss(i)) + offset
!        if(ss(i).gt.0.) n=(0.2*ss(i))**gamma + offset
        n=min(252,max(0,n))
        j=121-i
        a(nx,j)=n
     enddo
     if(nx.eq.7 .or. nx.eq.378 .or. nx.eq.750) then
! Put in yellow ticks at the standard tone frequencies for FSK441, or
! at the sync-tone frequency for JT65, JT6M.
        do i=nx-4,nx
           if(mode.eq.'FSK441') then
              do n=2,5
                 j=121-nint(n*441/df)
                 a(i,j)=254
              enddo
           else if(mode(1:4).eq.'JT65') then
              j=121-nint(1270.46/df)
              a(i,j)=254
           else if(mode.eq.'JT6M') then
              j=121-nint(1076.66/df)
              a(i,j)=254
           endif
        enddo
     endif

     ng=140 - 30*log10(0.00033*p+0.001)
     ng=min(ng,150)
     if(nx.eq.1) ng0=ng
     if(abs(ng-ng0).le.1) then
        a(nx,ng)=255
     else
        ist=1
        if(ng.lt.ng0) ist=-1
        jmid=(ng+ng0)/2
        i=max(1,nx-1)
        do j=ng0+ist,ng,ist
           a(i,j)=255
           if(j.eq.jmid) i=i+1
        enddo
        ng0=ng
     endif
     i0=i0+441
  enddo

  return
end subroutine horizspec

!------------------------------------------------- hscroll
subroutine hscroll(a,nx)
  integer*2 a(750,300)

  do j=1,150
     do i=1,750
        if(nx.gt.50) a(i,150+j)=a(i,j)
        a(i,j)=0
     enddo
  enddo
  return

end subroutine hscroll

!------------------------------------------------ ftn_init
subroutine ftn_init

  character*1 cjunk
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

  addpfx='    '

  do i=80,1,-1
     if(AppDir(i:i).ne.' ') goto 1
  enddo
1 iz=i
  lenappdir=iz

#ifdef Win32
  open(11,file=appdir(:iz)//'/decoded.txt',status='unknown',               &
       share='denynone',err=910)
#else
  open(11,file=appdir(:iz)//'/decoded.txt',status='unknown',               &
       err=910)
#endif
  endfile 11

#ifdef Win32
  open(12,file=appdir(:iz)//'/decoded.ave',status='unknown',               &
       share='denynone',err=920)
#else
  open(12,file=appdir(:iz)//'/decoded.ave',status='unknown',               &
       err=920)
#endif
  endfile 12

#ifdef Win32
  open(14,file=appdir(:iz)//'/azel.dat',status='unknown',                  &
       share='denynone',err=930)
#else
  open(14,file=appdir(:iz)//'/azel.dat',status='unknown',                  &
       err=930)
#endif

#ifdef Win32
  open(15,file=appdir(:iz)//'/debug.txt',status='unknown',                 &
       share='denynone',err=940)
#else
  open(15,file=appdir(:iz)//'/debug.txt',status='unknown',                 &
       err=940)
#endif

#ifdef Win32
  open(21,file=appdir(:iz)//'/ALL.TXT',status='unknown',                   &
       access='append',share='denynone',err=950)
#else
  open(21,file=appdir(:iz)//'/ALL.TXT',status='unknown',err=950)
  do i=1,9999999
     read(21,*,end=10) cjunk
  enddo
10 continue
#endif

#ifdef Win32
  open(22,file=appdir(:iz)//'/kvasd.dat',access='direct',recl=1024,        &
       status='unknown',share='denynone')
#else
  open(22,file=appdir(:iz)//'/kvasd.dat',access='direct',recl=1024,        &
       status='unknown')
#endif

  return

910 print*,'Error opening DECODED.TXT'
  stop
920 print*,'Error opening DECODED.AVE'
  stop
930 print*,'Error opening AZEL.DAT'
  stop
940 print*,'Error opening DEBUG.TXT'
  stop
950 print*,'Error opening ALL.TXT'
  stop

end subroutine ftn_init

!------------------------------------------------ ftn_quit
subroutine ftn_quit
  call four2a(a,-1,1,1,1)
  return
end subroutine ftn_quit

!------------------------------------------------ audio_init
subroutine audio_init(ndin,ndout)

#ifdef Win32
  use dfmt
  integer Thread1,Thread2
  external a2d,decode1
#endif

  integer*2 a(225000)           !Pixel values for 750 x 300 array
  integer brightness,contrast
  include 'gcom1.f90'

  ndevin=ndin
  ndevout=ndout
  TxOK=0
  Transmitting=0
  nfsample=11025
  nspb=1024
  nbufs=2048
  nmax=nbufs*nspb
  nwave=60*nfsample
  ngo=1
  brightness=0
  contrast=0
  nsec=1
  df=11025.0/4096
  f0=800.0
  do i=1,nwave
     iwave(i)=nint(32767.0*sin(6.283185307*i*f0/nfsample))
  enddo

#ifdef Win32
!  Priority classes (for processes):
!     IDLE_PRIORITY_CLASS               64
!     NORMAL_PRIORITY_CLASS             32
!     HIGH_PRIORITY_CLASS              128

!  Priority definitions (for threads):
!     THREAD_PRIORITY_IDLE             -15
!     THREAD_PRIORITY_LOWEST            -2
!     THREAD_PRIORITY_BELOW_NORMAL      -1
!     THREAD_PRIORITY_NORMAL             0
!     THREAD_PRIORITY_ABOVE_NORMAL       1
!     THREAD_PRIORITY_HIGHEST            2
!     THREAD_PRIORITY_TIME_CRITICAL     15
    
  m0=SetPriorityClass(GetCurrentProcess(),NORMAL_PRIORITY_CLASS)

! Start a thread for doing A/D and D/A with sound card.
  Thread1=CreateThread(0,0,a2d,0,CREATE_SUSPENDED,id)
  m1=SetThreadPriority(Thread1,THREAD_PRIORITY_ABOVE_NORMAL)
  m2=ResumeThread(Thread1)

! Start a thread for background decoding.
  Thread2=CreateThread(0,0,decode1,0,CREATE_SUSPENDED,id)
  m3=SetThreadPriority(Thread2,THREAD_PRIORITY_BELOW_NORMAL)
  m4=ResumeThread(Thread2)
#else
  call start_threads
#endif

  return
end subroutine audio_init

!----------------------------------------------------- getfile
subroutine getfile(fname,len)

#ifdef Win32
  use dflib
#endif

  parameter (NDMAX=60*11025)
  character*(*) fname
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom4.f90'


  integer*1 d1(NDMAX)
  integer*1 hdr(44),n1
  integer*2 d2(NDMAX)
  integer*2 nfmt2,nchan2,nbitsam2,nbytesam2
  character*4 ariff,awave,afmt,adata
  common/hdr/ariff,lenfile,awave,afmt,lenfmt,nfmt2,nchan2, &
     nsamrate,nbytesec,nbytesam2,nbitsam2,adata,ndata,d2
  equivalence (ariff,hdr),(n1,n4),(d1,d2)

1 if(ndecoding.eq.0) go to 2
#ifdef Win32
  call sleepqq(100)
#else
  call usleep(100*1000)
#endif

  go to 1

2 do i=len,1,-1
     if(fname(i:i).eq.'/' .or. fname(i:i).eq.'\\') go to 10
  enddo
  i=0
10 filename=fname(i+1:)
  ierr=0

#ifdef Win32
  open(10,file=fname,form='binary',status='old',err=998)
  read(10,end=998) hdr
#else
  call rfile2(fname,hdr,44+2*NDMAX,nr)
#endif

  if(nbitsam2.eq.8) then
     if(ndata.gt.NDMAX) ndata=NDMAX

#ifdef Win32
     call rfile(10,d1,ndata,ierr)
     if(ierr.ne.0) go to 999
#endif

     do i=1,ndata
        n1=d1(i)
        n4=n4+128
        d2c(i)=250*n1
     enddo
     jzc=ndata

  else if(nbitsam2.eq.16) then
     if(ndata.gt.2*NDMAX) ndata=2*NDMAX
#ifdef Win32
     call rfile(10,d2c,ndata,ierr)
     if(ierr.ne.0) go to 999
#else
     jzc=ndata/2
     do i=1,jzc
        d2c(i)=d2(i)
     enddo
#endif
  endif

  if(monitoring.eq.0) then
! In this case, spec should read data from d2c
!     jzc=jzc/2048
!     jzc=jzc*2048
     ndiskdat=1
  endif

  mousebutton=0
  ndecoding=4

  go to 999

998 ierr=1001
999 close(10)
  return
end subroutine getfile

!----------------------------------------------------- rfile
subroutine rfile(lu,ibuf,n,ierr)

  integer*1 ibuf(n)

  read(lu,end=998) ibuf
  ierr=0
  go to 999
998 ierr=1002
999  return
end subroutine rfile

!--------------------------------------------------- i1tor4
subroutine i1tor4(d,jz,data)

!  Convert wavefile byte data from to real*4.

  integer*1 d(jz)
  real data(jz)
  integer*1 i1
  equivalence(i1,i4)

  do i=1,jz
     n=d(i)
     i4=n-128
     data(i)=i1
  enddo

  return
end subroutine i1tor4

!---------------------------------------------------- azdist0

subroutine azdist0(MyGrid,HisGrid,utch,nAz,nEl,nDmiles,nDkm,nHotAz,nHotABetter)
  character*6 MyGrid,HisGrid
  real*8 utch
!f2py intent(in) MyGrid,HisGrid,utch
!f2py intent(out) nAz,nEl,nDmiles,nDkm,nHotAz,nHotABetter

  if(hisgrid(5:5).eq.' ' .or. ichar(hisgrid(5:5)).eq.0) hisgrid(5:5)='m'
  if(hisgrid(6:6).eq.' ' .or. ichar(hisgrid(6:6)).eq.0) hisgrid(6:6)='m'
  call azdist(MyGrid,HisGrid,utch,nAz,nEl,nDmiles,nDkm,nHotAz,nHotABetter)
  return
end subroutine azdist0

!--------------------------------------------------- astro0
subroutine astro0(nyear,month,nday,uth8,nfreq,grid,cauxra,cauxdec,       &
     AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,ntsky,ndop,ndop00,  &
     dbMoon8,RAMoon8,DecMoon8,HA8,Dgrd8,sd8,poloffset8,xnr8,dfdt,dfdt0,  &
     RaAux8,DecAux8,AzAux8,ElAux8)

!f2py intent(in) nyear,month,nday,uth8,nfreq,grid,cauxra,cauxdec
!f2py intent(out) AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,ntsky,ndop,ndop00,dbMoon8,RAMoon8,DecMoon8,HA8,Dgrd8,sd8,poloffset8,xnr8,dfdt,dfdt0,RaAux8,DecAux8,AzAux8,ElAux8

  character grid*6
  character*9 cauxra,cauxdec
  real*8 utch8
  real*8 AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,AzAux8,ElAux8
  real*8 dbMoon8,RAMoon8,DecMoon8,HA8,Dgrd8,xnr8,dfdt,dfdt0
  real*8 sd8,poloffset8
  include 'gcom2.f90'
  data uth8z/0.d0/,imin0/-99/
  save

  auxra=0.
  i=index(cauxra,':')
  if(i.eq.0) then
     read(cauxra,*,err=1,end=1) auxra
  else
     read(cauxra(1:i-1),*,err=1,end=1) ih
     read(cauxra(i+1:i+2),*,err=1,end=1) im
     read(cauxra(i+4:i+5),*,err=1,end=1) is
     auxra=ih + im/60.0 + is/3600.0
  endif
1 auxdec=0.
  i=index(cauxdec,':')
  if(i.eq.0) then
     read(cauxdec,*,err=2,end=2) auxdec
  else
     read(cauxdec(1:i-1),*,err=2,end=2) id
     read(cauxdec(i+1:i+2),*,err=2,end=2) im
     read(cauxdec(i+4:i+5),*,err=2,end=2) is
     auxdec=id + im/60.0 + is/3600.0
  endif

2 nmode=1
  if(mode(1:4).eq.'JT65') then
     nmode=2
     if(mode(5:5).eq.'A') mode65=1
     if(mode(5:5).eq.'B') mode65=2
     if(mode(5:5).eq.'C') mode65=4
  endif
  if(mode.eq.'Echo') nmode=3
  if(mode.eq.'JT6M') nmode=4
  uth=uth8

  call astro(AppDir,nyear,month,nday,uth,nfreq,hisgrid,2,nmode,1,    &
       AzSun,ElSun,AzMoon,ElMoon,ntsky,doppler00,doppler,            &
       dbMoon,RAMoon,DecMoon,HA,Dgrd,sd,poloffset,xnr,auxra,auxdec,  &
       AzAux,ElAux)
  AzMoonB8=AzMoon
  ElMoonB8=ElMoon
  call astro(AppDir,nyear,month,nday,uth,nfreq,grid,1,nmode,1,       &
       AzSun,ElSun,AzMoon,ElMoon,ntsky,doppler00,doppler,            &
       dbMoon,RAMoon,DecMoon,HA,Dgrd,sd,poloffset,xnr,auxra,auxdec,  &
       AzAux,ElAux)

  RaAux8=auxra
  DecAux8=auxdec
  AzSun8=AzSun
  ElSun8=ElSun
  AzMoon8=AzMoon
  ElMoon8=ElMoon
  dbMoon8=dbMoon
  RAMoon8=RAMoon/15.0
  DecMoon8=DecMoon
  HA8=HA
  Dgrd8=Dgrd
  sd8=sd
  poloffset8=poloffset
  xnr8=xnr
  AzAux8=AzAux
  ElAux8=ElAux
  ndop=nint(doppler)
  ndop00=nint(doppler00)

  if(uth8z.eq.0.d0) then
     uth8z=uth8-1.d0/3600.d0
     dopplerz=doppler
     doppler00z=doppler00
  endif
     
  dt=60.0*(uth8-uth8z)
  if(dt.le.0) dt=1.d0/60.d0
  dfdt=(doppler-dopplerz)/dt
  dfdt0=(doppler00-doppler00z)/dt
  uth8z=uth8
  dopplerz=doppler
  doppler00z=doppler00

  imin=60*uth8
  isec=3600*uth8

  if(isec.ne.isec0) then
     ih=uth8
     im=mod(imin,60)
     is=mod(isec,60)
     rewind 14
     write(14,1010) ih,im,is,AzMoon,ElMoon
1010 format(i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Moon')
     write(14,1012) ih,im,is,AzSun,ElSun
1012 format(i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Sun')
     write(14,1013) ih,im,is,AzAux,ElAux
1013 format(i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Source')
     write(14,1014) nfreq,doppler,dfdt,doppler00,dfdt0
1014 format(i4,',',f6.1,',',f6.2,',',f6.1,',',f6.2,',Doppler')
     rewind 14
     isec0=isec
  endif

  return
end subroutine astro0

include 'makedate_sub.f90'
include 'abc441.f90'
