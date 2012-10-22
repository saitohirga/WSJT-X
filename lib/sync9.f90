subroutine sync9(ss,tstep,df3,ntol,nfqso,sync,snr,fpk,ccfred)

  parameter (NSMAX=22000)            !Max length of saved spectra
  real ss(184,NSMAX)
  real ccfred(NSMAX)
  include 'jt9sync.f90'

  ipk=0
  ipkbest=0
  ia=1
  ib=min(1000,nint(1000.0/df3))

  if(ntol.lt.1000) then
     ia=nint((nfqso-1000-ntol)/df3)
     ib=nint((nfqso-1000+ntol)/df3)
     if(ia.lt.1) ia=1
     if(ib.gt.NSMAX) ib=NSMAX
  endif

  sbest=0.
  lagmax=2.5/tstep + 0.9999
  ccfred=0.

  do i=ia,ib
     smax=0.
     do lag=-lagmax,lagmax
        sum=0.
        do j=1,16
           k=ii2(j) + lag
           if(k.ge.1) sum=sum + ss(k,i)
        enddo
        if(sum.gt.smax) then
           smax=sum
           ipk=i
           lagpk=lag
        endif
     enddo
     ccfred(i)=smax                        !Best at this freq, over all lags
     if(smax.gt.sbest) then
        sbest=smax
        ipkbest=ipk
        lagpkbest=lagpk
     endif
  enddo

  sum=0.
  nsum=0
  do i=ia,ib
     if(abs(i-ipkbest).ge.4) then
        sum=sum+ccfred(i)
        nsum=nsum+1
     endif
  enddo
  ave=sum/nsum
  snr=10.0*log10(sbest/ave) - 10.0*log10(2500.0/df3) + 2.0
  sync=sbest/ave - 1.0
  if(sync.lt.0.0) sync=0.0
  if(sync.gt.10.0) sync=10.0
  fpk=(ipkbest-1)*df3

  do i=1,184
     write(72,3007) i,ss(i,684)
3007 format(i3,f12.3)
  enddo
  call flush(72)

  return
end subroutine sync9
