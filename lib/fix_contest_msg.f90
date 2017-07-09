subroutine fix_contest_msg(mycall,mygrid,hiscall,msg)

! If msg is "mycall hiscall grid1" and distance from mygrid to grid1 is more
! thsn 10000 km, change "grid1" to "R grid2" where grid2 is the antipodes
! of grid1.

  character*6 mycall,mygrid,hiscall
  character*22 msg
  character*6 g1,g2
  logical isgrid

  n=len(trim(msg))
  if(n.lt.4) return
  g1=msg(n-3:n)//'  '
  if(isgrid(g1)) then
     call azdist(mygrid,g1,0.d0,nAz,nEl,nDmiles,nDkm,nHotAz,nHotABetter)
     if(ndkm.gt.10000) then
        call grid2deg(g1,dlong,dlat)
        dlong=dlong+180.0
        if(dlong.gt.180.0) dlong=dlong-360.0
        dlat=-dlat
        call deg2grid(dlong,dlat,g2)
        msg=msg(1:n-4)//'R '//g2(1:4)
     endif
  endif

  return
end subroutine fix_contest_msg
