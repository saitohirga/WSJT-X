subroutine hash(string,len,ihash)

  parameter (MASK15=32767)
  character*(*) string
  integer*1 ic(12)

     do i=1,len
        ic(i)=ichar(string(i:i))
     enddo
     i=nhash(ic,len,146)
     ihash=iand(i,MASK15)

!     print*,'C',ihash,len,string
  return
end subroutine hash
