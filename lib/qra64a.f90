subroutine qra64a(dd,nutc,nf1,nf2,nfqso,ntol,mode64,mycall_12,hiscall_12,   &
     hisgrid_6,sync,nsnr,dtx,nfreq,decoded,nft)

  use packjt
  parameter (NFFT=2*6912,NZ=5760,NMAX=60*12000,LN=1152*63)
  character decoded*22
  character*12 mycall_12,hiscall_12
  character*6 mycall,hiscall,hisgrid_6
  character*4 hisgrid
  logical ltext
  complex c00(0:360000)                      !Complex spectrum of dd()
  complex c0(0:360000)                       !Complex spectrum of dd()
!  integer*8 count0,count1,clkfreq
  real a(3)
  real dd(NMAX)                              !Raw data sampled at 12000 Hz
  real s3(LN)                                !Symbol spectra
  real s3a(LN)                               !Symbol spectra
  integer dat4(12)                           !Decoded message (as 12 integers)
  integer dat4x(12)
  data nc1z/-1/,nc2z/-1/,ng2z/-1/
  save

  if(nfqso.lt.nf1 .or. nfqso.gt.nf2) go to 900
  nft=99
  nsnr=-30
  mycall=mycall_12(1:6)                     !### May need fixing ###
  hiscall=hiscall_12(1:6)
  hisgrid=hisgrid_6(1:4)
  call packcall(mycall,nc1,ltext)
  call packcall(hiscall,nc2,ltext)
  call packgrid(hisgrid,ng2,ltext)
  nSubmode=0
  if(mode64.eq.2) nSubmode=1
  if(mode64.eq.4) nSubmode=2
  if(mode64.eq.8) nSubmode=3
  if(mode64.eq.16) nSubmode=4
  b90=1.0
  nFadingModel=1
  if(nc1.ne.nc1z .or. nc2.ne.nc2z .or. ng2.ne.ng2z) then
     do naptype=0,5
        call qra64_dec(s3,nc1,nc2,ng2,naptype,1,nSubmode,b90,      &
             nFadingModel,dat4,snr2,irc)
     enddo
     nc1z=nc1
     nc2z=nc2
     ng2z=ng2
  endif

  maxf1=5
  call sync64(dd,nf1,nf2,nfqso,ntol,mode64,maxf1,dtx,f0,jpk,kpk,snr1,c00)

  npts2=216000
  naptype=4
  LL=64*(mode64+2)
  NN=63
!  do itry0=1,3
  do itry0=1,1
     idf0=itry0/2
     if(mod(itry0,2).eq.0) idf0=-idf0
     a(1)=-(f0+0.248*(idf0-0.33*kpk))
     nfreq=nint(-a(1))
     a(3)=0.
!     do itry1=1,3
     do itry1=1,1
        idf1=itry1/2
        if(mod(itry1,2).eq.0) idf1=-idf1
        a(2)=-0.67*(idf1 + 0.67*kpk)
        call twkfreq(c00,c0,npts2,4000.0,a)
        call spec64(c0,npts2,mode64,jpk,s3a,LL,NN)
        ircmin=99
        do iter=0,10
           b90=1.728**iter
           s3(1:LL*NN)=s3a(1:LL*NN)
           call qra64_dec(s3,nc1,nc2,ng2,naptype,0,nSubmode,b90,      &
                nFadingModel,dat4,snr2,irc)
           if(abs(snr2).gt.30.) snr2=-30.0
           if(irc.eq.0) go to 10
!           write(*,3001) iter,b90,snr2,irc
!           write(72,3001) iter,b90,snr2,irc
!3001       format(i2,2f7.1,i4)
           if(irc.ge.0 .and. irc.le.ircmin) then
              dat4x=dat4
              b90x=b90
              snr2x=snr2
              ircmin=irc
           endif
        enddo
        if(ircmin.ne.99) then
              dat4=dat4x
              b90=b90x
              snr2=snr2x
              irc=ircmin
        endif
10      decoded='                      '
!        write(73,3001) iter,b90,snr2,irc
        if(irc.ge.0) then
           call unpackmsg(dat4,decoded)           !Unpack the user message
           call fmtmsg(decoded,iz)
           nft=100 + irc
           nsnr=nint(snr2)
        else
           snr2=0.
        endif
!        write(78,3900) nutc,snr1,snr2,dtx,nfreq,kpk,idf0,idf1,irc,decoded
!3900    format(i4.4,2f6.1,f6.2,i5,4i3,1x,a22)
!        flush(78)
!        write(*,3006) idf0,idf1,nfreq,jpk,kpk,irc,decoded
!3006    format(2i4,i6,i7,2i4,2x,a22)
        if(irc.ge.0) go to 900
     enddo
  enddo
900 continue
  if(index(decoded,"000AAA ").ge.1) then
! Suppress a certain type of garbage decode.
     decoded='                      '
     irc=-1
  endif

  return
end subroutine qra64a
