subroutine packbits(dbits,nsymd,m0,sym)

! Pack 0s and 1s from dbits() into sym() with m0 bits per word.
! NB: nsymd is the number of packed output words.

  integer sym(nsymd)
  integer*1 dbits(*)

  k=0
  do i=1,nsymd
     n=0
     do j=1,m0
        k=k+1
        m=dbits(k)
        n=ior(ishft(n,1),m)
     enddo
     sym(i)=n
  enddo

  return
end subroutine packbits
