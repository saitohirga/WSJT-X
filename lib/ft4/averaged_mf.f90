program averaged_mf

  parameter (nsps=32)
  complex cgfsk(3*nsps,64)
  complex clin(3*nsps,64)
  complex cavg(3*nsps,4)
  complex cavl(3*nsps,4)
  real pulse(3*nsps)
  real dphi(3*nsps)

  do i=1,3*NSPS
     t=(i-1.5*nsps)/real(nsps)
     pulse(i)=gfsk_pulse(1.0,t)
  enddo

  twopi=8.0*atan(1.0)
  hmod=1.0
  dphi_peak=twopi*hmod/real(nsps)

  do iwf=1,64
    i0=mod((iwf-1)/16,4)
    i1=mod((iwf-1)/4,4)
    i2=mod(iwf-1,4)
    dphi=0.0
    dphi(1:64)=dphi_peak*pulse(33:96)*i1
    dphi(1:96)=dphi(1:96)+dphi_peak*pulse(1:96)*i0
    dphi(33:96)=dphi(33:96)+dphi_peak*pulse(1:64)*i2
    phi=0.0
    do j=1,96
      cgfsk(j,iwf)=cmplx(cos(phi),sin(phi))
      phi=mod(phi+dphi(j),twopi)
    enddo
    cgfsk(:,iwf)=cgfsk(:,iwf)*conjg(cgfsk(48,iwf))
  enddo

  do iwf=1,64
    i0=mod((iwf-1)/16,4)
    i1=mod((iwf-1)/4,4)
    i2=mod(iwf-1,4)
    dphi=0.0
    dphi(1:32)=dphi_peak*i1
    dphi(33:64)=dphi_peak*i0
    dphi(65:96)=dphi_peak*i2
    phi=0.0
    do j=1,96
      clin(j,iwf)=cmplx(cos(phi),sin(phi))
      phi=mod(phi+dphi(j),twopi)
    enddo
  enddo


  do i=1,4
    ib=(i-1)*16+1
    ie=ib+15
    cavg(:,i)=sum(cgfsk(:,ib:ie),2)/16.0
    cavl(:,i)=sum(clin(:,ib:ie),2)/16.0
    do j=1,96
write(*,*) j
write(21,*) i,j,real(cavg(j,i)),imag(cavg(j,i)),real(cavl(j,i)),imag(cavl(j,i))
    enddo
  enddo

end program averaged_mf

