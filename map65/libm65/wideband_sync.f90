module wideband_sync

  parameter (NFFT=32768)
  integer isync(22)
  integer nkhz_center
  real sync_dat(NFFT,4)     !fkhz, ccfmax, xdt, ipol

  contains
  
subroutine wb_sync(ss,savg,ntone_spacing)

! Compute "orange sync curve" using the Q65 sync pattern

  parameter (LAGMAX=30)
  real ss(4,322,NFFT)
  real savg(4,NFFT)
  logical first
  character*1 c1
!  integer hist(0:20)
  integer isync0(22)
! Q65 sync symbols
  data isync0/1,9,12,13,15,22,23,26,27,33,35,38,46,50,55,60,62,66,69,74,76,85/
  data first/.true./
  save first

  tstep=2048.0/11025.0
  if(first) then
     fac=0.6/tstep
     do i=1,22                                !Expand the sync stride
        isync(i)=nint((isync0(i)-1)*fac) + 1
     enddo
     first=.false.
  endif

  df=96000.0/NFFT
  ia=nint(7000.0/df)          !Flat frequency range for WSE converters
  ib=nint(89000.0/df)
  lagbest=-1
  ipolbest=-1

  do i=ia,ib
     ccfmax=0.
     do ipol=1,4
        do lag=0,LAGMAX
           ccf=0.
           do j=1,22
              k=isync(j) + lag
              ccf=ccf + ss(ipol,k,i+1) 
           enddo
           ccf=ccf - savg(ipol,i+1)*22.0/322.0
           if(ccf.gt.ccfmax) then
              ipolbest=ipol
              lagbest=lag
              ccfmax=ccf
           endif
        enddo  ! lag
     enddo  !ipol

     fkhz=0.001*i*df + nkhz_center - 48.0
     xdt=lagbest*tstep-1.0
     sync_dat(i,1)=fkhz
     sync_dat(i,2)=ccfmax
     sync_dat(i,3)=xdt
     sync_dat(i,4)=ipolbest
  enddo

  call pctile(sync_dat(ia:ib,2),ib-ia+1,50,base)
  sync_dat(ia:ib,2)=sync_dat(ia:ib,2)/base
!  hist=0
!  s2_avg=63.5*ntone_spacing
!  do i=ia,ib
!     f0=0.001*i*df
!     write(70,3010) f0,sync_dat(i,2:3),nint(sync_dat(i,4)),   &
!          0.001*i*df,nkhz_center
!3010 format(3f10.3,i5,f10.3,i5)
!     x=min(sync_dat(i,2),20.0)
!     nx=x
!     hist(nx)=hist(nx)+1
!     if(x.gt.2.5) then
!        c1=' '
!        s0=sync_dat(i,2) - 1.0
!        s1=(sync_dat(i-1,2) + sync_dat(i+1,2) - 2.0)/s0
!        s2=(sum(sync_dat(i+ntone_spacing/2+1:i+64*ntone_spacing,2)) - s2_avg)/s0
!        if(s2.ge.0.5) c1='*'
!        write(72,3072) f0,s0,s1,s2,c1
!3072    format(f12.6,3f10.3,2x,a1)
!     endif
!  enddo

!  do i=0,20
!     write(71,3071) i,hist(i)
!3071 format(i2,i8)
!  enddo

  return
end subroutine wb_sync

end module wideband_sync
