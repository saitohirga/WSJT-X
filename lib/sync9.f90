subroutine sync9(ss,tstep,df3,ntol,nfqso,ccfred,ia,ib,ipkbest)

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
           if(k.ge.1) sum=sum + ss(k,i) - 0.5*(ss(k+2,i)+ss(k+4,i))
        enddo
        if(sum.gt.smax) then
           smax=sum
           ipk=i
        endif
     enddo
     ccfred(i)=smax                        !Best at this freq, over all lags
     if(smax.gt.sbest) then
        sbest=smax
        ipkbest=ipk
     endif
  enddo

  call pctile(ccfred(ia),ib-ia+1,50,xmed)
  if(xmed.le.0.0) xmed=1.0
  ccfred=ccfred/xmed

  return
end subroutine sync9
