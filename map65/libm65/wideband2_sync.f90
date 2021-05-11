module wideband2_sync

  parameter (NFFT=32768)
  integer isync(22)
  integer nkhz_center
  real sync_dat(NFFT,6)     !fkhz, ccfmax, xdt, ipol, flip
  real savg_med(4)

  contains

subroutine wb2_sync(ss,savg,nfa,nfb)

! Compute "orange sync curve" using the Q65 sync pattern

  parameter (LAGMAX=30)
  real ss(4,322,NFFT)
  real savg(4,NFFT)
  logical first
  integer isync0(22)
  integer jsync0(63)
! Q65 sync symbols
  data isync0/1,9,12,13,15,22,23,26,27,33,35,38,46,50,55,60,62,66,69,74,76,85/
  data jsync0/                                                         &
       1,  4,  5,  9, 10, 11, 12, 13, 14, 16, 18, 22, 24, 25, 28, 32,  &
       33, 34, 37, 38, 39, 40, 42, 43, 45, 46, 47, 48, 52, 53, 55, 57, &
       59, 60, 63, 64, 66, 68, 70, 73, 80, 81, 89, 90, 92, 95, 97, 98, &
       100,102,104,107,108,111,114,119,120,121,122,123,124,125,126/
  data first/.true./
  save first

  do j=322,1,-1
     if(sum(ss(1,j,1:NFFT)).gt.0.0) exit
  enddo
  jz=j


  tstep=2048.0/11025.0        !0.185760 s: 0.5*tsym_jt65, 0.3096*tsym_q65
  if(first) then
     fac=0.6/tstep
     do i=1,22                                !Expand the Q65 sync stride
        isync(i)=nint((isync0(i)-1)*fac) + 1
     enddo
     do i=1,63
        jsync0(i)=2*(jsync0(i)-1) + 1
     enddo
     first=.false.
  endif

  df3=96000.0/NFFT
  ia=nint(1000*nfa/df3)          !Flat frequency range for WSE converters
  ib=nint(1000*nfb/df3)

  do i=1,4
     call pctile(savg(i,ia:ib),ib-ia+1,50,savg_med(i))
  enddo
  do i=ia,ib
     write(14,3014) 0.001*i*df3,savg(1:4,i)
3014 format(5f10.3)
  enddo

  lagbest=0
  ipolbest=1
  flip=0.

  do i=ia,ib
     ccfmax=0.
     do ipol=1,4
        do lag=0,LAGMAX

           ccf=0.
           do j=1,22
              k=isync(j) + lag
              ccf=ccf + ss(ipol,k,i+1) + ss(ipol,k+1,i+1) + ss(ipol,k+2,i+1) 
           enddo
           ccf=ccf - savg(ipol,i+1)*3*22/float(jz)
           if(ccf.gt.ccfmax) then
              ipolbest=ipol
              lagbest=lag
              ccfmax=ccf
              flip=0.
           endif

           ccf=0.
           do j=1,63
              k=jsync0(j) + lag
              ccf=ccf + ss(ipol,k,i+1) + ss(ipol,k+1,i+1)
           enddo
           ccf=ccf - savg(ipol,i+1)*2*63/float(jz)
           if(ccf.gt.ccfmax) then
              ipolbest=ipol
              lagbest=lag
              ccfmax=ccf
              flip=1.0
           endif

        enddo  ! lag
     enddo  !ipol

     fkhz=0.001*i*df3 + nkhz_center - 48.0
     xdt=lagbest*tstep-1.0
     sync_dat(i,1)=fkhz
     sync_dat(i,2)=ccfmax
     sync_dat(i,3)=xdt
     sync_dat(i,4)=ipolbest
     sync_dat(i,5)=flip
     sync_dat(i,6)=ccfmax/(savg(ipolbest,i)/savg_med(ipolbest))
  enddo

  call pctile(sync_dat(ia:ib,2),ib-ia+1,50,base)
  sync_dat(ia:ib,2)=sync_dat(ia:ib,2)/base

  return
end subroutine wb2_sync

end module wideband2_sync
