module jt65_test

  ! Test the JT65 decoder for WSJT-X

  implicit none

  public :: test
  integer, parameter, public :: NZMAX=60*12000
  integer, public :: nft

contains

  subroutine test (dd,nutc,nflow,nfhigh,nfqso,ntol,nsubmode,n2pass,nrobust     &
       ,ntrials,naggressive,ndepth,mycall,hiscall,hisgrid,nexp_decode)
    use timer_module, only: timer
    use jt65_decode
    implicit none

    include 'constants.f90'
    real, intent(in) :: dd(NZMAX)
    integer, intent(in) :: nutc, nflow, nfhigh, nfqso, ntol, nsubmode, n2pass  &
         , ntrials, naggressive, ndepth, nexp_decode
    logical, intent(in) :: nrobust
    character(len=12), intent(in) :: mycall, hiscall
    character(len=6), intent(in) :: hisgrid
    type(jt65_decoder) :: my_decoder
    logical nclearave                          !### Should be a dummy arg?
    nclearave=.false.

    call timer('jt65a   ',0)
    call my_decoder%decode(my_callback,dd,npts=52*12000,newdat=.true.,     &
         nutc=nutc,nf1=nflow,nf2=nfhigh,nfqso=nfqso,ntol=ntol,             &
         nsubmode=nsubmode, minsync=-1,nagain=.false.,n2pass=n2pass,       &
         nrobust=nrobust,ntrials=ntrials,naggressive=naggressive,          &
         ndepth=ndepth,clearave=nclearave,mycall=mycall,hiscall=hiscall,   &
         hisgrid=hisgrid,nexp_decode=nexp_decode)
    call timer('jt65a   ',1)
  end subroutine test

  subroutine my_callback (this,utc,sync,snr,dt,freq,drift,nflip,width,     &
       decoded,ft,qual,smo,sum,minsync,submode,aggression,single_decode)
    use jt65_decode
    implicit none

    class(jt65_decoder), intent(inout) :: this
    integer, intent(in) :: utc
    real, intent(in) :: sync
    integer, intent(in) :: snr
    real, intent(in) :: dt
    integer, intent(in) :: freq
    integer, intent(in) :: drift
    integer, intent(in) :: nflip
    real, intent(in) :: width
    character(len=22), intent(in) :: decoded
    integer, intent(in) :: ft
    integer, intent(in) :: qual
    integer, intent(in) :: smo
    integer, intent(in) :: sum
    integer, intent(in) :: minsync
    integer, intent(in) :: submode
    integer, intent(in) :: aggression
    logical, intent(in) :: single_decode

    integer nwidth
    real t

    t=max(0.0,width*width-7.2)
    nwidth=max(nint(sqrt(t)),2)
!### deal with nflip here! ###
!### also single_decode, csync, etc... ###
    write(*,1010) utc,snr,dt,freq,decoded
1010 format(i4.4,i4,f5.1,i5,1x,'#',1x,a22)
    write(13,1012) utc,nint(sync),snr,dt,freq,drift,nwidth,         &
         decoded,ft,sum,smo
1012 format(i4.4,i4,i5,f6.2,i5,i4,i3,1x,a22,' JT65',3i3)
    nft=ft
    call flush(6)
!    write(79,3001) utc,sync,snr,dt,freq,candidates,    &
!         hard_min,total_min,rtt,tries,ft,qual,decoded
!3001 format(i4.4,f5.1,i4,f5.1,i5,i6,i3,i4,f6.3,i8,i2,i3,1x,a22)

  end subroutine my_callback

end module jt65_test
