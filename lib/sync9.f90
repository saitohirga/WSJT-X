subroutine sync9(ss,nzhsym,tstep,df3,nfa,nfb,ccfred,ia,ib,ipkbest)

  parameter (NSMAX=22000)            !Max length of saved spectra
  real ss(184,NSMAX)
  real ccfred(NSMAX)
  include 'jt9sync.f90'

  ipk=0
  ipkbest=0
  ia=max(1,nint((nfa-1000)/df3))
  ib=min(NSMAX,nint((nfb-1000)/df3))

  sbest=0.
  lag1=-(2.5/tstep + 0.9999)
  lag2=5.0/tstep + 0.9999
  ccfred=0.

  do i=ia,ib                         !Loop over freq range
     smax=0.
     do lag=lag1,lag2                !DT = 2.5 to 5.0 s
        sum=0.
        do j=1,16                    !Sum over 16 sync symbols
           k=ii2(j) + lag
           kaa=ka(j)+lag
           kbb=kb(j)+lag
           if(k.ge.1 .and. k.le.nzhsym) sum=sum + ss(k,i) -      &
                0.5*(ss(kaa,i)+ss(kbb,i))
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
