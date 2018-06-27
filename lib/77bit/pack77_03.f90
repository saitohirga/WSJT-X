subroutine pack77_03(nwords,w,i3,n3,c77)
! Check 0.3 and 0.4 (ARRL Field Day exchange)

  parameter (NSEC=84)      !Number of ARRL Sections
  character*13 w(19)
  character*77 c77
  character*6 bcall_1,bcall_2
  character*3 csec(NSEC)
  logical ok1,ok2
  data csec/                                                         &
       "AB ","AK ","AL ","AR ","AZ ","BC ","CO ","CT ","DE ","EB ",  &       
       "EMA","ENY","EPA","EWA","GA ","GTA","IA ","ID ","IL ","IN ",  &       
       "KS ","KY ","LA ","LAX","MAR","MB ","MDC","ME ","MI ","MN ",  &       
       "MO ","MS ","MT ","NC ","ND ","NE ","NFL","NH ","NL ","NLI",  &       
       "NM ","NNJ","NNY","NT ","NTX","NV ","OH ","OK ","ONE","ONN",  &       
       "ONS","OR ","ORG","PAC","PR ","QC ","RI ","SB ","SC ","SCV",  &       
       "SD ","SDG","SF ","SFL","SJV","SK ","SNJ","STX","SV ","TN ",  &       
       "UT ","VA ","VI ","VT ","WCF","WI ","WMA","WNY","WPA","WTX",  &       
       "WV ","WWA","WY ","DX "/

  if(nwords.lt.4 .or. nwords.gt.5) return  
  call chkcall(w(1),bcall_1,ok1)
  call chkcall(w(2),bcall_2,ok2)
  if(.not.ok1 .or. .not.ok2) return
  isec=-1
  do i=1,NSEC
     if(csec(i).eq.w(nwords)) then
        isec=i
        exit
     endif
  enddo
  if(isec.eq.-1) return
  if(nwords.eq.5 .and. trim(w(3)).ne.'R') return
  
  ntx=-1
  j=len(trim(w(nwords-1)))-1
  read(w(nwords-1)(1:j),*,err=1) ntx                !Number of transmitters
1 if(ntx.lt.1 .or. ntx.gt.32) return
  nclass=ichar(w(nwords-1)(j+1:j+1))-ichar('A')
  
  m=len(trim(w(nwords)))                            !Length of section abbreviation
  if(m.lt.2 .or. m.gt.3) return

! 0.3   WA9XYZ KA1ABC R 16A EMA            28 28 1 4 3 7    71   ARRL Field Day
! 0.4   WA9XYZ KA1ABC R 32A EMA            28 28 1 4 3 7    71   ARRL Field Day
  
  i3=0
  n3=3                                 !Type 0.3 ARRL Field Day
  intx=ntx-1
  if(intx.ge.16) then
     n3=4                              !Type 0.4 ARRL Field Day
     intx=ntx-17
  endif
  call pack28(w(1),n28a)
  call pack28(w(2),n28b)
  ir=0
  if(w(3)(1:2).eq.'R ') ir=1
  write(c77,1010) n28a,n28b,ir,intx,nclass,isec,n3,i3
1010 format(2b28.28,b1,b4.4,b3.3,b7.7,2b3.3)

  return
end subroutine pack77_03
