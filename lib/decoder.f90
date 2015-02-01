subroutine decoder(ss,id2)

  use prog_args

  include 'constants.f90'
  real ss(184,NSMAX)
  character*20 datetime
  logical done65,baddata
  integer*2 id2(NTMAX*12000)
  real*4 dd(NTMAX*12000)
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfsplit,nfb,    &
       ntol,kin,nzhsym,nsave,nagain,ndepth,ntxmode,nmode,datetime
  common/tracer/limtrace,lu
  save

  nfreqs0=0
  nfreqs1=0
  ndecodes0=0
  ndecodes1=0

  if (nagain .eq. 0) then
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown')
  else
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown',      &
          position='append')
  end if
  open(22,file=trim(temp_dir)//'/kvasd.dat',access='direct',recl=1024,  &
       status='unknown')

  npts65=52*12000
  if(baddata(id2,npts65)) then
     nsynced=0
     ndecoded=0
     go to 800
  endif

  ntol65=20
  done65=.false.
  if((nmode.eq.65 .or. nmode.eq.65+9) .and. ntxmode.eq.65) then
! We're decoding JT65, and should do this mode first
     if(newdat.ne.0) dd(1:npts65)=id2(1:npts65)
     nf1=nfa
     nf2=nfb
     call jt65a(dd,npts65,newdat,nutc,nf1,nf2,nfqso,ntol65,nagain,ndecoded)
     done65=.true.
  endif

  if(nmode.eq.65) go to 800

!  print*,'A'
!!$OMP PARALLEL PRIVATE(id)
!!$OMP SECTIONS

!!$OMP SECTION
!  print*,'B'
  call decjt9(ss,id2,nutc,nfqso,newdat,npts8,nfa,nfsplit,nfb,ntol,nzhsym,  &
       nagain,ndepth,nmode)

!!$OMP SECTION
  if(nmode.ge.65 .and. (.not.done65)) then
     if(newdat.ne.0) dd(1:npts65)=id2(1:npts65)
     nf1=nfa
     nf2=nfb
!     print*,'C'
     call jt65a(dd,npts65,newdat,nutc,nf1,nf2,nfqso,ntol65,nagain,ndecoded)
  endif

!!$OMP END SECTIONS NOWAIT
!!$OMP END PARALLEL 
!  print*,'D'

! JT65 is not yet producing info for nsynced, ndecoded.
800 write(*,1010) nsynced,ndecoded
1010 format('<DecodeFinished>',2i4)
  call flush(6)
  close(13)
  close(22)

  return
end subroutine decoder
