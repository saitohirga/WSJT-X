subroutine sync9(ss,tstep,f0a,df3,fpk)

  parameter (NSMAX=22000)            !Max length of saved spectra
  real ss(184,NSMAX)

  integer ii0(16)
  integer ii(16)                     !Locations of sync half-symbols
  data ii/1,11,21,31,41,51,61,77,89,101,113,125,137,149,161,169/
  integer isync(85)                  !Sync vector for half-symbols
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/

  nz=1000.0/df3

  smax=0.
  lagmax=2.5/tstep + 0.9999
  do n=1,nz
     do lag=-lagmax,lagmax
        sum=0.
        do i=1,16
           k=ii(i) + lag
           if(k.ge.1) sum=sum + ss(k,n)
        enddo
        if(sum.gt.smax) then
           smax=sum
           npk=n
           lagpk=lag
        endif
     enddo
  enddo

  fpk=f0a + (npk-1)*df3

! This loop for tests only:
!  do lag=-lagmax,lagmax
!     sum=0.
!     do i=1,16
!        k=ii(i) + lag
!        if(k.ge.1) sum=sum + ss(k,npk)
!     enddo
!     write(71,3001) lag,sum
!3001 format(i8,f12.3)
!  enddo
!  flush(71)

  return
end subroutine sync9
