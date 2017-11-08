module dxped_fox
  
  parameter (MAXSIG=5,NSEQ=10,NCALLS=268)
  
  character*6 cx(MAXSIG),xcall(NCALLS)
  character*4 gx(MAXSIG),xgrid(NCALLS)
  character*6 called(MAXSIG)
  character*6 acknowledged(MAXSIG)
  character*6 MyCall
  character*4 MyGrid
  integer nsig
  integer isent(MAXSIG)
  integer istate(2,MAXSIG)
  integer isnr(NCALLS)
  integer irpt(MAXSIG)
  integer nlogged
  integer nrx
  integer nc

  ! istate
  !  0 = Start QSO: call X (from FIFO) or CQ if FIFO is empty
  !  1 = Sent report to X
  !  2 = Received R+rpt from X
  !  3 = Sent RR73 to X
  !  4 = Logged -> Idle
  
contains
  
  subroutine fox_tx(iseq)
    character*32 txmsg(MAXSIG)
    character*6 cy
    character*4 gy
    character*16 log
    save txmsg

    if(iseq.eq.0) nrx=nsig
    
    do j=1,nsig
       log='                '
       js=istate(1,j)
       if(js.eq.0) then
          if(iseq.eq.0) then
             txmsg(j)='CQ KH1DX AJ10'
          else
!             read(10,1002,end=1,err=999) cx(j),gx(j)         !Grab next call from FIFO
!1002         format(a6,7x,a4)
             nc=nc+1
             if(nc.gt.NCALLS) go to 1
             cx(j)=xcall(nc)
             gx(j)=xgrid(NC)
!             call random_number(x)
!             irpt=-20+int(40*x)
             irpt(j)=isnr(nc)
             write(txmsg(j),1004) cx(j),mycall,irpt(j)
1004         format(a6,1x,a6,i4.2)
             if(txmsg(j)(15:15).eq.' ') txmsg(j)(15:15)='+'
             istate(1,j)=1
             go to 2
1            txmsg(j)='CQ '//MyCall//' '//MyGrid//'                  '
2            continue
          endif
       endif

       if(js.eq.2) then
!          read(10,1002,end=3,err=999) cy,gy              !Grab next call from FIFO
          nc=nc+1
          if(nc.gt.NCALLS) go to 3
          cy=xcall(nc)
          gy=xgrid(nc)
!          call random_number(x)
!          irpt=-20+int(40*x)
          irpt(j)=isnr(nc)
          
          isent(j)=irpt(j)
          write(txmsg(j),1006) cx(j),cy,irpt(j)
1006      format(a6,' RR73; ',a6,1x,'<KH1DX>',i4.2)
          if(txmsg(j)(29:29).eq.' ') txmsg(j)(29:29)='+'
          write(log,1008) cx(j),gx(j),isent(j)
1008      format(a6,2x,a4,i4.2)
          if(log(14:14).eq.' ') log(14:14)='+'
          cx(j)=cy
          gx(j)=gy
          called(j)=cy
          isent(j)=irpt(j)
          istate(2,j)=1
          go to 4
3         write(txmsg(j),1006) cx(j),'DE    '
          istate(2,j)=0
4         istate(1,j)=3
       endif

!       if(j.gt.nrx) print*,'a',nrx,j
! Encode txmsg, generate waveform, and transmit
       if(log(1:1).ne.' ') then
          nlogged=nlogged+1
          nrate=0
          if(iseq.gt.0) nrate=nint(nlogged*240.0/iseq)
          write(*,1010) iseq,j,istate(1:2,j),txmsg(j),log,nlogged,nrate
1010      format(i4.4,i3,2i2,1x,a32,20x,a16,2i4)
       else
!          irpt=-20+int(40*x)
          if(iseq.ge.2) write(txmsg(j),1004) cx(j),mycall,irpt(j)
          write(*,1010) iseq,j,istate(1:2,j),txmsg(j)
       endif
    enddo
    
    return
!999 stop '*** ERROR ***'
  end subroutine fox_tx

  subroutine fox_rx(iseq,rxmsg)
    character*22 rxmsg
    data iseq0/-1/
    save iseq0,k

    if(rxmsg(1:6).ne.MyCall) go to 900
    if(iseq.lt.0) called='      '

    nrx=nrx+1
    if(iseq.ne.iseq0) k=0
    iseq0=iseq
    if(index(rxmsg,'R+').ge.8 .or. index(rxmsg,'R-').ge.8) then
       j0=0
       do j=1,nsig
          if(rxmsg(8:13).eq.called(j)) j0=j
       enddo
       if(j0.ge.1) then
          write(*,1000) iseq,j0,istate(1:2,j0),j0,rxmsg
1000      format(i4.4,i3,2i2,32x,i1,1x,a22)
          istate(1,j0)=2
       endif
       go to 900
    endif

    if(k.le.nsig-1) then
       k=k+1
       called(k)=rxmsg(8:13)
       write(*,1000) iseq,k,istate(1:2,k),j0,rxmsg
    endif
!    print*,'b',iseq,j0,k

900 return
  end subroutine fox_rx
  
  
end module dxped_fox
!AA7UN  KH1DX  +19
!KH1DX  AA7UN  R+18
!AA7UN  RR73; EA5YI  <KH1DX>  16
!0004  AA7UN   DN32  09
!0050  5 3 1 KA6A   RR73; KB2M   <KH1DX> -08                     KA6A    EM13 -08  86 413
