module ft8_decode

  type :: ft8_decoder
     procedure(ft8_decode_callback), pointer :: callback
   contains
     procedure :: decode
  end type ft8_decoder

  abstract interface
     subroutine ft8_decode_callback (this,sync,snr,dt,freq,nbadcrc,decoded)
       import ft8_decoder
       implicit none
       class(ft8_decoder), intent(inout) :: this
       real, intent(in) :: sync
       integer, intent(in) :: snr
       real, intent(in) :: dt
       real, intent(in) :: freq
       integer, intent(in) :: nbadcrc
       character(len=22), intent(in) :: decoded
     end subroutine ft8_decode_callback
  end interface

contains

  subroutine decode(this,callback,ss,iwave,nfqso,newdat,npts8,nutc,nfa,    &
       nfsplit,nfb,ntol,nzhsym,nagain,ndepth,nmode,nsubmode,nexp_decode)

    use timer_module, only: timer
    include 'fsk4hf/ft8_params.f90'

    class(ft8_decoder), intent(inout) :: this
    procedure(ft8_decode_callback) :: callback
    real ss(1,1)  !### dummy, to be removed ###
    real s(NH1,NHSYM)
    real candidate(3,100)
    logical, intent(in) :: newdat, nagain
    integer*2 iwave(15*12000)
    character datetime*13,message*22

    this%callback => callback

    write(datetime,1001) nutc        !### TEMPORARY ###
1001 format("000000_",i6.6)

    call timer('sync8   ',0)
    call sync8(iwave,s,candidate,ncand)
    call timer('sync8   ',1)

    rewind 51
    do icand=1,ncand
       f1=candidate(1,icand)
       xdt=candidate(2,icand)
       sync=candidate(3,icand)
       nsnr=min(99,nint(10.0*log10(sync) - 25.5))    !### empirical ###
       call timer('ft8b    ',0)
       call ft8b(s,f1,xdt,nharderrors,dmin,nbadcrc,message)
       call timer('ft8b    ',1)
       if (associated(this%callback)) call this%callback(sync,nsnr,xdt,   &
            freq,nbadcrc,message)
!       write(13,1110) datetime,0,nsnr,xdt,f1,nharderrors,dmin,message
!1110   format(a13,2i4,f6.2,f7.1,i4,' ~ ',f6.2,2x,a22,'  FT8')
       write(51,3051) xdt,f1,sync,dmin,nsnr,nharderrors,nbadcrc,message
3051 format(4f9.1,3i5,2x,a22)
    enddo
    flush(51)

    return
  end subroutine decode

end module ft8_decode
