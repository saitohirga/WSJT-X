subroutine parse77(msg,i3,n3)

  use packjt
  parameter (NSEC=83)      !Number of ARRL Sections
  parameter (NUSCAN=65)    !Number of US states and Canadian provinces/territories
  character*37 msg
  character*22 msg22
  character*13 w(19),c13
  character*13 call_1,call_2
  character*6 bcall_1,bcall_2,grid6
  character*4 grid4
  character crpt*3,crrpt*4
  character*77 c77bit
  character*1 c,c0
  character*3 csec(NSEC),cmult(NUSCAN),section,mult
  logical ok1,ok2,text1,text2
  logical is_grid4,is_grid6

  data csec/                                                         &
       "AB ","AK ","AL ","AR ","AZ ","BC ","CO ","CT ","DE ","EB ",  &       
       "EMA","ENY","EPA","EWA","GA ","GTA","IA ","ID ","IL ","IN ",  &       
       "KS ","KY ","LA ","LAX","MAR","MB ","MDC","ME ","MI ","MN ",  &       
       "MO ","MS ","MT ","NC ","ND ","NE ","NFL","NH ","NL ","NLI",  &       
       "NM ","NNJ","NNY","NT ","NTX","NV ","OH ","OK ","ONE","ONN",  &       
       "ONS","OR ","ORG","PAC","PR ","QC ","RI ","SB ","SC ","SCV",  &       
       "SD ","SDG","SF ","SFL","SJV","SK ","SNJ","STX","SV ","TN ",  &       
       "UT ","VA ","VI ","VT ","WCF","WI ","WMA","WNY","WPA","WTX",  &       
       "WV ","WWA","WY "/
  
  data cmult/                                                        &
       "AL ","AK ","AZ ","AR ","CA ","CO ","CT ","DE ","FL ","GA ",  &
       "HI ","ID ","IL ","IN ","IA ","KS ","KY ","LA ","ME ","MD ",  &
       "MA ","MI ","MN ","MS ","MO ","MT ","NE ","NV ","NH ","NJ ",  &
       "NM ","NY ","NC ","ND ","OH ","OK ","OR ","PA ","RI ","SC ",  &
       "SD ","TN ","TX ","UT ","VT ","VA ","WA ","WV ","WI ","WY ",  &
       "NB ","NS ","QC ","ON ","MB ","SK ","AB ","BC ","NWT","NF ",  &
       "LB ","NU ","VT ","PEI","DC "/

  is_grid4(grid4)=len(trim(grid4)).eq.4 .and.                        &
       grid4(1:1).ge.'A' .and. grid4(1:1).le.'R' .and.               &
       grid4(2:2).ge.'A' .and. grid4(2:2).le.'R' .and.               &
       grid4(3:3).ge.'0' .and. grid4(3:3).le.'9' .and.               &
       grid4(4:4).ge.'0' .and. grid4(4:4).le.'9'
  
  is_grid6(grid6)=len(trim(grid6)).eq.6 .and.                        &
       grid6(1:1).ge.'A' .and. grid6(1:1).le.'R' .and.               &
       grid6(2:2).ge.'A' .and. grid6(2:2).le.'R' .and.               &
       grid6(3:3).ge.'0' .and. grid6(3:3).le.'9' .and.               &
       grid6(4:4).ge.'0' .and. grid6(4:4).le.'9' .and.               &
       grid6(5:5).ge.'A' .and. grid6(5:5).le.'X' .and.               &
       grid6(6:6).ge.'A' .and. grid6(6:6).le.'X'

  iz=len(trim(msg))
! Convert to upper case; parse into words.
  j=0
  k=0
  n=0
  c0=' '
  w='             '
  do i=1,iz
     c=msg(i:i)                                 !Single character
     if(c.eq.' ' .and. c0.eq.' ') cycle         !Skip over leading or repeated blanks
     if(c.ne.' ' .and. c0.eq.' ') then
        k=k+1                                   !New word
        n=0
     endif
     j=j+1                                      !Index in msg
     n=n+1                                      !Index in word
     msg(j:j)=c
     if(c.ge.'a' .and. c.le.'z') msg(j:j)=char(ichar(c)-32)  !Force upper case
     w(k)(n:n)=c                                !Copy character c into word
     c0=c
  enddo
  iz=j                                          !Message length
  nw=k                                          !Number of words in msg
  msg(iz+1:)='                                     '

! Check 0.1 (DXpedition mode)
  i3=0
  n3=0
  i0=index(msg," RR73; ")
  call chkcall(w(1)(1:12),bcall_1,ok1)
  call chkcall(w(3)(1:12),bcall_2,ok2)

  if(i0.ge.4 .and. i0.le.7 .and. nw.eq.5 .and. ok1 .and. ok2) then
     i0=0
     n3=1                             !Type 0.1: DXpedition mode
     go to 900
  endif

