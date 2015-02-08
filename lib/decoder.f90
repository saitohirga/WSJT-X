subroutine decoder(ss,id2)

  use prog_args
  !$ use omp_lib

  include 'constants.f90'
  real ss(184,NSMAX)
  character*20 datetime
  logical baddata
  integer*2 id2(NTMAX*12000)
  real*4 dd(NTMAX*12000)
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfsplit,nfb,    &
       ntol,kin,nzhsym,nsave,nagain,ndepth,ntxmode,nmode,datetime
  common/tracer/limtrace,lu
  integer onlevel(0:10)
  common/tracer_priv/level,onlevel
  !$omp threadprivate(/tracer_priv/)
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
  newdat65=newdat
  newdat9=newdat

  !$ call omp_set_dynamic(.true.)
  !$omp parallel sections num_threads(2) copyin(/tracer_priv/) shared(ndecoded)

  !$omp section
  if(nmode.eq.65 .or. (nmode.gt.65 .and. ntxmode.eq.65)) then
! We're decoding JT65 or should do this mode first
     if(newdat65.ne.0) dd(1:npts65)=id2(1:npts65)
     nf1=nfa
     nf2=nfb
     call timer('jt65a   ',0)
     call jt65a(dd,npts65,newdat65,nutc,nf1,nf2,nfqso,ntol65,nagain,ndecoded)
     call timer('jt65a   ',1)
  else
! We're decoding JT9 or should do this mode first
     call timer('decjt9  ',0)
     call decjt9(ss,id2,nutc,nfqso,newdat9,npts8,nfa,nfsplit,nfb,ntol,nzhsym,  &
          nagain,ndepth,nmode)
     call timer('decjt9  ',1)
  endif

  !$omp section
  if(nmode.gt.65) then          ! do the other mode in dual mode
     if (ntxmode.eq.9) then
        if(newdat65.ne.0) dd(1:npts65)=id2(1:npts65)
        nf1=nfa
        nf2=nfb
        call timer('jt65a   ',0)
        call jt65a(dd,npts65,newdat65,nutc,nf1,nf2,nfqso,ntol65,nagain,ndecoded)
        call timer('jt65a   ',1)
     else
        call timer('decjt9  ',0)
        call decjt9(ss,id2,nutc,nfqso,newdat9,npts8,nfa,nfsplit,nfb,ntol,   &
             nzhsym,nagain,ndepth,nmode)
        call timer('decjt9  ',1)
     end if
  endif

  !$omp end parallel sections

! JT65 is not yet producing info for nsynced, ndecoded.
800 write(*,1010) nsynced,ndecoded
1010 format('<DecodeFinished>',2i4)
  call flush(6)
  close(13)
  close(22)

  return
end subroutine decoder
