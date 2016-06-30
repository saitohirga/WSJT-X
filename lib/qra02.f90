subroutine qra02(dd,nf1,nf2,nfqso,ntol,mycall_12,sync,nsnr,dtx,nfreq,    &
     decoded,nft)

  use packjt
  parameter (NFFT=2*6912,NH=NFFT/2,NZ=5760)
  character decoded*22,mycall_12*12,mycall*6
  character*1 mark(0:5),zplot(0:63)
  logical ltext
  integer icos7(0:6)
  integer ipk(1)
  integer jpk(1)
!  integer dat4(12)
  integer dat4(120)
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
  common/qra65com/ss(NZ,194),s3(0:63,1:63),ccf(NZ,0:25)
  save

!  rewind 74
!  rewind 75

!  print*,'B',nf1,nf2,nfqso,ntol
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
!  do i=1,NZ
!     write(73,1010) i*df,savg(i),i
!1010 format(2f10.3,i8)
!  enddo

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

  do i=0,63
     k=i0 + 2*i
     jj=j0+13
     do j=1,63
        jj=jj+2
        s3(i,j)=ss(k,jj)
        if(j.eq.32) jj=jj+14               !Skip over the middle Costas array
     enddo
  enddo

  do j=1,63
     do i=0,63
        n=0.25*s3(i,j)
        if(n.lt.0) n=0
        if(n.gt.5) n=5
        zplot(i)=mark(n)
     enddo
     ipk=maxloc(s3(0:63,j))
!     write(76,3001) j,zplot,ipk(1)-1
!3001 format(i2,1x,'|',64a1,'|',i4)
  enddo

  if0=nint(f0/df)
  nfreq=nint(f0)
  blue(0:25)=ccf(if0,0:25)
  jpk=maxloc(blue)
  xpk=jpk(1) + 1.0
  call slope(blue,26,xpk)

!  do j=0,25
!     tsec=j*istep/12000.0
!     write(74,1020) tsec,blue(j)
!1020 format(f5.2,i3,10f7.1)
!  enddo

!  do i=ia,ib
!     f=i*df
!     write(75,1030) f,red(i)
!1030 format(2f10.2)
!  enddo
!  flush(74)
!  flush(75)
!  flush(76)

  nsnr=-30
  if(sync.gt.1.0) nsnr=nint(10.0*log10(sync) - 38.0)

  decoded='                      '
  nft=100
  mycall=mycall_12(1:6)                     !### May need fixing ###
  call packcall(mycall,nmycall,ltext)
!  write(77,3002) s3
!3002 format(f10.3)
!  flush(77)
!  print*,'a',sync,dtx,base
  call qra65_dec(s3,nmycall,dat4,irc)       !Attempt decoding
!  print*,'z',sync,dtx,nfreq
  if(irc.ge.0) then
     call unpackmsg(dat4,decoded)           !Unpack the user message
     call fmtmsg(decoded,iz)
     nft=100 + irc
  endif

  return
end subroutine qra02
