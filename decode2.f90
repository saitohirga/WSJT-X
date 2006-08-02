
!---------------------------------------------------- decode2
subroutine decode2

! Get data and parameters from gcom, then call the decoders

  character fnamex*24
  integer*2 d2d(30*11025)
  
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

! ndecoding  data  Action
!--------------------------------------
!    0             Idle
!    1       d2a   Standard decode, full file
!    2       y1    Mouse pick, top half
!    3       y1    Mouse pick, bottom half
!    4       d2c   Decode recorded file
!    5       d2a   Mouse pick, main window

  lenpick=22050                !Length of FSK441 mouse-picked region
  if(mode(1:4).eq.'JT6M') then
     lenpick=4*11025
     if(mousebutton.eq.3) lenpick=10*11025
  endif

  istart=1.0 + 11025*0.001*npingtime - lenpick/2
  if(istart.lt.2) istart=2
  if(ndecoding.eq.1) then
! Normal decoding at end of Rx period (or at t=53s in JT65)
     istart=1
     call decode3(d2a,jza,istart,fnamea)
  else if(ndecoding.eq.2) then

! Mouse pick, top half of waterfall
! The following is empirical:
     k=2048*ibuf0 + istart - 11025*mod(tbuf(ibuf0),dble(trperiod)) -3850
     if(k.le.0)      k=k+NRxMax
     if(k.gt.NrxMax) k=k-NRxMax
     nt=ntime/86400
     nt=86400*nt + tbuf(ibuf0)
     if(receiving.eq.0) nt=nt-trperiod
     call get_fname(hiscall,nt,trperiod,lauto,fnamex)
     do i=1,lenpick
        k=k+1
        if(k.gt.NrxMax) k=k-NRxMax
        d2b(i)=dgain*y1(k)
     enddo
     call decode3(d2b,lenpick,istart,fnamex)
  else if(ndecoding.eq.3) then

!Mouse pick, bottom half of waterfall
     ib0=ibuf0-161
     if(lauto.eq.1 .and. mute.eq.0 .and. transmitting.eq.1) ib0=ibuf0-323
     if(ib0.lt.1) ib0=ib0+1024
     k=2048*ib0 + istart - 11025*mod(tbuf(ib0),dble(trperiod)) - 3850
     if(k.le.0)      k=k+NRxMax
     if(k.gt.NrxMax) k=k-NRxMax
     nt=ntime/86400
     nt=86400*nt + tbuf(ib0)
     call get_fname(hiscall,nt,trperiod,lauto,fnamex)
     do i=1,lenpick
        k=k+1
        if(k.gt.NrxMax) k=k-NRxMax
        d2b(i)=dgain*y1(k)
     enddo
     call decode3(d2b,lenpick,istart,fnamex)

!Recorded file
  else if(ndecoding.eq.4) then
     jzz=jzc
     if(mousebutton.eq.0) istart=1
     if(mousebutton.gt.0) then
        jzz=lenpick

!  This is a major kludge:
        if(mode(1:4).eq.'JT6M') then          
           jzz=4*11025
           if(mousebutton.eq.3) jzz=10*11025
           istart=istart+11025
        else
           istart=istart + 3300 - jzz/2
        endif

        if(istart.lt.2) istart=2
        if(istart+jzz.gt.jzc) istart=jzc-jzz
     endif
     call decode3(d2c(istart),jzz,istart,filename)

  else if(ndecoding.eq.5) then
! Mouse pick, main window (but not from recorded file)
     istart=istart - 1512
     if(istart.lt.2) istart=2
     if(istart+lenpick.gt.jza) istart=jza-lenpick
     call decode3(d2a(istart),lenpick,istart,fnamea)
  endif

  fnameb=fnamea

999 return

end subroutine decode2
