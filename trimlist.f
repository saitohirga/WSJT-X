      subroutine trimlist(sig,kk,indx,nsiz,nz)

      parameter (MAXMSG=1000)             !Size of decoded message list
      real sig(MAXMSG,30)
      integer indx(MAXMSG),nsiz(MAXMSG)
      data ftol/0.02/

C     1      2     3    4    5    6     7     8
C   nfile  nutc  freq  snr  dt  ipol  flip  sync

      call indexx(kk,sig(1,3),indx)            !Sort list by frequency

      n=1
      i0=1
      do i=2,kk         
         j0=indx(i-1)
         j=indx(i)
         if(sig(j,3)-sig(j0,3).gt.ftol) then
            nsiz(n)=i-i0
            i0=i
            n=n+1
         endif
      enddo
      nz=n
      nsiz(nz)=kk+1-i0
      nsiz(nz+1)=-1

      return
      end
