subroutine sync9(ss,tstep,f0a,df3,ntol,nfqso,sync,fpk,ccfred)

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

  ia=1
  ib=min(1000,nint(1000.0/df3))

  if(ntol.lt.1000) then
     ia=nint((nfqso-1000-ntol)/df3)
     ib=nint((nfqso-1000+ntol)/df3)
     if(ia.lt.1) ia=1
     if(ib.gt.NSMAX) ib=NSMAX
  endif
!  print*,ia,ib,f0a,df3,ntol,nfqso,df3*ia+1000,df3*ib+1000

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
        lagpkbest=lagpk
     endif
     ccfred(i)=smax
  enddo

  fpk=f0a + (ipkbest-1)*df3
  sync=sbest

  return
end subroutine sync9
