
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
