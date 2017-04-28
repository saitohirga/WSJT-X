subroutine msksoftsymw(zz,aa,bb,id,nterms,ierror,rxdata,nhard0,nhardsync0)

  include 'wsprlf_params.f90'

  complex zz(NS+ND)                     !Complex symbol values (intermediate)
  complex z,z0
  real rxdata(ND)                       !Soft symbols
  real aa(20),bb(20)                    !Fitted polyco's
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer ierror(NS+ND)

  n=0
  ierror=0
  ierr=0
  jz=(NS+ND+1)/2
  do j=1,jz
     xx=j*2.0/jz - 1.0
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
!     write(41,3301) j,id(j),ierror(j),ierr,n,p,p*id(j)
!3301 format(5i6,2f10.3)
  enddo

  do j=jz+1,NS+ND
     xx=(j-jz+0.5)*2.0/jz - 1.0
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
     if(n.gt.ND) exit
     rxdata(n)=p
     ierr=0
     if(id(j)*p.lt.0) then
        ierr=1
        ierror(j)=1
     endif
     nhard0=nhard0+ierr
!     write(41,3301) j,id(j),ierror(j),ierr,n,p,p*id(j)
  enddo

  return
end subroutine msksoftsymw
