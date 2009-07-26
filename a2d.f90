subroutine a2d(iarg)

! Start the PortAudio streams for audio input and output.
  integer nchin(0:20),nchout(0:20)
  include 'gcom1.f90'
  include 'gcom2.f90'

! This call does not normally return, as the background portion of
! JTaudio goes into a test-and-sleep loop.

  call cs_lock('a2d')
  write(*,1000)
1000 format('Using Linrad for input, PortAudio for output.')
  idevout=ndevout
  call padevsub(numdevs,ndefin,ndefout,nchin,nchout)
  
  write(*,1002) ndefout
1002 format(/'Default Output:',i3)
  write(*,1004) idevout
1004 format('Requested Output:',i3)
  if(idevout.lt.0 .or. idevout.ge.numdevs) idevout=ndefout
  if(idevout.eq.0) idevout=ndefout
  idevin=0
  call cs_unlock
  ierr=jtaudio(idevin,idevout,y1,y2,NMAX,iwrite,iwave,nwave,    &
       11025,NSPB,TRPeriod,TxOK,ndebug,Transmitting,            &
       Tsec,ngo,nmode,tbuf,ibuf,ndsec)
  if(ierr.ne.0) then
     print*,'Error ',ierr,' in JTaudio, cannot continue.'
  else
     write(*,1006) 
1006 format('Audio output stream terminated normally.')
  endif
  return
end subroutine a2d
