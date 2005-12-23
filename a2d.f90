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
