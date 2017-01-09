subroutine freqcal(id2,k,nkhz,noffset,ntol,line)

  parameter (NZ=30*12000,NFFT=55296,NH=NFFT/2)
  integer*2 id2(0:NZ-1)
  real x(0:NFFT-1)
  real s(NH)
  character line*80,cflag*1
  complex cx(0:NH)
  equivalence (x,cx)
  data n/0/,k0/9999999/
  save n,k0

  if(k.lt.NFFT) go to 900
  if(k.lt.k0) n=0
  k0=k
     
  x=0.001*id2(k-NFFT:k-1)
  call four2a(x,NFFT,1,-1,0)       !Compute spectrum, r2c
  df=12000.0/NFFT
  ia=nint((noffset-ntol)/df)
  ib=nint((noffset+ntol)/df)
  smax=0.
  s=0.
  do i=ia,ib
     s(i)=real(cx(i))**2 + aimag(cx(i))**2
     if(s(i).gt.smax) then
        smax=s(i)
        ipk=i
     endif
  enddo
  
  call peakup(s(ipk-1),s(ipk),s(ipk+1),dx)
  fpeak=df * (ipk+dx)
  sum=0.
  nsum=0
  do i=ia,ib
     if(abs(i-ipk).gt.10) then
        sum=sum+s(i)
        nsum=nsum+1
     endif
  enddo
  ave=sum/nsum
  snr=db(smax/ave)
  pave=db(ave) + 8.0
  cflag=' '
  if(snr.lt.20.0) cflag='*'
  n=n+1
  nsec=mod(time(),86400)
  nhr=nsec/3600
  nmin=mod(nsec/60,60)
  nsec=mod(nsec,60)
  ncal=1
  ferr=fpeak-noffset
  write(line,1100)  nhr,nmin,nsec,nkhz,ncal,noffset,fpeak,ferr,pave,   &
          snr,cflag,char(0)
1100 format(i2.2,':',i2.2,':',i2.2,i7,i3,i6,2f10.3,2f7.1,2x,a1,a1)

900 return
end subroutine freqcal
