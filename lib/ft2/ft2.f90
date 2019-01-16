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
  i1=0
  i1=ptt(nport,1,0,iptt)
  if(i1.lt.0 .and. nport.ne.0) allok=.false.
  if(.not.allok) then
     write(*,"('Please fix setup error(s) and restart.')")
     go to 999
  endif
  open(12,file='all_ft2.txt',status='unknown',position='append')

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
  ltx=.false.
  lrx=.false.
  autoseq=.false.
  QSO_in_progress=.false.
  ntxed=0

  nargs=iargc()
  if(nargs.eq.3) then
     call getarg(1,txmsg)
     call getarg(2,arg)
     read(arg,*) f0
     call getarg(3,arg)
     read(arg,*) snrdb
     tx_once=.true.
     ftx=1500.0
     call transmit(-1,ftx,iptt)
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
  integer*8 count0,count1,clkfreq
  integer ptt
  integer*2 id(30000)
  logical transmitted,level
  character*70 line
  character cdatetime*17
  include 'gcom1.f90'
  data nt0/-1/,transmitted/.false./,snr/-99.0/
  data level/.false./
  save nt0,transmitted,level,snr,iptt

  if(ic1.ne.0 .or. ic2.ne.0) then
     if(ic1.eq.27 .and. ic2.eq.0) ngo=0        !ESC
     if(nTxOK.eq.0 .and. ntransmitting.eq.0) then
        nfunc=0
        if(ic1.eq.0 .and. ic2.eq.59) nfunc=1   !F1
        if(ic1.eq.0 .and. ic2.eq.60) nfunc=2   !F2
        if(ic1.eq.0 .and. ic2.eq.61) nfunc=3   !F3
        if(ic1.eq.0 .and. ic2.eq.62) nfunc=4   !F4
        if(ic1.eq.0 .and. ic2.eq.63) nfunc=5   !F5
        if(nfunc.eq.1 .or. (nfunc.ge.2 .and. hiscall.ne.'      ')) then
           ftx=1500.0
           call transmit(nfunc,ftx,iptt)
        endif
     endif
     if(ic1.eq.13 .and. ic2.eq.0) hiscall=hiscall_next
     if((ic1.eq.97 .or. ic1.eq.65) .and. ic2.eq.0) autoseq=.not.autoseq
     if((ic1.eq.108 .or. ic1.eq.76) .and. ic2.eq.0) level=.not.level
  endif

  if(ntransmitting.eq.1) transmitted=.true.
  if(transmitted .and. ntransmitting.eq.0) then
     i1=0
     if(iptt.eq.1 .and. nport.gt.0) i1=ptt(nport,0,1,iptt)
     if(tx_once .and. transmitted) stop
     transmitted=.false.
  endif

  nt=2*total_time
  if(nt.gt.nt0 .or. ic1.ne.0 .or. ic2.ne.0) then
     if(level) then
! Measure and display the average level of signal plus noise in past 0.5 s
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
        n=sigdb
        if(n.lt.1) n=1
        if(n.gt.70) n=70
        line=' '
        line(n:n)='*'
        write(*,1030) sigdb,ntxed,autoseq,QSO_in_progress,(line(i:i),i=1,n)
1030    format(f4.1,i3,2L2,1x,70a1)
!        write(*,1020) nt,total_time,iwrite,itx,ntxok,ntransmitting,ndecodes,  &
!             snr,sigdb,line
!1020    format(i6,f9.3,i10,i6,3i3,f6.0,f6.1,1x,a30)
     endif
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
        call system_clock(count0,clkfreq)
        nrx=-1
        call ft2_decode(cdatetime(),nfqso,id,ndecodes,mycall,hiscall,nrx)
        call system_clock(count1,clkfreq)
!        tdecode=float(count1-count0)/float(clkfreq)
!        write(*,3001) trun
!3001    format(f10.3)

        if(autoseq .and.nrx.eq.2) QSO_in_progress=.true.
        if(autoseq .and. QSO_in_progress .and. nrx.ge.1 .and. nrx.le.4) then
           lrx(nrx)=.true.
           ftx=1500.0
           if(ntxed.eq.1) then
              if(nrx.eq.2) then
                 call transmit(3,ftx,iptt)
              else
                 call transmit(1,ftx,iptt)
              endif
           endif
           if(ntxed.eq.2) then
              if(nrx.eq.3) then
                 call transmit(4,ftx,iptt)
                 QSO_in_progress=.false.
                 write(*,1032)
1032             format('QSO complete: S+P side')
              else
                 call transmit(2,ftx,iptt)
              endif
           endif
           if(ntxed.eq.3) then
              if(nrx.eq.4) then
                 QSO_in_progress=.false.
                 write(*,1034)
1034             format('QSO complete: CQ side')
              else
                 call transmit(3,ftx,iptt)
              endif
           endif
        endif
     endif
     nt0=nt
  endif

  return
end subroutine update

character*17 function cdatetime()
  character cdate*8,ctime*10
  call date_and_time(cdate,ctime)
  cdatetime=cdate(3:8)//'_'//ctime
  return
end function cdatetime

subroutine transmit(nfunc,ftx,iptt)
  include 'gcom1.f90'
  character*17 cdatetime
  integer ptt

  if(nTxOK.eq.1) return
  
  if(nfunc.eq.1) txmsg='CQ '//trim(mycall)//' '//mygrid
  if(nfunc.eq.2) txmsg=trim(hiscall)//' '//trim(mycall)//     &
       ' 559 '//trim(exch)
  if(nfunc.eq.3) txmsg=trim(hiscall)//' '//trim(mycall)//     &
       ' R 559 '//trim(exch)
  if(nfunc.eq.4) txmsg=trim(hiscall)//' '//trim(mycall)//' RR73'
  if(nfunc.eq.5) txmsg='TNX 73 GL'
  call ft2_iwave(txmsg,ftx,99.0,iwave)
  i1=ptt(nport,1,1,iptt)
  ntxok=1
  n=len(trim(txmsg))
  write(*,1010) cdatetime(),0,0.0,nint(ftx),(txmsg(i:i),i=1,n)
  write(12,1010) cdatetime(),0,0.0,nint(ftx),(txmsg(i:i),i=1,n)
1010 format(a17,i4,f6.2,i5,' Tx ',37a1)
  if(nfunc.ge.1 .and. nfunc.le.4) ntxed=nfunc
  if(nfunc.ge.1 .and. nfunc.le.5) ltx(nfunc)=.true.
  if(nfunc.eq.2 .or. nfunc.eq.3) QSO_in_progress=.true.

  return
end subroutine transmit
