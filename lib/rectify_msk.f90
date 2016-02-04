subroutine rectify_msk(c,msg0,imsg,freq2)

  parameter (NSPM=1404)
  complex c(0:NSPM-1)                         !Received data
  complex cmsg(0:NSPM-1)                      !Message waveform
  complex c1(0:NSPM-1)                        !Rectified signal
  complex c2(0:NSPM-1)                        !Integral of rectified signal
  complex c3(0:2*NSPM-1)                      !FFT of rectified signal
  complex cfac
  character*22 msg0,msg,msgsent
  integer i4tone(234)

  ichk=0
  msg=msg0
  nsym=234
  if(imsg.ge.0) then
     ichk=10000+imsg
     msg="<C1ALL C2ALL> 73"
     nsym=35
  endif
  call genmsk(msg,ichk,msgsent,i4tone,itype)  !Get tone sequence for msg

  twopi=8.0*atan(1.0)
  dt=1.0/12000.0
  f0=1000.0
  f1=2000.0
  phi=0.
  dphi=0.
  k=-1
  c2=0.
  do j=1,nsym                                  !Generate Tx waveform for msg
     if(i4tone(j).eq.0) dphi=twopi*f0*dt
     if(i4tone(j).eq.1) dphi=twopi*f1*dt
     do i=1,6
        k=k+1
        phi=phi+dphi
        cmsg(k)=cmplx(cos(phi),sin(phi))
        c1(k)=conjg(cmsg(k))*c(k)
        if(k.ge.1) c2(k)=c2(k-1) + c1(k)
     enddo
  enddo
  c2(0)=c2(1)
  pha=atan2(aimag(c2(NSPM-1)),real(c2(NSPM-1)))
  cfac=cmplx(cos(pha),-sin(pha))
  c1=cfac*c1
  c2=cfac*c2
  nfft=2*NSPM
  c3(0:NSPM-1)=c2
  c3(NSPM:nfft-1)=0.
  df=12000.0/nfft
  call four2a(c3,nfft,1,-1,1)
  smax=0.
  do i=0,nfft-1
     f=i*df
     if(i.gt.nfft/2) f=f-12000.0
     s=1.e-10*(real(c3(i))**2 + aimag(c3(i))**2)
     if(s.gt.smax) then
        smax=s
        freq2=1500.0 + f
     endif
  enddo

  return
end subroutine rectify_msk