! Check 0.2 (EU VHF contest exchange)
  if(nw.eq.3 .or. nw.eq.4) then
     n=-1
     if(nw.ge.2) read(w(nw-1),*,err=2) n
2    if(ok1 .and. n.ge.520001 .and. n.le.594095 .and. is_grid6(w(nw)(1:6))) then
        i3=0
        n3=2                          !Type 0.2: EU VHF+ Contest
        go to 900
     endif
  endif

  call chkcall(w(2)(1:12),bcall_2,ok2)

! Check 0.3 and 0.4 (ARRL Field Day exchange)
  if(nw.eq.4 .or. nw.eq.5) then
     n=-1
     j=len(trim(w(nw-1)))-1
     if(j.ge.2) read(w(nw-1)(1:j),*,err=4) n      !Number of transmitters
4    m=len(trim(w(nw)))                           !Length of section abbreviation
     if(ok1 .and. ok2 .and. n.ge.1 .and. n.le.32 .and. (m.eq.2 .or. m.eq.3)) then
        section='   '
        do i=1,NSEC
           if(csec(i).eq.w(nw)) then
              section=csec(i)
              exit
           endif
        enddo
        if(section.ne.'   ') then
           i3=0
           if(n.ge.1 .and. n.le.16) n3=3    !Type 0.3 ARRL Field Day
           if(n.ge.17 .and. n.le.32) n3=4   !Type 0.4 ARRL Field Day
           go to 900
        endif
     endif
  endif

  n3=0
! Check Type 1 (Standard 77-bit message) and Type 4 (ditto, with a "/P" call)
  if(nw.eq.3 .or. nw.eq.4) then
     if(ok1 .and. ok2 .and. is_grid4(w(nw)(1:4))) then
        if(nw.eq.3 .or. (nw.eq.4 .and. w(3)(1:2).eq.'R ')) then
           i3=1                          !Type 1: Standard message
           if(index(w(1),'/P').ge.4 .or. index(w(2),'/P').ge.4) i3=4
           go to 900
        endif
     endif
  endif

! Check Type 2 (ARRL RTTY contest exchange)
  if(nw.eq.4 .or. nw.eq.5 .or. nw.eq.6) then
     i1=1
     if(trim(w(1)).eq.'TU;') i1=2
     call chkcall(w(i1),bcall_1,ok1)
     call chkcall(w(i1+1),bcall_2,ok2)
     crpt=w(nw-1)(1:3)
     if(crpt(1:1).eq.'5' .and. crpt(2:2).ge.'2' .and. crpt(2:2).le.'9' .and.    &
          crpt(3:3).eq.'9') then
        i3=2
        n3=0
        go to 900
     endif
  endif

! Check Type 3 (One nonstandard call and one hashed call)
  if(nw.eq.3) then
     call_1=w(1)
     if(call_1(1:1).eq.'<') call_1=w(1)(2:len(trim(w(1)))-1)
     call_2=w(2)
     if(call_2(1:1).eq.'<') call_2=w(2)(2:len(trim(w(2)))-1)
     call chkcall(call_1,bcall_1,ok1)
     call chkcall(call_2,bcall_2,ok2)
     crrpt=w(nw)(1:4)
     i1=1
     if(crrpt(1:1).eq.'R') i1=2
     n=-99
     read(crrpt(i1:),*,err=6) n
6     if(ok1 .and. ok2 .and. n.ne.-99) then
        i3=3
        n3=0
        go to 900
     endif
  endif

! It's free text
  i3=0
  n3=0
  msg(iz+1:)='                                     '
  call packtext(msg(1:22),nc1,nc2,ng)
  write(c77bit,1100) nc1,nc2,ng,i3,n3           !c77bit is the 77-bit message
1100 format(2b28.28,b15.15,b3.3,b3.3)
  print*,c77bit
  read(c77bit,1102) nc1,nc2,ng,i3,n3
1102 format(2b28,b15,2b3)
  call unpacktext(nc1,nc2,ng,msg22)
  write(*,3002) nc1,nc2,ng,i3,n3,msg22(1:13)
3002 format(2i12,i8,2i3,2x,a13)
  
900 continue

  call packcall(bcall_1,nc1,text1)
  call packcall(bcall_2,nc2,text2)
  if(.not.text1) write(*,3001) bcall_1,nc1
  if(.not.text2) write(*,3001) bcall_2,nc2
3001 format(50x,a6,i12)
  
  return
end subroutine parse77
