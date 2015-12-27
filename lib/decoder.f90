subroutine decoder(ss,id2,params,nfsample)

  !$ use omp_lib
  use prog_args
  use timer_module, only: timer

  include 'jt9com.f90'
  include 'timer_common.inc'

  real ss(184,NSMAX)
  logical baddata
  integer*2 id2(NTMAX*12000)
  type(params_block) :: params
  real*4 dd(NTMAX*12000)
  save

  if(mod(params%nranera,2).eq.0) ntrials=10**(params%nranera/2)
  if(mod(params%nranera,2).eq.1) ntrials=3*10**(params%nranera/2)
  if(params%nranera.eq.0) ntrials=0

  rms=sqrt(dot_product(float(id2(300000:310000)),                            &
                       float(id2(300000:310000)))/10000.0)
  if(rms.lt.2.0) go to 800 

  if (params%nagain .eq. 0) then
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown')
  else
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown',      &
          position='append')
  end if
  if(params%nmode.eq.4 .or. params%nmode.eq.65) open(14,file=trim(temp_dir)//'/avemsg.txt', &
       status='unknown')

  if(params%nmode.eq.4) then
     jz=52*nfsample
     if(params%newdat.ne.0) then
        if(nfsample.eq.12000) call wav11(id2,jz,dd)
        if(nfsample.eq.11025) dd(1:jz)=id2(1:jz)
     endif
     call jt4a(dd,jz,params%nutc,params%nfqso,params%ntol,params%emedelay,params%dttol,  &
          params%nagain,params%ndepth,params%nclearave,params%minsync,params%minw,       &
          params%nsubmode,params%mycall,params%hiscall,params%hisgrid,                   &
          params%nlist,params%listutc)
     go to 800
  endif

  npts65=52*12000
  if(baddata(id2,npts65)) then
     nsynced=0
     ndecoded=0
     go to 800
  endif

  ntol65=params%ntol              !### is this OK? ###
  newdat65=params%newdat
  newdat9=params%newdat

!$ call omp_set_dynamic(.true.)
!$omp parallel sections num_threads(2) copyin(/timer_private/) shared(ndecoded) if(.true.) !iif() needed on Mac

!$omp section
  if(params%nmode.eq.65 .or. (params%nmode.eq.(65+9) .and. params%ntxmode.eq.65)) then
! We're in JT65 mode, or should do JT65 first
     if(newdat65.ne.0) dd(1:npts65)=id2(1:npts65)
     nf1=params%nfa
     nf2=params%nfb
     call timer('jt65a   ',0)
     call jt65a(dd,npts65,newdat65,params%nutc,nf1,nf2,params%nfqso,ntol65,params%nsubmode,      &
          params%minsync,params%nagain,params%n2pass,params%nrobust,ntrials,params%naggressive,  &
          params%ndepth,params%mycall,params%hiscall,params%hisgrid,params%nexp_decode,ndecoded)
     call timer('jt65a   ',1)

  else if(params%nmode.eq.9 .or. (params%nmode.eq.(65+9) .and. params%ntxmode.eq.9)) then
! We're in JT9 mode, or should do JT9 first
     call timer('decjt9  ',0)
     call decjt9(ss,id2,params%nutc,params%nfqso,newdat9,params%npts8,params%nfa,params%nfsplit,  &
          params%nfb,params%ntol,params%nzhsym,params%nagain,params%ndepth,params%nmode)
     call timer('decjt9  ',1)
  endif

!$omp section
  if(params%nmode.eq.(65+9)) then          !Do the other mode (we're in dual mode)
     if (params%ntxmode.eq.9) then
        if(newdat65.ne.0) dd(1:npts65)=id2(1:npts65)
        nf1=params%nfa
        nf2=params%nfb
        call timer('jt65a   ',0)
        call jt65a(dd,npts65,newdat65,params%nutc,nf1,nf2,params%nfqso,ntol65,params%nsubmode,   &
             params%minsync,params%nagain,params%n2pass,params%nrobust,ntrials,                  &
             params%naggressive,params%ndepth,params%mycall,params%hiscall,params%hisgrid,       &
             params%nexp_decode,ndecoded)
        call timer('jt65a   ',1)
     else
        call timer('decjt9  ',0)
        call decjt9(ss,id2,params%nutc,params%nfqso,newdat9,params%npts8,params%nfa,params%nfsplit,  &
             params%nfb,params%ntol,params%nzhsym,params%nagain,params%ndepth,params%nmode)
        call timer('decjt9  ',1)
     end if
  endif

!$omp end parallel sections

! JT65 is not yet producing info for nsynced, ndecoded.
800 write(*,1010) nsynced,ndecoded
1010 format('<DecodeFinished>',2i4)
  call flush(6)
  close(13) 
  if(params%nmode.eq.4 .or. params%nmode.eq.65) close(14)

  return
end subroutine decoder
