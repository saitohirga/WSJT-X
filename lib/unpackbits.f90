subroutine unpackbits(sym,nsymd,m0,dbits)

! Unpack bits from sym() into dbits(), one bit per byte.
! NB: nsymd is the number of input words, and m0 their length.
! there will be m0*nsymd output bytes, each 0 or 1.

  integer sym(nsymd)
  integer*1 dbits(*)

  k=0
  do i=1,nsymd
     mask=ishft(1,m0-1)
     do j=1,m0
        k=k+1
        dbits(k)=0
        if(iand(mask,sym(i)).ne.0) dbits(k)=1
        mask=ishft(mask,-1)
     enddo
  enddo

  return
end subroutine unpackbits
