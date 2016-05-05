subroutine decode9w(nfqso,ntol,nsubmode,ss,id2,sync,nsnr,xdt1,f0,decoded)

! Decode a weak signal in a wide/slow JT9 submode.

  parameter (NSMAX=6827,NZMAX=60*12000)
  real ss(184,NSMAX)                     !Symbol spectra at 1/2-symbol steps
  real ccfred(NSMAX)                     !Best sync vs frequency
  real ccfblue(-9:18)                    !Sync vs time at best frequency
  real a(5)                              !Fitted Lorentzian params
  integer*2 id2(NZMAX)                   !Raw 16-bit data
  integer*1 i1SoftSymbols(207)           !Binary soft symbols
  character*22 decoded                   !Decoded message

  df=12000.0/16384.0                     !Bin spacing in ss()
  nsps=6912                              !Samples per 9-FSK symbol
  tstep=nsps*0.5/12000.0                 !Half-symbol duration
  npts=52*12000
  limit=10000                            !Fano timeout parameter

  ia=max(1,nint((nfqso-ntol)/df))        !Start frequency bin
  ib=min(NSMAX,nint((nfqso+ntol)/df))    !End frequency bin
  lag1=-int(2.5/tstep + 0.9999)          !Start lag
  lag2=int(5.0/tstep + 0.9999)           !End lag
  nhsym=184                              !Number of half-symbols

! First sync pass finds approximate Doppler spread; second pass does a
! good Lorentzian fit to determine frequency f0.
  do iter=1,2
     nadd=3
     if(iter.eq.2) nadd=2*nint(0.375*a(4)) + 1
     call sync9w(ss,nhsym,lag1,lag2,ia,ib,ccfred,ccfblue,ipk,lagpk,nadd)
     sum1=sum(ccfblue) - ccfblue(lagpk-1)-ccfblue(lagpk) -ccfblue(lagpk+1)
     sq=dot_product(ccfblue,ccfblue) - ccfblue(lagpk-1)**2 - &
          ccfblue(lagpk)**2 - ccfblue(lagpk+1)**2
     base=sum1/25.0
     rms=sqrt(sq/24.0)
     sync=(ccfblue(lagpk)-base)/rms
     nsnr=nint(db(sync)-29.7)
     xdt0=lagpk*tstep
     call lorentzian(ccfred(ia),ib-ia+1,a)
     f0=(ia+a(3))*df
     ccfblue=(ccfblue-base)/rms
  enddo

  call softsym9w(id2,npts,xdt0,f0,a(4)*df,nsubmode,xdt1-1.05,i1softsymbols)
  call jt9fano(i1softsymbols,limit,nlim,decoded)

  return
end subroutine decode9w
