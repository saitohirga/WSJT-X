subroutine avecho(id2,ndop,nfrit,nqual,f1,rms0,sigdb,snr,dfreq,width)

  integer TXLENGTH
  parameter (TXLENGTH=27648)           !27*1024
  parameter (NFFT=32768,NH=NFFT/2)
  integer*2 id2(34560)                 !Buffer for Rx data
  real sa(2000)      !Avg spectrum relative to initial Doppler echo freq
  real sb(2000)      !Avg spectrum with Dither and changing Doppler removed
  integer nsum       !Number of integrations
  real dop0          !Doppler shift for initial integration (Hz)
  real doppler       !Doppler shift for current integration (Hz)
  real s(8192)
  real x(NFFT)
  integer ipkv(1)
  complex c(0:NH)
  equivalence (x,c),(ipk,ipkv)
  common/echocom/nclearave,nsum,blue(2000),red(2000)
  save dop0,sa,sb

  dop=ndop
  doppler=dop
  sq=0.
  do i=1,TXLENGTH
     x(i)=id2(i)
     sq=sq + x(i)*x(i)
  enddo
  rms0=sqrt(sq/TXLENGTH)

  if(nclearave.ne.0) nsum=0
  nclearave=0
  if(nsum.eq.0) then
     dop0=doppler                         !Remember the initial Doppler
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
  ib=nint((f1+doppler-nfrit)/df)
  if(ia.lt.600 .or. ib.lt.600) go to 900
  if(ia.gt.7590 .or. ib.gt.7590) go to 900

  nsum=nsum+1

  do i=1,2000
     sa(i)=sa(i) + s(ia+i-1000)    !Center at initial doppler freq
     sb(i)=sb(i) + s(ib+i-1000)    !Center at expected echo freq
  enddo

  call pctile(sb,200,50,r0)
  call pctile(sb(1800),200,50,r1)

  sum=0.
  sq=0.
  do i=1,2000
     y=r0 + (r1-r0)*(i-100.0)/1800.0
     blue(i)=sa(i)/y
     red(i)=sb(i)/y
     if(i.le.500 .or. i.ge.1501) then
        sum=sum+red(i)
        sq=sq + (red(i)-1.0)**2
     endif
  enddo
  ave=sum/1000.0
  rms=sqrt(sq/1000.0)

  redmax=maxval(red)
  ipkv=maxloc(red)
  fac=10.0/max(redmax,10.0)
  dfreq=(ipk-1000)*df
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
     call smo121(red,2000)
     call smo121(blue,2000)
  enddo

900 continue
  write(*,3001) ia,ib,nclearave,nsum,width,snr,nqual
3001 format('avecho:',4i6,2f7.1,i5)

  return
end subroutine avecho
