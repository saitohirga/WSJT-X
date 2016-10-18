subroutine sh65(cx,n5,mode65,ntol,xdf,nspecial,snrdb)
  parameter(NFFT=2048,NH=NFFT/2,MAXSTEPS=150)
  complex cx(90000)
  complex c(0:NFFT-1)
  real s(-NH+1:NH)
  real s2(-NH+1:NH,MAXSTEPS)
  real ss(-NH+1:NH,8)
  real sigmax(8)
  integer ipk(8)

  s=0.
  ss=0.

  jstep=NFFT/4
  nblks=n5/jstep - 3
  ia=-jstep+1
  do iblk=1,nblks
     ia=ia+jstep
     ib=ia+NFFT-1
     c=cx(ia:ib)
     call four2a(c,nfft,1,1,1)            !c2c FFT
     do i=0,NFFT-1
        j=i
        if(j.gt.NH) j=j-NFFT
        p=real(c(i))**2 + aimag(c(i))**2
        s(j)=s(j) + p
        s2(j,iblk)=p
     enddo
     n=mod(iblk-1,8) +1
     ss(-NH+1:NH,n)=ss(-NH+1:NH,n) + s2(-NH+1:NH,iblk)
  enddo

  s=1.e-6*s
  ss=1.e-6*ss
  df=1378.1285/NFFT
  nfac=40*mode65
  dtstep=0.25/df

! Define range of frequencies to be searched
  fa=-ntol
  fb=ntol
  ia2=max(-NH+1,nint(fa/df))
! Upper tone is above sync tone by 4*nfac*df Hz
  ib2=min(NH,nint(fb/df + 4.1*nfac))

! Find strongest line in each of the 4 phases, repeating for each drift rate.
  sbest=0.
  snrbest=0.
  nbest=1
  ipk=0

  do n=1,8
     sigmax(n)=0.
     do i=ia2,ib2
        sig=ss(i,n)
        if(sig.ge.sigmax(n)) then
           ipk(n)=i
           sigmax(n)=sig
           if(sig.ge.sbest) then
              sbest=sig
              nbest=n
           endif
        endif
     enddo
  enddo
  n2best=nbest+4
  if(n2best.gt.8) n2best=nbest-4
  xdf=min(ipk(nbest),ipk(n2best))*df
  nspecial=0
  if(abs(xdf).le.ntol) then
     idiff=abs(ipk(nbest)-ipk(n2best))
     xk=float(idiff)/nfac
     k=nint(xk)
     iderr=nint((xk-k)*nfac)
!     maxerr=nint(0.008*abs(idiff) + 0.51)
     maxerr=nint(0.02*abs(idiff) + 0.51)     !### Better test ??? ###
     if(abs(iderr).le.maxerr .and. k.ge.2 .and. k.le.4) nspecial=k
     snrdb=-30.0
     if(nspecial.gt.0) then
        call sh65snr(ss(ia2,nbest),ib2-ia2+1,snr1)
        call sh65snr(ss(ia2,n2best),ib2-ia2+1,snr2)
        snr=0.5*(snr1+snr2)
        snrdb=db(snr) - db(2500.0/df) - db(sqrt(nblks/4.0)) + 8.0
     endif
     if(snr1.lt.4.0 .or. snr2.lt.4.0 .or. snr.lt.5.0) nspecial=0
  endif

  return
end subroutine sh65
