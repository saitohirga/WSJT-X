subroutine pack28(c13,n28)

! Pack a special token, a 24-bit hash code, or a valid base call into a 28-bit
! integer.

  parameter (NTOKENS=4874084,MAX24=16777216)
  integer nc(6)
  logical is_digit,is_letter
  character*13 c13
  character*6 callsign
  character*1 c
  character*4 c4
  character*37 a1
  character*36 a2
  character*10 a3
  character*27 a4
  data a1/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data a2/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data a3/'0123456789'/
  data a4/' ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
  data nc/37,36,19,27,27,27/
  
  is_digit(c)=c.ge.'0' .and. c.le.'9'
  is_letter(c)=c.ge.'A' .and. c.le.'Z'

  n28=-1
! Work-around for Swaziland prefix:
  if(c13(1:4).eq.'3DA0') callsign='3D0'//c13(5:7)
! Work-around for Guinea prefixes:
  if(c13(1:2).eq.'3X' .and. c13(3:3).ge.'A' .and.          &
       c13(3:3).le.'Z') callsign='Q'//c13(3:6)

! Check for special tokens first
  if(c13(1:3).eq.'DE ') then
     n28=0
     go to 900
  endif
  
  if(c13(1:4).eq.'QRZ ') then
     n28=1
     go to 900
  endif

  if(c13(1:3).eq.'CQ ') then
     n28=2
     go to 900
  endif

  if(c13(1:3).eq.'CQ_') then
     n=len(trim(c13))
     if(n.ge.4 .and. n.le.7) then
        nlet=0
        nnum=0
        do i=4,n
           c=c13(i:i)
           if(c.ge.'A' .and. c.le.'Z') nlet=nlet+1
           if(c.ge.'0' .and. c.le.'9') nnum=nnum+1
        enddo
        if(nnum.eq.3 .and. nlet.eq.0) then
           read(c13(4:3+nnum),*) nqsy
           n28=3+nqsy
           go to 900
        endif
        if(nlet.ge.1 .and. nlet.le.4 .and. nnum.eq.0) then
           c4=c13(4:n)//'   '
           c4=adjustr(c4)
           m=0
           do i=1,4
              j=0
              c=c4(i:i)
              if(c.ge.'A' .and. c.le.'Z') j=ichar(c)-ichar('A')+1
              m=27*m + j
           enddo
           n28=3+1000+m
           go to 900
        endif
     endif
  endif

! Check for <...> callsign
  if(c13(1:1).eq.'<')then
     n24=ihashcall(c13,24)
     call hash24(n24,c13,1)     !Save (key,value) in hash table
     n28=NTOKENS + n24
     go to 900
  endif

! Check for standard callsign
  iarea=-1
  n=len(trim(c13))
  do i=n,2,-1
     if(is_digit(c13(i:i))) exit
  enddo
  iarea=i
  npdig=0
  nplet=0
  do i=1,iarea-1
     if(is_digit(c13(i:i))) npdig=npdig+1
     if(is_letter(c13(i:i))) nplet=nplet+1
  enddo
  nslet=0
  do i=iarea+1,n
     if(is_letter(c13(i:i))) nslet=nslet+1
  enddo
  if(iarea.lt.2 .or. iarea.gt.3 .or. nplet.eq.0 .or.       &
       npdig.ge.iarea-1 .or. nslet.gt.3) then
! Treat this as a nonstandard callsign: compute its 24-bit hash
     n24=ihashcall(c13,24)
     call hash24(n24,c13,1)     !Save (key,value) in hash table
     n28=NTOKENS + n24
     go to 900
  endif
  
  n=len(trim(c13))
! This is a standard callsign
  if(iarea.eq.2) callsign=' '//c13(1:5)
  if(iarea.eq.3) callsign=c13(1:6)
  i1=index(a1,callsign(1:1))-1
  i2=index(a2,callsign(2:2))-1
  i3=index(a3,callsign(3:3))-1
  i4=index(a4,callsign(4:4))-1
  i5=index(a4,callsign(5:5))-1
  i6=index(a4,callsign(6:6))-1
  n28=36*10*27*27*27*i1 + 10*27*27*27*i2 + 27*27*27*i3 + 27*27*i4 + &
       27*i5 + i6
  n28=n28 + NTOKENS + MAX24

900 return
end subroutine pack28
