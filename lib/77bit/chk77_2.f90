subroutine chk77_2(nwords,w,i3,n3)
! Check Type 2 (ARRL RTTY contest exchange)
!ARRL RTTY   - US/Can: rpt state/prov      R 579 MA
!     	     - DX:     rpt serial          R 559 0013

  parameter (NUSCAN=65)    !Number of US states and Canadian provinces/territories
  character*13 w(19)
  character*6 bcall_1,bcall_2
  character*3 cmult(NUSCAN),mult
  character crpt*3
  logical ok1,ok2

  data cmult/                                                        &
       "AL ","AK ","AZ ","AR ","CA ","CO ","CT ","DE ","FL ","GA ",  &
       "HI ","ID ","IL ","IN ","IA ","KS ","KY ","LA ","ME ","MD ",  &
       "MA ","MI ","MN ","MS ","MO ","MT ","NE ","NV ","NH ","NJ ",  &
       "NM ","NY ","NC ","ND ","OH ","OK ","OR ","PA ","RI ","SC ",  &
       "SD ","TN ","TX ","UT ","VT ","VA ","WA ","WV ","WI ","WY ",  &
       "NB ","NS ","QC ","ON ","MB ","SK ","AB ","BC ","NWT","NF ",  &
       "LB ","NU ","VT ","PEI","DC "/

  if(nwords.eq.4 .or. nwords.eq.5 .or. nwords.eq.6) then
     i1=1
     if(trim(w(1)).eq.'TU;') i1=2
     call chkcall(w(i1),bcall_1,ok1)
     call chkcall(w(i1+1),bcall_2,ok2)
     crpt=w(nwords-1)(1:3)
     if(crpt(1:1).eq.'5' .and. crpt(2:2).ge.'2' .and. crpt(2:2).le.'9' .and.    &
          crpt(3:3).eq.'9') then
        n=-99
        read(w(nwords),*,err=1) n
1       i3=2
        n3=0
     endif
     do i=1,NUSCAN
        if(cmult(i).eq.w(nwords)) then
           mult=cmult(i)
           exit
        endif
     enddo
     if(mult.ne.'   ') then
        i3=2
        n3=0
     endif
  endif

  return
end subroutine chk77_2
