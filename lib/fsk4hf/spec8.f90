subroutine spec8(c,s,savg)

  include 'wspr_fsk8_params.f90'
  complex c(0:NMAXD-1)
  complex c1(0:NSPS-1)
  real s(0:NH2,NN)
  real savg(0:NH2)

  fs=12000.0/NDOWN
  df=fs/NSPS
  savg=0.
  do j=1,NN
     ia=(j-1)*NSPS
     ib=ia + NSPS-1
     c1(0:NSPS-1)=c(ia:ib)
     c1(NSPS:)=0.
     call four2a(c1,NSPS,1,-1,1)
     do i=0,NH2
        s(i,j)=real(c1(i))**2 + aimag(c1(i))**2
     enddo
     savg=savg+s(0:NH2,j)
  enddo
  s=s/NZ
  savg=savg/(NN*NZ)
!  do i=0,NH2
!     write(31,3101) i*df,savg(i)
!3101 format(f10.3,f12.3)
!  enddo

  return
end subroutine spec8
