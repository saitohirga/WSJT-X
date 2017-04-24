subroutine msksoftsymw(zz,aa,bb,id,nterms,ierror,rxdata,nhard0,nhardsync0)

  parameter (KK=60)                     !Information bits (50 + CRC10)
  parameter (ND=300)                    !Data symbols: LDPC (300,60), r=1/5
  parameter (NS=109)                    !Sync symbols (2 x 48 + Barker 13)
  parameter (NR=3)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (412)
  parameter (NSPS=16)                   !Samples per MSK symbol (16)
  parameter (N2=2*NSPS)                 !Samples per OQPSK symbol (32)
  parameter (N13=13*N2)                 !Samples in central sync vector (416)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (6592)
  parameter (NFFT1=4*NSPS,NH1=NFFT1/2)

  complex zz(NS+ND)                     !Complex symbol values (intermediate)
  complex z,z0
  real rxdata(ND)                       !Soft symbols
  real aa(20),bb(20)                    !Fitted polyco's
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer ierror(NS+ND)

  n=0
  ierror=0
  ierr=0
  do j=1,205
     xx=j*2.0/205.0 - 1.0
     yii=1.
     yqq=0.
     if(nterms.gt.0) then
        yii=aa(1)
        yqq=bb(1)
        do i=2,nterms
           yii=yii + aa(i)*xx**(i-1)
           yqq=yqq + bb(i)*xx**(i-1)
        enddo
     endif
     z0=cmplx(yii,yqq)
     z=zz(j)*conjg(z0)
     p=real(z)
     if(abs(id(j)).eq.2) then
        if(real(z)*id(j).lt.0) then              !Sync bit
           nhardsync0=nhardsync0+1
           ierror(j)=2
        endif
     else
        n=n+1                                    !Data bit
        rxdata(n)=p
        ierr=0
        if(id(j)*p.lt.0) then
           ierr=1
           ierror(j)=1
        endif
        nhard0=nhard0+ierr
     endif
!     write(41,3301) j,id(j),ierror(j),ierr,p*id(j)
!3301 format(4i6,f10.3)
  enddo

  do j=206,409
     xx=(j-204.5)*2.0/205.0 - 1.0
     yii=1.
     yqq=0.
     if(nterms.gt.0) then
        yii=aa(1)
        yqq=bb(1)
        do i=2,nterms
           yii=yii + aa(i)*xx**(i-1)
           yqq=yqq + bb(i)*xx**(i-1)
        enddo
     endif
     z0=cmplx(yii,yqq)
     z=zz(j)*conjg(z0)
     p=aimag(z)
     n=n+1
     rxdata(n)=p
     ierr=0
     if(id(j)*p.lt.0) then
        ierr=1
        ierror(j)=1
     endif
     nhard0=nhard0+ierr
!     write(41,3301) j,id(j),ierror(j),ierr,p*id(j)
  enddo

  return
end subroutine msksoftsymw
