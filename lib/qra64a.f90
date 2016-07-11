subroutine qra64a(dd,nf1,nf2,nfqso,ntol,mycall_12,sync,nsnr,dtx,nfreq,    &
     decoded,nft)

  use packjt
  parameter (NFFT=2*6912,NH=NFFT/2,NZ=5760)
  character decoded*22,mycall_12*12,mycall*6
  logical ltext
  integer icos7(0:6)
  integer ipk(1)
  integer ij(2)
  integer dat4(12)
  real ss(NZ,194)
  real s3(0:63,1:63)
  real dd(60*12000)
  real s(NZ)
  real savg(NZ)
  real red(NZ)
  real ccf(NZ,0:25)
  real ccf1(NZ,0:25)
  real ccf2(NZ,0:25)
  real ccf3(NZ,0:25)
  real x(NFFT)
  real syncd(-4:4,-5:5)
  complex cx(0:NH)
  equivalence (x,cx)
  data icos7/2,5,6,0,4,1,3/                            !Costas 7x7 pattern
  save

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

  fa=max(nf1,nfqso-ntol)
  fb=min(nf2,nfqso+ntol)
  ia=nint(fa/df)
  ib=nint(fb/df)
  call pctile(savg(ia),ib-ia+1,45,base)
  savg=savg/base - 1.0
  ss=ss/base

  ccf=0.
  red=0.
  sync=0.
  fac=1.0/sqrt(21.0)
  do if0=ia,ib
     red(if0)=0.
     do j=0,25
        t1=0.0
        t2=0.0
        t3=0.0
        do n=0,6
           i=if0 + 2*icos7(n)
           t1=t1 + ss(i,1+2*n+j)
           t2=t2 + ss(i,1+2*n+j+78)
           t3=t3 + ss(i,1+2*n+j+154)
        enddo
        ccf1(if0,j)=fac*t1
        ccf2(if0,j)=fac*t2
        ccf3(if0,j)=fac*t3
        ccf(if0,j)=fac*(t1+t2+t3)
     enddo
  enddo

  ij=maxloc(ccf)
  i0=ij(1)
  j0=ij(2)-1
  red(ia:ib)=ccf(ia:ib,j0)
  sync=ccf(i0,j0)
  dtx=j0*istep/12000.0 - 1.0
  nfreq=nint(i0*df)

  syncbest=0.
  syncd=0.
  do k=-4,4
     syncd(-4:4,k)=ccf1(i0-k-4:i0-k+4,j0) + ccf2(i0-4:i0+4,j0) +       &
          ccf3(i0+k-4:i0+k+4,j0)
  enddo
  ij=maxloc(syncd)
  iadd=ij(1)-5
  idrift=ij(2)-6
  drift=idrift
  syncbest=maxval(syncd)
!  write(*,3002) i0,iadd,idrift,sync,syncbest
!3002 format(3i5,2f7.1)
  i0=i0+iadd

  write(17) ia,ib,red(ia:ib)
  close(17)

!  rewind 71
!  do i=ia,ib
!     write(71,3001) i*df,red(i),ccf1(i,j0),ccf2(i,j0),ccf3(i,j0)
!3001 format(5f10.3)
!  enddo
!  flush(71)

! Insist on at least 6 correct hard decisions in the 21 Costas bins.
!### Should include drift solution here ...
  nhard=0
  do n=0,6
     ipk=maxloc(ss(i0:i0+2*63,1+j0+2*n)) - 1
     i=abs(ipk(1)-2*icos7(n))
     if(i.le.1) nhard=nhard+1

     ipk=maxloc(ss(i0:i0+2*63,1+j0+2*n+78)) - 1
     i=abs(ipk(1)-2*icos7(n))
     if(i.le.1) nhard=nhard+1

     ipk=maxloc(ss(i0:i0+2*63,1+j0+2*n+154)) - 1
     i=abs(ipk(1)-2*icos7(n))
     if(i.le.1) nhard=nhard+1
  enddo
  if(nhard.lt.6) go to 900

  do i=0,63
     k=i0 + 2*i
     jj=j0+13                              !Skip over the first Costas array
     do j=1,63
        jj=jj+2
        kk=nint(drift*(jj-(82+j0))/70.0)
!        if(i.eq.0) write(72,3101) j,jj,kk
!3101    format(3i6)
        s3(i,j)=ss(k+kk,jj)
        if(j.eq.32) jj=jj+14               !Skip over the middle Costas array
     enddo
  enddo

  if(sync.gt.1.0) nsnr=nint(10.0*log10(sync) - 38.0)

  mycall=mycall_12(1:6)                     !### May need fixing ###
  call packcall(mycall,nmycall,ltext)
  call qra64_dec(s3,nmycall,dat4,irc)       !Attempt decoding
  if(irc.ge.0) then
     call unpackmsg(dat4,decoded)           !Unpack the user message
     call fmtmsg(decoded,iz)
     nft=100 + irc
!### Should recompute S/N here, using all 84 symbols ...     
  endif

900 return
end subroutine qra64a
