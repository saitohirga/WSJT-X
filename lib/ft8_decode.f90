module ft8_decode

  type :: ft8_decoder
     procedure(ft8_decode_callback), pointer :: callback
   contains
     procedure :: decode
  end type ft8_decoder

  abstract interface
     subroutine ft8_decode_callback (this,sync,snr,dt,freq,decoded)
       import ft8_decoder
       implicit none
       class(ft8_decoder), intent(inout) :: this
       real, intent(in) :: sync
       integer, intent(in) :: snr
       real, intent(in) :: dt
       real, intent(in) :: freq
       character(len=22), intent(in) :: decoded
     end subroutine ft8_decode_callback
  end interface

contains

  subroutine decode(this,callback,iwave,nfqso,newdat,nutc,nfa,    &
       nfb,nagain,ndepth,nsubmode,mycall12,hiscall12,hisgrid6)
!    use wavhdr
    use timer_module, only: timer
    include 'fsk4hf/ft8_params.f90'
!    type(hdr) h

    class(ft8_decoder), intent(inout) :: this
    procedure(ft8_decode_callback) :: callback
    real s(NH1,NHSYM)
    real candidate(3,200)
    real dd(15*12000)
    logical, intent(in) :: nagain
    logical newdat,lsubtract
    character*12 mycall12, hiscall12
    character*6 hisgrid6
    integer*2 iwave(15*12000)
    integer apsym(KK)
    character datetime*13,message*22
    save s,dd

    this%callback => callback
    write(datetime,1001) nutc        !### TEMPORARY ###
1001 format("000000_",i6.6)

    call ft8apset(mycall12,hiscall12,hisgrid6,apsym,iaptype)

    dd=iwave

! For now:
! ndepth=1: no subtraction, 1 pass, belief propagation only
! ndepth=2: subtraction, 2 passes, belief propagation only
! ndepth=3: subtraction, 2 passes, bp+osd2 at and near nfqso
    if(ndepth.eq.1) npass=1
    if(ndepth.ge.2) npass=2
    do ipass=1,npass
      newdat=.true.  ! Is this a problem? I hijacked newdat.
      if(ipass.eq.1) then
        lsubtract=.true.
        if(ndepth.eq.1) lsubtract=.false.
        syncmin=1.3
      else
        lsubtract=.false.
        syncmin=1.3
      endif 
      call timer('sync8   ',0)
      call sync8(dd,nfa,nfb,syncmin,nfqso,s,candidate,ncand)
      call timer('sync8   ',1)
      do icand=1,ncand
        sync=candidate(3,icand)
        f1=candidate(1,icand)
        xdt=candidate(2,icand)
        nsnr0=min(99,nint(10.0*log10(sync) - 25.5))    !### empirical ###
        call timer('ft8b    ',0)
        call ft8b(dd,newdat,nfqso,ndepth,lsubtract,iaptype,icand,sync,f1,   &
             xdt,apsym,nharderrors,dmin,nbadcrc,iap,ipass,iera,message,xsnr)
        nsnr=xsnr  
        xdt=xdt-0.6
        call timer('ft8b    ',1)
        if(nbadcrc.eq.0 .and. associated(this%callback)) then
           call this%callback(sync,nsnr,xdt,f1,message)
!           write(81,3081) ncand,icand,iera,nharderrors,ipass,iap,iaptype,    &
!                db(sync),f1,xdt,dmin,xsnr,message
!3081       format(2i5,i2,i3,i2,i2,i2,f7.2,f7.1,3f7.2,1x,a22)
!           flush(81)
        endif
      enddo
!     h=default_header(12000,NMAX)
!     open(10,file='subtract.wav',status='unknown',access='stream')
!     iwave=nint(dd)
!     write(10) h,iwave
!     close(10)
  enddo
  return
  end subroutine decode

end module ft8_decode
