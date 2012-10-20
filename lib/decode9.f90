subroutine decode9(i1SoftSymbols,msg)

! Decoder for JT9
! Input:   i1SoftSymbols(207) - Single-bit soft symbols
! Output:  msg                - decoded message (blank if erasure)

  character*22 msg
  integer*4 i4DecodedBytes(9)
  integer*4 i4Decoded6BitWords(12)
  integer*1 i1DecodedBytes(13)   !72 bits and zero tail as 8-bit bytes
  integer*1 i1SoftSymbols(207)
  integer*1 i1DecodedBits(72)

  integer*1 i1
  logical first
  integer*4 mettab(0:255,0:1)
  equivalence (i1,i4)
  data first/.true./
  save

  if(first) then
! Get the metric table
!     bias=0.37                         !To be optimized, in decoder program
     bias=0.0                           !Seems better, in jt9.exe ???
     scale=10                           !  ... ditto ...
     open(19,file='met8.21',status='old')
     do i=0,255
        read(19,*) x00,x0,x1
        mettab(i,0)=nint(scale*(x0-bias))
        mettab(i,1)=nint(scale*(x1-bias))    !### Check range, etc.  ###
     enddo
     close(19)
     first=.false.
  endif

  msg='                      '
  nbits=72
  ndelta=17
  limit=10000
  call fano232(i1SoftSymbols,nbits+31,mettab,ndelta,limit,i1DecodedBytes,   &
       ncycles,metric,ierr)

  if(ncycles.lt.(nbits*limit)) then
     nbytes=(nbits+7)/8
     do i=1,nbytes
        n=i1DecodedBytes(i)
        i4DecodedBytes(i)=iand(n,255)
     enddo
     call unpackbits(i4DecodedBytes,nbytes,8,i1DecodedBits)
     call packbits(i1DecodedBits,12,6,i4Decoded6BitWords)
     call unpackmsg(i4Decoded6BitWords,msg)                !Unpack decoded msg
  endif

  return
end subroutine decode9
