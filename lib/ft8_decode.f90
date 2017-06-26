module ft8_decode

  type :: ft8_decoder
     procedure(ft8_decode_callback), pointer :: callback
   contains
     procedure :: decode
  end type ft8_decoder

  abstract interface
     subroutine ft8_decode_callback (this, sync, snr, dt, freq, drift, &
          decoded)
       import ft8_decoder
       implicit none
       class(ft8_decoder), intent(inout) :: this
       real, intent(in) :: sync
       integer, intent(in) :: snr
       real, intent(in) :: dt
       real, intent(in) :: freq
       integer, intent(in) :: drift
       character(len=22), intent(in) :: decoded
     end subroutine ft8_decode_callback
  end interface

contains

  subroutine decode(this,callback,ss,iwave,nfqso,newdat,npts8,nutc,nfa,    &
       nfsplit,nfb,ntol,nzhsym,nagain,ndepth,nmode,nsubmode,nexp_decode)
    use timer_module, only: timer

!    include 'constants.f90'
    include 'fsk4hf/ft8_params.f90'

    class(ft8_decoder), intent(inout) :: this
    procedure(ft8_decode_callback) :: callback
    real ss(1,1)  !### dummy, to be removed ###
    real s(NH1,NHSYM)
    real candidate(3,100)
    logical, intent(in) :: newdat, nagain
    integer*2 iwave(15*12000)
    character*13 datetime

    write(datetime,1001) nutc        !### TEMPORARY ###
1001 format("000000_",i6.6)

    call sync8(iwave,s,candidate,ncand)
    call ft8b(datetime,s,candidate,ncand)
!     if (associated(this%callback)) then
!        call this%callback(sync,nsnr,xdt,freq,ndrift,msg)
!     end if
     
    return
  end subroutine decode

end module ft8_decode
