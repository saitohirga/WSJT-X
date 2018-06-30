program t3
  character*3 csec
  character*70 line
  logical eof

  eof=.false.
  j=1
  do i=1,83
     read(*,1001,end=1) csec
1001 format(a3)
     go to 2
1    eof=.true.
2     line(j:j+5)='"'//csec//'",'
     j=j+6
     if(j.gt.60 .or. i.eq.83 .or.eof) then
        line(j:j+2)='  &'
        line(j+3:)='                                                        '
        write(*,1010) line
1010    format(a70)
        j=1
     endif
     if(eof) go to 999
  enddo
  
999 end program t3
