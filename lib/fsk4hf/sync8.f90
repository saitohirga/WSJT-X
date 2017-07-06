subroutine sync8(iwave,nfa,nfb,nfqso,s,candidate,ncand)

  include 'ft8_params.f90'
  parameter (JZ=31)                            !DT up to +/- 2.5 s
  complex cx(0:NH1)
  real s(NH1,NHSYM)
  real savg(NH1)
  real x(NFFT1)
  real sync2d(NH1,-JZ:JZ)
  real red(NH1)
  real candidate0(3,100)
  real candidate(3,100)
  integer*2 iwave(NMAX)
  integer jpeak(NH1)
  integer indx(NH1)
  integer ii(1)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/                   !Costas 7x7 tone pattern
  equivalence (x,cx)

! Compute symbol spectra at half-symbol steps.  
  savg=0.
  istep=NSPS/2                                !960
  tstep=istep/12000.0                         !0.08 s
  df=12000.0/NFFT1                            !3.125 Hz

! Compute symbol spectra at half-symbol steps
  fac=1.0/300.0
  do j=1,NHSYM
     ia=(j-1)*istep + 1
     ib=ia+NSPS-1
     x(1:NSPS)=fac*iwave(ia:ib)
     x(NSPS+1:)=0.
     call four2a(x,NFFT1,1,-1,0)              !r2c FFT
     do i=1,NH1
        s(i,j)=real(cx(i))**2 + aimag(cx(i))**2
     enddo
     savg=savg + s(1:NH1,j)                   !Average spectrum
  enddo
  savg=savg/NHSYM
!  do i=1,NH1
!     write(51,3051) i*df,savg(i),db(savg(i))
!3051 format(f10.3,e12.3,f12.3)
!  enddo

  ia=max(1,nint(nfa/df))
  ib=nint(nfb/df)
  do i=ia,ib
     do j=-JZ,JZ
        t=0.
        t0=0.
        do n=0,6
           k=j+2*n
           if(k.ge.1) then
              t=t + s(i+2*icos7(n),k)
              t0=t0 + sum(s(i:i+12:2,k))
           endif
           t=t + s(i+2*icos7(n),k+72)
           t0=t0 + sum(s(i:i+12:2,k+72))
           if(k+144.le.NHSYM) then
              t=t + s(i+2*icos7(n),k+144)
              t0=t0 + sum(s(i:i+12:2,k+144))
           endif
        enddo
        t0=(t0-t)/6.0
        sync2d(i,j)=t/t0
     enddo
  enddo

  red=0.
  do i=ia,ib
     ii=maxloc(sync2d(i,-JZ:JZ)) - 1 - JZ
     j0=ii(1)
     jpeak(i)=j0
     red(i)=sync2d(i,j0)
!     write(52,3052) i*df,red(i),db(red(i))
!3052 format(3f12.3)
  enddo
  iz=ib-ia+1
  call indexx(red(ia:ib),iz,indx)
  ibase=indx(nint(0.40*iz)) - 1 + ia
  base=red(ibase)
  red=red/base

  candidate0=0.
  k=0
  syncmin=1.5
  do i=1,100
     n=ia + indx(iz+1-i) - 1
     if(red(n).lt.syncmin) exit
     k=k+1
     candidate0(1,k)=n*df
     candidate0(2,k)=(jpeak(n)-1)*tstep
     candidate0(3,k)=red(n)
  enddo
  ncand=min(100,k)

! Put nfqso at top of list, and save only the best of near-dupe freqs.  
  do i=1,ncand
     if(abs(candidate0(1,i)-nfqso).lt.10.0) candidate0(1,i)=-candidate0(1,i)
     if(i.ge.2) then
        do j=1,i-1
           fdiff=abs(candidate0(1,i))-abs(candidate0(1,j))
           if(abs(fdiff).lt.4.0) then
              if(candidate0(3,i).ge.candidate0(3,j)) candidate0(3,j)=0.
              if(candidate0(3,i).lt.candidate0(3,j)) candidate0(3,i)=0.
           endif
        enddo
!        write(*,3001) i,candidate0(1,i-1),candidate0(1,i),candidate0(3,i-1),  &
!             candidate0(3,i)
!3001    format(i2,4f8.1)
     endif
  enddo
  
  fac=20.0/maxval(s)
  s=fac*s

  call indexx(candidate0(1,1:ncand),ncand,indx)
  do i=1,ncand
     j=indx(i)
     candidate(1,i)=abs(candidate0(1,j))
     candidate(2,i)=candidate0(2,j)
     candidate(3,i)=candidate0(3,j)
  enddo
  
  return
end subroutine sync8
