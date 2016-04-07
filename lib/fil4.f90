subroutine fil4(id1,n1,id2,n2,nrefspec)

! FIR lowpass filter designed using ScopeFIR

! fsample     = 48000 Hz
! Ntaps       = 49
! fc          = 4500  Hz
! fstop       = 6000  Hz
! Ripple      = 1     dB
! Stop Atten  = 40    dB
! fout        = 12000 Hz

  parameter (NTAPS=49)
  parameter (NDOWN=4)             !Downsample ratio
  parameter (NFFT=13824,NH=NFFT/2)
  integer*2 id1(n1)
  integer*2 id2(*)
  real t(NTAPS)
  real x(NFFT)
  real s(0:NH)
  complex cx(0:NH)
  equivalence(x,cx)
  data t/NTAPS*0.0/,nrefspec0/-999/

! Filter coefficients:
  real w(NTAPS)
  data w/                                                                 &
        0.000861074040, 0.010051920210, 0.010161983649, 0.011363155076,   &
        0.008706594219, 0.002613872664,-0.005202883094,-0.011720748164,   &
       -0.013752163325,-0.009431602741, 0.000539063909, 0.012636767098,   &
        0.021494659597, 0.021951235065, 0.011564169382,-0.007656470131,   &
       -0.028965787341,-0.042637874109,-0.039203309748,-0.013153301537,   &
        0.034320769178, 0.094717832646, 0.154224604789, 0.197758325022,   &
        0.213715139513, 0.197758325022, 0.154224604789, 0.094717832646,   &
        0.034320769178,-0.013153301537,-0.039203309748,-0.042637874109,   &
       -0.028965787341,-0.007656470131, 0.011564169382, 0.021951235065,   &
        0.021494659597, 0.012636767098, 0.000539063909,-0.009431602741,   &
       -0.013752163325,-0.011720748164,-0.005202883094, 0.002613872664,   &
        0.008706594219, 0.011363155076, 0.010161983649, 0.010051920210,   &
        0.000861074040/
  save w,t,nsave,s,nrefspec0

  if(nrefspec.ne.nrefspec0) then
     s=0.
     nsave=0
     nrefspec0=nrefspec
  endif

  n2=n1/NDOWN
  if(n2*NDOWN.ne.n1) stop 'Error in fil4'
  k=1-NDOWN
  do i=1,n2
     k=k+NDOWN
     t(1:NTAPS-NDOWN)=t(1+NDOWN:NTAPS)          !Shift old data down in array t
     t(1+NTAPS-NDOWN:NTAPS)=id1(k:k+NDOWN-1)    !Insert new data at end of t
     id2(i)=nint(dot_product(w,t))
  enddo

  if(nrefspec.eq.1) then
     nsave=nsave+1
     x=0.001*id1
     call four2a(x,NFFT,1,-1,0)                 !r2c FFT

     do i=1,NH
        s(i)=s(i) + real(cx(i))**2 + aimag(cx(i))**2
     enddo

     if(mod(nsave,34).eq.0) then                   !About 9.8 sec 
        df=48000.0/NFFT
        ia=nint(500.0/df)
        ib=nint(2500.0/df)
        call pctile(s(ia),ib-ia+1,50,xmed)
        db0=db(xmed)
        nhadd=10
        open(16,file='refspec.dat',status='unknown')
        do i=1,NH
           freq=i*df
           ia=max(1,i-nhadd)
           ib=min(NH,i+nhadd)
           smo=sum(s(ia:ib))/(ib-ia+1)
           write(16,1000) freq,db(smo)-db0
1000       format(2f10.3)
        enddo
        close(16)
     endif
  endif

  return
end subroutine fil4
