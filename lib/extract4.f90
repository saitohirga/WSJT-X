subroutine extract4(sym,nadd,ncount,decoded)

  real sym(207)
  character decoded*22, submode*1
  character*72 c72
  integer*1 symbol(207)
  integer*1 data1(13)                   !Decoded data (8-bit bytes)
  integer   data4a(9)                   !Decoded data (8-bit bytes)
  integer   data4(12)                   !Decoded data (6-bit bytes)
  integer mettab(0:255,0:1)             !Metric table
  logical first
  data first/.true./
  save first,mettab

  if(first) then
     call getmet24(mode,mettab)
     first=.false.
  endif

  do j=1,207
     r=sym(j) + 128.
     if(r.gt.255.0) r=255.0
     if(r.lt.0.0) r=0.0
     i4=nint(r)
     if(i4.gt.127) i4=i4-256
     symbol(j)=i4
  enddo

  nbits=72+31
  ndelta=50
  limit=100000
  ncycles=0
  ncount=-1
  decoded='                      '
  submode=' '

  call interleave24(symbol(2),-1)         !Remove the interleaving
  call fano232(symbol(2),nbits,mettab,ndelta,limit,data1,ncycles,metric,ncount)
  nlim=ncycles/nbits

  if(ncount.ge.0) then
     do i=1,9
        i4=data1(i)
        if(i4.lt.0) i4=i4+256
        data4a(i)=i4
     enddo
     write(c72,1100) (data4a(i),i=1,9)
1100 format(9b8.8)
     read(c72,1102) data4
1102 format(12b6)

     call unpackmsg(data4,decoded)
     submode=char(ichar('A')+ich-1)
     if(decoded(1:6).eq.'000AAA') then
        decoded='***WRONG MODE?***'
        ncount=-1
     endif
  endif

  return
end subroutine extract4
