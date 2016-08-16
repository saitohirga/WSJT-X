subroutine qra64a(dd,nutc,nf1,nf2,nfqso,ntol,mode64,mycall_12,hiscall_12,   &
     hisgrid_6,sync,nsnr,dtx,nfreq,decoded,nft)

  use packjt
  parameter (NFFT=2*6912,NZ=5760,NMAX=60*12000)
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
  real s3(0:63,1:63)                         !Symbol spectra
  integer dat4(12)                           !Decoded message (as 12 integers)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/                  !Costas 7x7 pattern
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
  if(nc1.ne.nc1z .or. nc2.ne.nc2z .or. ng2.ne.ng2z) then
     do naptype=0,5
        call qra64_dec(s3,nc1,nc2,ng2,naptype,1,dat4,snr2,irc)
     enddo
     nc1z=nc1
     nc2z=nc2
     ng2z=ng2
  endif

  maxf1=5
  call sync64(dd,nf1,nf2,nfqso,ntol,mode64,maxf1,dtx,f0,jpk,kpk,snr1,c00)
  
  npts2=216000
  naptype=4
  do itry0=1,3
     idf0=itry0/2
     if(mod(itry0,2).eq.0) idf0=-idf0
     a(1)=-(f0+0.248*(idf0-0.33*kpk))
     nfreq=nint(-a(1))
     a(3)=0.
     do itry1=1,3
        idf1=itry1/2
        if(mod(itry1,2).eq.0) idf1=-idf1
        a(2)=-0.67*(idf1 + 0.67*kpk)
        call twkfreq(c00,c0,npts2,4000.0,a)
        call spec64(c0,npts2,mode64,jpk,s3)
        call qra64_dec(s3,nc1,nc2,ng2,naptype,0,dat4,snr2,irc)
        decoded='                      '
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
