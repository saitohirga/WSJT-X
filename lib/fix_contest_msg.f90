subroutine fix_contest_msg(mycall,mygrid,hiscall,msg)

! If msg is "mycall hiscall grid1" and distance from mygrid to grid1 is more
! thsn 10000 km, change "grid1" to "R grid2" where grid2 is the antipodes
! of grid1.

  character*6 mycall,mygrid,hiscall
  character*22 msg,t
  character*6 g1,g2
  logical isgrid

  t=trim(mycall)//' '//trim(hiscall)
  i0=index(msg,trim(t))
  if(i0.eq.1) then
     i1=len(trim(t))+2
     g1=msg(i1:i1+3)
     if(isgrid(g1)) then
        call azdist(mygrid,g1,0.d0,nAz,nEl,nDmiles,nDkm,nHotAz,nHotABetter)
        if(ndkm.gt.10000) then
           call grid2deg(g1,dlong,dlat)
           dlong=dlong+180.0
           if(dlong.gt.180.0) dlong=dlong-360.0
           dlat=-dlat
           call deg2grid(dlong,dlat,g2)
           msg=msg(1:i1-1)//'R '//g2(1:4)
        endif
     endif
  endif

  return
end subroutine fix_contest_msg
