subroutine cpolyfit(c,pp,id,maxn,aa,bb,zz,nhardsync)

  parameter (KK=84)                     !Information bits (72 + CRC12)
  parameter (ND=168)                    !Data symbols: LDPC (168,84), r=1/2
  parameter (NS=65)                     !Sync symbols (2 x 26 + Barker 13)
  parameter (NR=3)                      !Ramp up/down
  parameter (NN=NR+NS+ND)               !Total symbols (236)
  parameter (NSPS=16)                   !Samples per MSK symbol (16)
  parameter (N2=2*NSPS)                 !Samples per OQPSK symbol (32)
  parameter (N13=13*N2)                 !Samples in central sync vector (416)
  parameter (NZ=NSPS*NN)                !Samples in baseband waveform (3760)
  parameter (NFFT1=4*NSPS,NH1=NFFT1/2)

  complex c(0:NZ-1)                     !Complex waveform
  complex zz(NS+ND)                     !Complex symbol values (intermediate)
  complex z,z0
  real x(NS),yi(NS),yq(NS)              !For complex polyfit
  real pp(2*NSPS)                       !Shaped pulse for OQPSK
  real aa(20),bb(20)                    !Fitted polyco's
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data

  ib=NSPS-1
  ib2=N2-1
  n=0
  do j=1,117                                !First-pass demodulation
     ia=ib+1
     ib=ia+N2-1
     zz(j)=sum(pp*c(ia:ib))/NSPS
     if(abs(id(j)).eq.2) then               !Save all sync symbols
        n=n+1
        x(n)=float(ia+ib)/NZ - 1.0
        yi(n)=real(zz(j))*0.5*id(j)
        yq(n)=aimag(zz(j))*0.5*id(j)
!        write(54,1225) n,x(n),yi(n),yq(n)
!1225    format(i5,3f12.4)
     endif
     if(j.le.116) then
        zz(j+117)=sum(pp*c(ia+NSPS:ib+NSPS))/NSPS
     endif
  enddo
  
  aa=0.
  bb=0.
  nterms=0
  chisqa=0.
  chisqb=0.
  if(maxn.gt.0) then
     npts=n
     mode=0
     nterms=maxn
     call polyfit4(x,yi,yi,npts,nterms,mode,aa,chisqa)
     call polyfit4(x,yq,yq,npts,nterms,mode,bb,chisqb)
  endif
  
  nhardsync=0
  do j=1,117
     if(abs(id(j)).ne.2) cycle
     xx=j*2.0/117.0 - 1.0
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
     if(p*id(j).lt.0) nhardsync=nhardsync+1
  enddo
  
  return
end subroutine cpolyfit
