subroutine avecho(id2,ndop,nfrit,nqual,f1,xlevel,sigdb,snr,dfreq,width)

  integer TXLENGTH
  parameter (TXLENGTH=27648)           !27*1024
  parameter (NFFT=32768,NH=NFFT/2)
  integer*2 id2(34560)                 !Buffer for Rx data
  real sa(4096)      !Avg spectrum relative to initial Doppler echo freq
  real sb(4096)      !Avg spectrum with Dither and changing Doppler removed
  integer nsum       !Number of integrations
  real dop0          !Doppler shift for initial integration (Hz)
  real dop           !Doppler shift for current integration (Hz)
  real s(8192)
  real x(NFFT)
  integer ipkv(1)
  complex c(0:NH)
  equivalence (x,c),(ipk,ipkv)
  common/echocom/nclearave,nsum,blue(4096),red(4096)
  save dop0,sa,sb

  dop=ndop
  sq=0.
  do i=1,TXLENGTH
     x(i)=id2(i)
     sq=sq + x(i)*x(i)
  enddo
  xlevel=10.0*log10(sq/TXLENGTH)

  if(nclearave.ne.0) nsum=0
  if(nsum.eq.0) then
     dop0=dop                             !Remember the initial Doppler
     sa=0.                                !Clear the average arrays
     sb=0.
  endif

  x(TXLENGTH+1:)=0.
  x=x/TXLENGTH
  call four2a(x,NFFT,1,-1,0)
  df=12000.0/NFFT
  do i=1,8192                             !Get spectrum 0 - 3 kHz
     s(i)=real(c(i))**2 + aimag(c(i))**2
  enddo

  fnominal=1500.0           !Nominal audio frequency w/o doppler or dither
  ia=nint((fnominal+dop0-nfrit)/df)
  ib=nint((f1+dop-nfrit)/df)
  if(ia.lt.600 .or. ib.lt.600) go to 900
  if(ia.gt.7590 .or. ib.gt.7590) go to 900

  nsum=nsum+1

  do i=1,4096
     sa(i)=sa(i) + s(ia+i-2048)    !Center at initial doppler freq
     sb(i)=sb(i) + s(ib+i-2048)    !Center at expected echo freq
  enddo

  call pctile(sb,200,50,r0)
  call pctile(sb(1800),200,50,r1)

  sum=0.
  sq=0.
  do i=1,4096
     y=r0 + (r1-r0)*(i-100.0)/1800.0
     blue(i)=sa(i)/y
     red(i)=sb(i)/y
     if(i.le.500 .or. i.ge.3597) then
        sum=sum+red(i)
        sq=sq + (red(i)-1.0)**2
     endif
  enddo
  ave=sum/1000.0
  rms=sqrt(sq/1000.0)

  redmax=maxval(red)
  ipkv=maxloc(red)
  fac=10.0/max(redmax,10.0)
  dfreq=(ipk-2048)*df
  snr=(redmax-ave)/rms

  sigdb=-99.0
  if(ave.gt.0.0) sigdb=10.0*log10(redmax/ave - 1.0) - 35.7

  nqual=0
  if(nsum.ge.2 .and. nsum.lt.4)  nqual=(snr-4)/5
  if(nsum.ge.4 .and. nsum.lt.8)  nqual=(snr-3)/4
  if(nsum.ge.8 .and. nsum.lt.12) nqual=(snr-3)/3
  if(nsum.ge.12) nqual=(snr-2.5)/2.5
  if(nqual.lt.0)  nqual=0
  if(nqual.gt.10) nqual=10

! Scale for plotting
  blue=fac*blue
  red=fac*red

  sum=0.
  do i=ipk,ipk+300
     if(red(i).lt.1.0) exit
     sum=sum+(red(i)-1.0)
  enddo
  do i=ipk-1,ipk-300,-1
     if(red(i).lt.1.0) exit
     sum=sum+(red(i)-1.0)
  enddo
  bins=sum/(red(ipk)-1.0)
  width=df*bins
  nsmo=max(0.0,0.25*bins)

  do i=1,nsmo
     call smo121(red,4096)
     call smo121(blue,4096)
  enddo

900  return
end subroutine avecho
