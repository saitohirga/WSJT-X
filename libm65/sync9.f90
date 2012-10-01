subroutine sync9(ss,df3)

  parameter (NSMAX=22000)            !Max length of saved spectra
  real ss(184,NSMAX)

  integer ii(16)
  integer isync(85)             !Sync vector
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/
  
  ii=0
  k=0
  do i=1,85
     if(isync(i).eq.1) then
        k=k+1
        ii(k)=2*i-1
     endif
  enddo

  nz=1000.0/df3

  smax=0.
  lagmax=10
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
        endif
     enddo
  enddo

  print*,'npk:',npk
  n=npk
  do lag=-lagmax,lagmax
     sum=0.
     do i=1,16
        k=ii(i) + lag
        if(k.ge.1) sum=sum + ss(k,n)
     enddo
     write(*,3000) lag,sum
3000 format(i3,f12.3)
  enddo

  return
end subroutine sync9
