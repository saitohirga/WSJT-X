subroutine sync9(ss,tstep,df3,ntol,nfqso,sync,snr,fpk,ccfred)

  parameter (NSMAX=22000)            !Max length of saved spectra
  real ss(184,NSMAX)
  real ccfred(NSMAX)

  integer ii(16)                     !Locations of sync half-symbols
  data ii/1,11,21,31,41,51,61,77,89,101,113,125,137,149,161,169/
  integer isync(85)                  !Sync vector for half-symbols
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/

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
           k=ii(j) + lag
           if(k.ge.1) sum=sum + ss(k,i)
        enddo
        if(sum.gt.smax) then
           smax=sum
           ipk=i
           lagpk=lag
        endif
     enddo
     if(smax.gt.sbest) then
        sbest=smax
        ipkbest=ipk
!        lagpkbest=lagpk
     endif
     ccfred(i)=smax
  enddo

  sum=0.
  nsum=0
  do i=ia,ib
     if(abs(i-ipkbest).ge.2) then
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

  return
end subroutine sync9
