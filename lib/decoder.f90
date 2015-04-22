subroutine decoder(ss,id2,nfsample)

  use prog_args
  !$ use omp_lib

  include 'constants.f90'
  real ss(184,NSMAX)
  logical baddata
  integer*2 id2(NTMAX*12000)
  real*4 dd(NTMAX*12000)
  character datetime*20,mycall*12,mygrid*6,hiscall*12,hisgrid*6
  common/npar/nutc,ndiskdat,ntrperiod,nfqso,newdat,npts8,nfa,nfsplit,nfb,    &
       ntol,kin,nzhsym,nsubmode,nagain,ndepth,ntxmode,nmode,minw,nclearave,  &
       emedelay,dttol,nlist,listutc(10),datetime,mycall,mygrid,hiscall,hisgrid

  common/tracer/limtrace,lu
  integer onlevel(0:10)
  common/tracer_priv/level,onlevel
  !$omp threadprivate(/tracer_priv/)
  save

  rms=sqrt(dot_product(float(id2(300000:310000)),                            &
                       float(id2(300000:310000)))/10000.0)
  if(rms.lt.2.0) go to 800 

  if (nagain .eq. 0) then
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown')
  else
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown',      &
          position='append')
  end if
  if(nmode.eq.4 .or. nmode.eq.65) open(14,file=trim(temp_dir)//'/avemsg.txt', &
       status='unknown')

  if(nmode.eq.65 .or. nmode.eq.(65+9)) open(22,file=trim(temp_dir)//    &
       '/kvasd.dat',access='direct',recl=1024,status='unknown')

  if(nmode.eq.4) then
     jz=52*nfsample
     if(newdat.ne.0) then
        if(nfsample.eq.12000) call wav11(id2,jz,dd)
        if(nfsample.eq.11025) dd(1:jz)=id2(1:jz)
     endif
     call jt4a(dd,jz,nutc,nfqso,newdat,nfa,nfb,ntol,emedelay,dttol,     &
          nagain,ndepth,nclearave,minw,nsubmode,mycall,mygrid,hiscall,  &
          hisgrid,nlist,listutc)
     go to 800
  endif

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
!$omp parallel sections num_threads(2) copyin(/tracer_priv/) shared(ndecoded) if(.true.) !iif() needed on Mac

!$omp section
  if(nmode.eq.65 .or. (nmode.eq.(65+9) .and. ntxmode.eq.65)) then
! We're in JT65 mode, or should do JT65 first
     if(newdat65.ne.0) dd(1:npts65)=id2(1:npts65)
     nf1=nfa
     nf2=nfb
     call timer('jt65a   ',0)
     call jt65a(dd,npts65,newdat65,nutc,nf1,nf2,nfqso,ntol65,nsubmode,      &
          nagain,ndecoded)
     call timer('jt65a   ',1)

  else if(nmode.eq.9 .or. (nmode.eq.(65+9) .and. ntxmode.eq.9)) then
! We're in JT9 mode, or should do JT9 first
     call timer('decjt9  ',0)
     call decjt9(ss,id2,nutc,nfqso,newdat9,npts8,nfa,nfsplit,nfb,ntol,nzhsym,  &
          nagain,ndepth,nmode)
     call timer('decjt9  ',1)
  endif

!$omp section
  if(nmode.eq.(65+9)) then          !Do the other mode (we're in dual mode)
     if (ntxmode.eq.9) then
        if(newdat65.ne.0) dd(1:npts65)=id2(1:npts65)
        nf1=nfa
        nf2=nfb
        call timer('jt65a   ',0)
        call jt65a(dd,npts65,newdat65,nutc,nf1,nf2,nfqso,ntol65,nsubmode,   &
             nagain,ndecoded)
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
  if(nmode.eq.4 .or. nmode.eq.65) close(14)
  close(22)

  return
end subroutine decoder
