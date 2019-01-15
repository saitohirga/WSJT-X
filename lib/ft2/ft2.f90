program ft2

  use packjt77
  include 'gcom1.f90'
  integer ft2audio,ptt
  logical allok
  character*20 pttport
  character*8 arg
!  integer*2 iwave2(30000)

  allok=.true.
! Get home-station details
  open(10,file='ft2.ini',status='old',err=1)
  go to 2
1 print*,'Cannot open ft2.ini'
  allok=.false.
2 read(10,*,err=3) mycall,mygrid,ndevin,ndevout,pttport,exch
  go to 4
3 print*,'Error reading ft2.ini'
  allok=.false.
4 if(index(pttport,'/').lt.1) read(pttport,*) nport
  hiscall='      '
  hiscall_next='      '
  idevin=ndevin
  idevout=ndevout
  call padevsub(idevin,idevout)
  if(idevin.ne.ndevin .or. idevout.ne.ndevout) allok=.false.
  i1=ptt(nport,1,1,iptt)
  if(i1.lt.0 .and. nport.ne.0) allok=.false.
  if(.not.allok) then
     write(*,"('Please fix setup error(s) and restart.')")
     go to 999
  endif

  nright=1
  iwrite=0
  iwave=0
  nwave=NTZ
  nfsample=12000
  ngo=1
  npabuf=1152
  ntxok=0
  ntransmitting=0
  tx_once=.false.
  snrdb=99.0
  txmsg='CQ K1JT FN20'

  nargs=iargc()
  if(nargs.eq.3) then
     call getarg(1,txmsg)
     call getarg(2,arg)
     read(arg,*) f0
     call getarg(3,arg)
     read(arg,*) snrdb
     tx_once=.true.
     call ft2_iwave(txmsg,f0,snrdb,iwave)
     nTxOK=1
  endif
  
! Start the audio streams  
  ierr=ft2audio(idevin,idevout,npabuf,nright,y1,y2,NRING,iwrite,itx,     &
       iwave,nwave,nfsample,nTxOK,nTransmitting,ngo)
  if(ierr.ne.0) then
     print*,'Error',ierr,' starting audio input and/or output.'
  endif

999 end program ft2

subroutine update(total_time,ic1,ic2)

  real*8 total_time
  integer*8 count00,count0,count1,clkfreq
  integer ptt
  integer*2 id(30000)
  logical transmitted
  character*30 line
  character cdate*8,ctime*10,cdatetime*17
  include 'gcom1.f90'
  data nt0/-1/,transmitted/.false./,snr/-99.0/,count00/-1/
  save nt0,transmitted,snr,count00

  if(ic1.ne.0 .or. ic2.ne.0) then
     if(ic1.eq.27 .and. ic2.eq.0) ngo=0  !ESC
     if(nTxOK.eq.0 .and. ntransmitting.eq.0) then
        nd=0
        if(ic1.eq.0 .and. ic2.eq.59) nd=1   !F1
        if(ic1.eq.0 .and. ic2.eq.60) nd=2   !F2
        if(ic1.eq.0 .and. ic2.eq.61) nd=3   !F3
        if(ic1.eq.0 .and. ic2.eq.62) nd=4   !F4
        if(ic1.eq.0 .and. ic2.eq.63) nd=5   !F5
        if(nd.gt.0) then
           i1=ptt(nport,1,1,iptt)
           ntxok=1
           if(nd.eq.1) txmsg='CQ K1JT FN20'
           if(nd.eq.2) txmsg='K9AN K1JT 559 NJ'
           call ft2_iwave(txmsg,1500.0,99.0,iwave)
        endif
     endif
     if(ic1.eq.13 .and. ic2.eq.0) hiscall=hiscall_next
  endif

  if(ntransmitting.eq.1) transmitted=.true.
  if(ntransmitting.eq.0) then
     if(iptt.eq.1 .and. nport.gt.0) i1=ptt(nport,0,1,iptt)
     if(tx_once .and. transmitted) stop
  endif

  nt=2*total_time
  if(nt.gt.nt0 .or. ic1.ne.0 .or. ic2.ne.0) then
     k=iwrite-6000
     if(k.lt.1) k=k+NRING
     sq=0.
     do i=1,6000
        k=k+1
        if(k.gt.NRING) k=k-NRING
        x=y1(k)
        sq=sq + x*x
     enddo
     sigdb=0.
     if(sq.gt.0.0) sigdb=db(sq/6000.0)
     k=iwrite-30000
     if(k.lt.1) k=k+NRING
     do i=1,30000
        k=k+1
        if(k.gt.NRING) k=k-NRING
        id(i)=y1(k)
     enddo
     nutc=0
     nfqso=1500
     ndecodes=0
     if(maxval(abs(id)).gt.0) then
        call date_and_time(cdate,ctime)
        cdatetime=cdate(3:8)//'_'//ctime
        call system_clock(count0,clkfreq)
        call ft2_decode(cdatetime,nfqso,id,ndecodes)
        call system_clock(count1,clkfreq)
        tdecode=float(count1-count0)/float(clkfreq)
        if(count00.lt.0) count00=count0
        trun=float(count1-count00)/float(clkfreq)
     endif
     n=2*sigdb-30.0
     if(n.lt.1) n=1
     if(n.gt.30) n=30
     line=' '
     line(n:n)='*'
!     write(*,1010) nt,total_time,iwrite,itx,ntxok,ntransmitting,ndecodes,  &
!          snr,sigdb,line
!1010 format(i6,f9.3,i10,i6,3i3,f6.0,f6.1,1x,a30)
     nt0=nt
     max1=0
     max2=0
  endif

  return
end subroutine update
