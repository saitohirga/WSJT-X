subroutine multimode_decoder(ss,id2,params,nfsample)

  !$ use omp_lib
  use prog_args
  use timer_module, only: timer
  use jt4_decode
  use jt65_decode
  use jt9_decode

  include 'jt9com.f90'
  include 'timer_common.inc'

  type, extends(jt4_decoder) :: counting_jt4_decoder
     integer :: decoded
  end type counting_jt4_decoder

  type, extends(jt65_decoder) :: counting_jt65_decoder
     integer :: decoded
  end type counting_jt65_decoder

  type, extends(jt9_decoder) :: counting_jt9_decoder
     integer :: decoded
  end type counting_jt9_decoder

  real ss(184,NSMAX)
  logical baddata,newdat65,newdat9,single_decode
  integer*2 id2(NTMAX*12000)
  type(params_block) :: params
  real*4 dd(NTMAX*12000)
  save
  type(counting_jt4_decoder) :: my_jt4
  type(counting_jt65_decoder) :: my_jt65
  type(counting_jt9_decoder) :: my_jt9

  single_decode=iand(params%nexp_decode,32).ne.0
  if(mod(params%nranera,2).eq.0) ntrials=10**(params%nranera/2)
  if(mod(params%nranera,2).eq.1) ntrials=3*10**(params%nranera/2)
  if(params%nranera.eq.0) ntrials=0

  rms=sqrt(dot_product(float(id2(300000:310000)),            &
       float(id2(300000:310000)))/10000.0)
  if(rms.lt.2.0) go to 800 

  if (params%nagain) then
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown',                          &
          position='append')
  else
     open(13,file=trim(temp_dir)//'/decoded.txt',status='unknown')
  end if
  if(params%nmode.eq.4 .or. params%nmode.eq.65) open(14,file=trim(temp_dir)//'/avemsg.txt', &
       status='unknown')

  if(params%nmode.eq.4) then
     jz=52*nfsample
     if(params%newdat) then
        if(nfsample.eq.12000) call wav11(id2,jz,dd)
        if(nfsample.eq.11025) dd(1:jz)=id2(1:jz)
     endif
     call my_jt4%decode(jt4_decoded,dd,jz,params%nutc,params%nfqso,         &
          params%ntol,params%emedelay,params%dttol,logical(params%nagain),  &
          params%ndepth,logical(params%nclearave),params%minsync,           &
          params%minw,params%nsubmode,params%mycall,params%hiscall,         &
          params%hisgrid,params%nlist,params%listutc,jt4_average)
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

!$call omp_set_dynamic(.true.)
!$omp parallel sections num_threads(2) copyin(/timer_private/) shared(ndecoded) if(.true.) !iif() needed on Mac

!$omp section
  if(params%nmode.eq.65 .or. (params%nmode.eq.(65+9) .and. params%ntxmode.eq.65)) then
! We're in JT65 mode, or should do JT65 first
     if(newdat65) dd(1:npts65)=id2(1:npts65)
     nf1=params%nfa
     nf2=params%nfb
     call timer('jt65a   ',0)
     call my_jt65%decode(jt65_decoded,dd,npts65,newdat65,params%nutc,      &
          nf1,nf2,params%nfqso,ntol65,params%nsubmode,params%minsync,      &
          logical(params%nagain),params%n2pass,logical(params%nrobust),    &
          ntrials,params%naggressive,params%ndepth,                        &
          logical(params%nclearave),params%mycall,params%hiscall,          &
          params%hisgrid,params%nexp_decode)
     call timer('jt65a   ',1)

  else if(params%nmode.eq.9 .or. (params%nmode.eq.(65+9) .and. params%ntxmode.eq.9)) then
! We're in JT9 mode, or should do JT9 first
     call timer('decjt9  ',0)
     call my_jt9%decode(jt9_decoded,ss,id2,params%nfqso,       &
          newdat9,params%npts8,params%nfa,params%nfsplit,params%nfb,       &
          params%ntol,params%nzhsym,logical(params%nagain),params%ndepth,  &
          params%nmode,params%nsubmode,params%nexp_decode)
     call timer('decjt9  ',1)
  endif

!$omp section
  if(params%nmode.eq.(65+9)) then       !Do the other mode (we're in dual mode)
     if (params%ntxmode.eq.9) then
        if(newdat65) dd(1:npts65)=id2(1:npts65)
        nf1=params%nfa
        nf2=params%nfb
        call timer('jt65a   ',0)
        call my_jt65%decode(jt65_decoded,dd,npts65,newdat65,params%nutc,   &
             nf1,nf2,params%nfqso,ntol65,params%nsubmode,params%minsync,   &
             logical(params%nagain),params%n2pass,logical(params%nrobust), &
             ntrials,params%naggressive,params%ndepth,                     &
             logical(params%nclearave),params%mycall,params%hiscall,       &
             params%hisgrid,params%nexp_decode)
        call timer('jt65a   ',1)
     else
        call timer('decjt9  ',0)
        call my_jt9%decode(jt9_decoded,ss,id2,params%nfqso,                &
             newdat9,params%npts8,params%nfa,params%nfsplit,params%nfb,    &
             params%ntol,params%nzhsym,logical(params%nagain),             &
             params%ndepth,params%nmode,params%nsubmode,params%nexp_decode)
        call timer('decjt9  ',1)
     end if
  endif

!$omp end parallel sections

! JT65 is not yet producing info for nsynced, ndecoded.
  ndecoded = my_jt4%decoded + my_jt65%decoded + my_jt9%decoded
800 write(*,1010) nsynced,ndecoded
1010 format('<DecodeFinished>',2i4)
  call flush(6)
  close(13) 
  if(params%nmode.eq.4 .or. params%nmode.eq.65) close(14)

  return

contains

  subroutine jt4_decoded(this,snr,dt,freq,have_sync,sync,is_deep,    &
       decoded,qual,ich,is_average,ave)
    implicit none
    class(jt4_decoder), intent(inout) :: this
    integer, intent(in) :: snr
    real, intent(in) :: dt
    integer, intent(in) :: freq
    logical, intent(in) :: have_sync
    logical, intent(in) :: is_deep
    character(len=1), intent(in) :: sync
    character(len=22), intent(in) :: decoded
    real, intent(in) :: qual
    integer, intent(in) :: ich
    logical, intent(in) :: is_average
    integer, intent(in) :: ave

    character*2 :: cqual

!    write(*,3001) 'A',have_sync,is_deep,is_average,int(qual),ave,decoded
!3001 format(a1,3L2,2i4,1x,a22)
    if (have_sync) then
       write(cqual, '(i2)') int(qual)
       if(int(qual).eq.99) cqual=' f'
       if (int(qual).gt.0) then
          if (ave.gt.0) then
             write(*,1000) params%nutc,snr,dt,freq,sync,decoded,cqual,    &
                  char(ichar('A')+ich-1),ave
          else
             write(*,1000) params%nutc,snr,dt,freq,sync,decoded,cqual,    &
                  char(ichar('A')+ich-1)
          end if
       else
          if (ave.gt.0) then
             if(int(qual).eq.99) cqual=' f'
             write(*,1000) params%nutc,snr,dt,freq,sync,decoded,cqual,    &
                  char(ichar('A')+ich-1),ave
          else
             if(int(qual).le.0) then
                write(*,1000) params%nutc,snr,dt,freq,sync
             else
                write(*,1000) params%nutc,snr,dt,freq,sync,decoded,cqual,  &
                     char(ichar('A')+ich-1)
             endif
          endif
       end if
    else
       write(*,1000) params%nutc,snr,dt,freq
    end if
1000 format(i4.4,i4,f5.1,i5,1x,'$',a1,1x,a22,a2,1x,a1,i3)

    select type(this)
    type is (counting_jt4_decoder)
       this%decoded = this%decoded + 1
    end select
  end subroutine jt4_decoded

  subroutine jt4_average (this, used, utc, sync, dt, freq, flip)
    implicit none
    class(jt4_decoder), intent(inout) :: this
    logical, intent(in) :: used
    integer, intent(in) :: utc
    real, intent(in) :: sync
    real, intent(in) :: dt
    integer, intent(in) :: freq
    logical, intent(in) :: flip
    character(len=1) :: cused, csync

    cused = '.'
    csync = '*'
    if (used) cused = '$'
    if (flip) csync = '$'
    write(14,1000) cused,utc,sync,dt,freq,csync
1000 format(a1,i5.4,f6.1,f6.2,i6,1x,a1)
  end subroutine jt4_average

  subroutine jt65_decoded(this,sync,snr,dt,freq,drift,nflip,width,     &
       decoded0,ft,qual,nsmo,nsum,minsync)

    use jt65_decode
    implicit none

    class(jt65_decoder), intent(inout) :: this
    real, intent(in) :: sync
    integer, intent(in) :: snr
    real, intent(in) :: dt
    integer, intent(in) :: freq
    integer, intent(in) :: drift
    integer, intent(in) :: nflip
    real, intent(in) :: width
    character(len=22), intent(in) :: decoded0
    integer, intent(in) :: ft
    integer, intent(in) :: qual
    integer, intent(in) :: nsmo
    integer, intent(in) :: nsum
    integer, intent(in) :: minsync

    integer i,n
    character*5 ctail,decoded*22,csync*2
    character*36 c
    data c/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'/

!$omp critical(decode_results)
    decoded=decoded0
    if(ft.eq.0 .and. minsync.ge.0 .and. int(sync).lt.minsync) then
       write(*,1010) params%nutc,snr,dt,freq
    else
       ctail='     '
       if(params%naggressive.gt.0 .and. ft.gt.0) then
          ctail(1:1)='d'
          if(ft.eq.1) ctail(1:1)='f'
          n=max(2,nsum+1)
          n=min(n,36)
          ctail(2:2)=c(n:n)
          n=min(nsmo+1,36)
          if(params%nsubmode.gt.0) ctail(3:3)=c(n:n)
          if(ft.eq.2) then
             ctail(5:5)='*'
             if(qual.le.9) ctail(5:5)=char(48+qual)
             if(qual.lt.3) decoded(21:21)='?'
          endif
       endif
       csync='# '
       i=0
       if(single_decode .and. nflip.ne.0 .and.                         &
            sync.ge.max(0.0,float(minsync))) then
          csync='#*'
          if(nflip.eq.-1) then
             csync='##'
             if(decoded.ne.'                      ') then
                do i=22,1,-1
                   if(decoded(i:i).ne.' ') exit
                enddo
!                write(*,*) 'C',i,decoded
                if(i.gt.18) i=18
                decoded(i+2:i+4)='OOO'
             endif
          endif
       endif
       write(*,1010) params%nutc,snr,dt,freq,csync,decoded,ctail
1010   format(i4.4,i4,f5.1,i5,1x,a2,1x,a22,a5)
    endif

    write(13,1012) params%nutc,nint(sync),snr,dt,float(freq),drift,    &
         decoded,ft,nsum,nsmo
1012 format(i4.4,i4,i5,f6.2,f8.0,i4,3x,a22,' JT65',3i3)
    call flush(6)

!$omp end critical(decode_results)
    select type(this)
    type is (counting_jt65_decoder)
       this%decoded = this%decoded + 1
    end select
  end subroutine jt65_decoded

  subroutine jt9_decoded (this, sync, snr, dt, freq, drift, decoded)
    use jt9_decode
    implicit none

    class(jt9_decoder), intent(inout) :: this
    real, intent(in) :: sync
    integer, intent(in) :: snr
    real, intent(in) :: dt
    real, intent(in) :: freq
    integer, intent(in) :: drift
    character(len=22), intent(in) :: decoded

    !$omp critical(decode_results)
    write(*,1000) params%nutc,snr,dt,nint(freq),decoded
1000 format(i4.4,i4,f5.1,i5,1x,'@ ',1x,a22)
    write(13,1002) params%nutc,nint(sync),snr,dt,freq,drift,decoded
1002 format(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22,' JT9')
    call flush(6)
    !$omp end critical(decode_results)
    select type(this)
    type is (counting_jt9_decoder)
       this%decoded = this%decoded + 1
    end select
  end subroutine jt9_decoded

end subroutine multimode_decoder
