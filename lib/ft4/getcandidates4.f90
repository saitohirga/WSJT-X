subroutine getcandidates4(id,fa,fb,syncmin,nfqso,maxcand,savg,candidate,   &
     ncand,sbase)

  include 'ft4_params.f90'
  real s(NH1,NHSYM)
  real savg(NH1),savsm(NH1)
  real sbase(NH1)
  real x(NFFT1)
  complex cx(0:NH1)
  real candidate(3,maxcand)
  integer*2 id(NMAX)
  integer indx(NH1)
  equivalence (x,cx)

! Compute symbol spectra, stepping by NSTEP steps.  
  savg=0.
  tstep=NSTEP/12000.0                         
  df=12000.0/NFFT1                            !3.125 Hz
  fac=1.0/300.0
  do j=1,NHSYM
     ia=(j-1)*NSTEP + 1
     ib=ia+NSPS-1
     x(1:NSPS)=fac*id(ia:ib)
     x(NSPS+1:)=0.
     call four2a(x,NFFT1,1,-1,0)              !r2c FFT
     do i=1,NH1
        s(i,j)=real(cx(i))**2 + aimag(cx(i))**2
     enddo
     savg=savg + s(1:NH1,j)                   !Average spectrum
  enddo
  savsm=0.
  do i=6,NH1-5
    savsm(i)=sum(savg(i-5:i+5))/11.
  enddo
  nfa=fa/df
  nfb=fb/df
  np=nfb-nfa+1
  indx=0
  call indexx(savsm(nfa:nfb),np,indx)
  xn=savsm(nfa+indx(nint(0.3*np)))
  savsm=savsm/xn
  imax=-1
  xmax=-99.
  do i=2,NH1-1
    if(savsm(i).gt.savsm(i-1).and.    &
       savsm(i).gt.savsm(i+1).and.    &
       savsm(i).gt.xmax) then
      xmax=savsm(i) 
      imax=i
    endif
  enddo
  f0=imax*df
  if(xmax.gt.1.2) then
     ncand=ncand+1
     candidate(1,ncand)=f0
     candidate(2,ncand)=-99.9
     candidate(3,ncand)=xmax
  endif
return
end subroutine getcandidates4
