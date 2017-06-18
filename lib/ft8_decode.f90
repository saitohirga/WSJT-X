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

  subroutine decode(this,callback,ss,id2,nfqso,newdat,npts8,nfa,    &
       nfsplit,nfb,ntol,nzhsym,nagain,ndepth,nmode,nsubmode,nexp_decode)
    use timer_module, only: timer

    include 'constants.f90'
    class(ft8_decoder), intent(inout) :: this
    procedure(ft8_decode_callback) :: callback
    real ss(184,NSMAX)
    logical, intent(in) :: newdat, nagain
    integer*2 id2(NTMAX*12000)

    print*,'A',nfqso,npts8,nfa,nfsplit,nfb,ntol,nzhsym,ndepth
    
    return
  end subroutine decode
end module ft8_decode
