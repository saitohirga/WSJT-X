subroutine decode1(iarg)

! Get data and parameters from gcom, then call the decoders when needed.
! This routine runs in a background thread and will never return.

#ifdef Win32
  use dflib
#endif

  character sending0*28,mode0*6,cshort*11
  integer sendingsh0

  include 'datcom.f90'
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'

  data sending0/'                      '/
  save

  ntr0=ntr
  ns0=999999

10 continue
  if(newdat2.gt.0) then
     call getfile2(fname80,nlen)
     newdat2=0
     kbuf=1
     kk=NSMAX
     kkdone=0
     newdat=1
  endif

  if((kk-kkdone).gt.32768) call symspec(id,kbuf,kk,kkdone,nutc,t00,newdat)

  if(ndecoding.gt.0 .and. mode(1:4).eq.'JT65') then
     ndecdone=0
     call map65a(newdat)
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

  call sleep_msec(1000)                  !### was 100
  go to 10

end subroutine decode1

subroutine sleep_msec(n)

#ifdef Win32
  use dflib
#endif

#ifdef Win32
  call sleepqq(n)
#else
  call usleep(1000*n)
#endif

  return
end subroutine sleep_msec

integer function mid_sec()
  integer time

#ifdef Win32
  mid_sec=int(secnds(0.0))
#else
  mid_sec=mod(time(),86400)
#endif

  return
end function mid_sec
