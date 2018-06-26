subroutine unpack77(c77,msg)

  character*77 c77
  character*37 msg
  character*13 c13

  read(c77(72:77),'(2b3)') n3,i3
  msg=repeat(' ',37)
  if(i3.eq.0 .and. n3.eq.0) then
     call unpacktext77(c77(1:71),msg(1:13))
     msg(14:)='                        '
  else if(i3.eq.0 .and. n3.eq.1) then
     read(c77,1010) n28a,n28b,n10,n5
1010 format(2b28,b10,b5)
     print*,'C1:',n28a,n28b,n10,n5,n3,i3
     call unpack28(n28a,c13)
     print*,'C2: ',c13
     call unpack28(n28b,c13)
     print*,'C3: ',c13

  endif

  return
end subroutine unpack77
