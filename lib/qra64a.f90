subroutine qra64a(dd,nf1,nf2,nfqso,ntol,mycall_12,sync,nsnr,dtx,nfreq,    &
     decoded,nft)

  use packjt
  parameter (NFFT=2*6912,NH=NFFT/2,NZ=5760)
  character decoded*22,mycall_12*12,mycall*6
  character*1 mark(0:5),zplot(0:63)
  logical ltext
  integer icos7(0:6)
  integer ipk(1)
  integer jpk(1)
  integer dat4(12)
  real dd(60*12000)
  real s(NZ)
  real savg(NZ)
  real blue(0:25)
  real red(NZ)
  real x(NFFT)
  complex cx(0:NH)
  equivalence (x,cx)
  data icos7/2,5,6,0,4,1,3/                            !Costas 7x7 pattern
  data mark/' ','.','-','+','X','$'/
  common/qra64com/ss(NZ,194),s3(0:63,1:63),ccf(NZ,0:25)
  save

!  rewind 73
!  rewind 74
!  rewind 75
!  rewind 76

  decoded='                      '
  nft=99
  nsnr=-30
  nsps=6912
  istep=nsps/2
  nsteps=52*12000/istep - 2
  ia=1-istep
  savg=0.
  df=12000.0/NFFT
  do j=1,nsteps
     ia=ia+istep
     ib=ia+nsps-1
     x(1:nsps)=1.2e-4*dd(ia:ib)
     x(nsps+1:)=0.0
     call four2a(x,nfft,1,-1,0)        !r2c FFT
     do i=1,NZ
        s(i)=real(cx(i))**2 + aimag(cx(i))**2
     enddo
     ss(1:NZ,j)=s
     savg=savg+s
  enddo

  savg=savg/nsteps
  call pctile(savg,NZ,45,base)
  savg=savg/base - 1.0
  ss=ss/base

  fa=max(nf1,nfqso-ntol)
  fb=min(nf2,nfqso+ntol)
  ia=nint(fa/df)
  ib=nint(fb/df)
  fac=1.0/sqrt(21.0)
  sync=0.
  do if0=ia,ib
     red(if0)=0.
     do j=0,25
        t=-3.0
        do n=0,6
           i=if0 + 2*icos7(n)
           t=t + ss(i,1+2*n+j) + ss(i,1+2*n+j+78) + ss(i,1+2*n+j+154)
        enddo
        ccf(if0,j)=fac*t
        if(ccf(if0,j).gt.red(if0)) then
           red(if0)=ccf(if0,j)
           if(red(if0).gt.sync) then
              sync=red(if0)
              f0=if0*df
              dtx=j*istep/12000.0 - 1.0
              i0=if0
              j0=j
           endif
        endif
     enddo
  enddo

  if0=nint(f0/df)
  nfreq=nint(f0)
  blue(0:25)=ccf(if0,0:25)
  jpk=maxloc(blue)
  xpk=jpk(1) + 1.0
  call slope(blue,26,xpk)

! Insist on at least 10 correct hard decisions in the 21 Costas bins.
  nhard=0
  do n=0,6
     ipk=maxloc(ss(i0:i0+63,1+j0+2*n)) - 1
     i=abs(ipk(1)-2*icos7(n))
     if(i.le.1) nhard=nhard+1

     ipk=maxloc(ss(i0:i0+63,1+j0+2*n+78)) - 1
     i=abs(ipk(1)-2*icos7(n))
     if(i.le.1) nhard=nhard+1

     ipk=maxloc(ss(i0:i0+63,1+j0+2*n+154)) - 1
     i=abs(ipk(1)-2*icos7(n))
     if(i.le.1) nhard=nhard+1
  enddo
!  print*,'a',nhard,nhard,nhard
  if(nhard.lt.6) go to 900

  do i=0,63
     k=i0 + 2*i
     jj=j0+13
     do j=1,63
        jj=jj+2
        s3(i,j)=ss(k,jj)
        if(j.eq.32) jj=jj+14               !Skip over the middle Costas array
     enddo
  enddo

  if(sync.gt.1.0) nsnr=nint(10.0*log10(sync) - 38.0)
!  if(sync.lt.12.8) go to 900                !### Temporary ###

  mycall=mycall_12(1:6)                     !### May need fixing ###
  call packcall(mycall,nmycall,ltext)
  call qra64_dec(s3,nmycall,dat4,irc)       !Attempt decoding
  if(irc.ge.0) then
     call unpackmsg(dat4,decoded)           !Unpack the user message
     call fmtmsg(decoded,iz)
     nft=100 + irc
  endif

900 return
end subroutine qra64a
