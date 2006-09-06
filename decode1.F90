
!---------------------------------------------------- decode1
subroutine decode1(iarg)

! Get data and parameters from gcom, then call the decoders when needed.
! This routine runs in a background thread and will never return.

#ifdef Win32
  use dflib
#endif

  character sending0*28,mode0*6,cshort*11
  integer sendingsh0
  
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

  data sending0/'                      '/
  save

  ntr0=ntr
  ns0=999999

10 continue
  if(mode(1:4).eq.'JT65') then
     if(rxdone) then
        call savedata
        rxdone=.false.
     endif
  else
     if(ntr.ne.ntr0 .and. monitoring.gt.0) then
        if(ntr.ne.TxFirst .or. (lauto.eq.0)) call savedata
        ntr0=ntr
     endif
  endif

  if(ndecoding.gt.0) then
     ndecdone=0
     call decode2
     ndecdone=1
     if(mousebutton.eq.0) ndecoding0=ndecoding
     ndecoding=0
  endif

  if(ns0.lt.0) then
     rewind 21
     ns0=999999
  endif
  n=Tsec
  if(n.lt.ns0 .and. utcdate(1:1).eq.'2') then
     write(21,1001) utcdate(:11)
1001 format(/'UTC Date: ',a11/'---------------------')
     ns0=n
  endif

  if(transmitting.eq.1 .and. (sending.ne.sending0 .or.       &
       sendingsh.ne.sendingsh0 .or. mode.ne.mode0)) then
     ih=n/3600
     im=mod(n/60,60)
     is=mod(n,60)
     cshort='           '
     if(sendingsh.eq.1) cshort='(Shorthand)'
     write(21,1010) ih,im,is,mode,sending,cshort
1010 format(3i2.2,'  Transmitting: ',a6,2x,a28,2x,a11)
     sending0=sending
     sendingsh0=sendingsh
     mode0=mode
  endif
       
20 continue

#ifdef Win32
  call sleepqq(100)
#else
  call usleep(100*1000)
#endif

  go to 10

end subroutine decode1
