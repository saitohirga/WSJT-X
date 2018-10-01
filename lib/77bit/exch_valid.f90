logical*1 function exch_valid(ntype,exch)
  
  parameter (NSEC=84)      !Number of ARRL Sections
  parameter (NUSCAN=65)    !Number of US states and Canadian provinces

  character*(*) exch
  character*3 c3
  character*3 cmult(NUSCAN)
  character*3 csec(NSEC)

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
  data cmult/                                                        &
       "AL ","AK ","AZ ","AR ","CA ","CO ","CT ","DE ","FL ","GA ",  &
       "HI ","ID ","IL ","IN ","IA ","KS ","KY ","LA ","ME ","MD ",  &
       "MA ","MI ","MN ","MS ","MO ","MT ","NE ","NV ","NH ","NJ ",  &
       "NM ","NY ","NC ","ND ","OH ","OK ","OR ","PA ","RI ","SC ",  &
       "SD ","TN ","TX ","UT ","VT ","VA ","WA ","WV ","WI ","WY ",  &
       "NB ","NS ","QC ","ON ","MB ","SK ","AB ","BC ","NWT","NF ",  &
       "LB ","NU ","YT ","PEI","DC "/

  exch_valid=.false.
  n=len(trim(exch))
  if(ntype.ne.3 .and. ntype.ne.4) go to 900
  if(ntype.eq.3 .and. (n.lt.2 .or. n.gt.7)) go to 900
  if(ntype.eq.4 .and. (n.lt.2 .or. n.gt.3)) go to 900
  
  if(ntype.eq.3) then                   !Field Day
     i1=index(exch,' ')
     if(i1.lt.3) go to 900
     read(exch(1:i1-2),*,err=900) ntx
     if(ntx.lt.1 .or. ntx.gt.32) go to 900
     if(exch(i1-1:i1-1).lt.'A' .or. exch(i1-1:i1-1).gt.'F') go to 900
     c3=exch(i1+1:)//'   '
     do i=1,NSEC
        if(csec(i).eq.c3) then
           exch_valid=.true.
           go to 900
        endif
     enddo
     
  else if(ntype.eq.4) then              !RTTY Roundup
     c3=exch//' '
     do i=1,NUSCAN
        if(cmult(i).eq.c3) then
           exch_valid=.true.
           go to 900
        endif
     enddo
  endif

900 return
end function exch_valid
