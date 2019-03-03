subroutine getcandidates4(id,fa,fb,syncmin,nfqso,maxcand,savg,candidate,   &
     ncand,sbase)

  include 'ft4_params.f90'
  real s(NH1,NHSYM)
  real savg(NH1),savsm(NH1)
  real sbase(NH1)
  real x(NFFT1)
  real window(NFFT1)
  complex cx(0:NH1)
  real candidate(3,maxcand)
  integer*2 id(NMAX)
  integer indx(NH1)
  integer ipk(1)
  equivalence (x,cx)
  logical first
  data first/.true./
  save first,window

  if(first) then
    first=.false.
    pi=4.0*atan(1.)
    window=0.
    call nuttal_window(window,NFFT1)
  endif

! Compute symbol spectra, stepping by NSTEP steps.  
  savg=0.
  tstep=NSTEP/12000.0                         
  df=12000.0/NFFT1                            !5.86 Hz
  fac=1.0/300.0
  do j=1,NHSYM
     ia=(j-1)*NSTEP + 1
     ib=ia+NFFT1-1
     if(ib.gt.NMAX) exit
     x=fac*id(ia:ib)*window
     call four2a(x,NFFT1,1,-1,0)              !r2c FFT
     do i=1,NH1
        s(i,j)=real(cx(i))**2 + aimag(cx(i))**2
     enddo
     savg=savg + s(1:NH1,j)                   !Average spectrum
  enddo
  savsm=0.
  do i=8,NH1-7
    savsm(i)=sum(savg(i-7:i+7))/15.
  enddo
  nfa=fa/df
  if(nfa.lt.1) nfa=1
  nfb=fb/df
  if(nfb.gt.nint(5000.0/df)) nfb=nint(5000.0/df)
  np=nfb-nfa+1
  indx=0
  call indexx(savsm(nfa:nfb),np,indx)
  xn=savsm(nfa+indx(nint(0.3*np)))
  savsm=savsm/xn

  ncand=0
  f_offset = -1.5*12000/512
  do i=nfa+1,nfb-1
    if(savsm(i).ge.savsm(i-1) .and. savsm(i).ge.savsm(i+1) .and. savsm(i).ge.syncmin) then
      del=0.5*(savsm(i-1)-savsm(i+1))/(savsm(i-1)-2*savsm(i)+savsm(i+1))
      fpeak=(i+del)*df+f_offset
      speak=savsm(i) - 0.25*(savsm(i-1)-savsm(i+1))*del
      ncand=ncand+1
      if(ncand.gt.maxcand) exit
      candidate(1,ncand)=fpeak
      candidate(2,ncand)=-99.99
      candidate(3,ncand)=speak
    endif
  enddo

return
end subroutine getcandidates4
