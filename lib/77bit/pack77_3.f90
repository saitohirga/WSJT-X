subroutine pack77_3(nwords,w,i3,n3,c77)
! Check Type 2 (ARRL RTTY contest exchange)
!ARRL RTTY   - US/Can: rpt state/prov      R 579 MA
!     	     - DX:     rpt serial          R 559 0013

  parameter (NUSCAN=65)    !Number of US states and Canadian provinces/territories
  character*13 w(19)
  character*77 c77
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
        nserial=0
        read(w(nwords),*,err=1) nserial
!1       i3=3
!        n3=0
     endif
1    mult='   '
     imult=-1
     do i=1,NUSCAN
        if(cmult(i).eq.w(nwords)) then
           imult=i
           mult=cmult(i)
           exit
        endif
     enddo
     nexch=0
     if(nserial.gt.0) nexch=nserial
     if(imult.gt.0) nexch=8000+imult
     if(mult.ne.'   ' .or. nserial.gt.0) then
        i3=3
        n3=0
        itu=0
        if(trim(w(1)).eq.'TU;') itu=1
        call pack28(w(1+itu),n28a)
        call pack28(w(2+itu),n28b)
        ir=0
        if(w(3+itu)(1:2).eq.'R ') ir=1
        read(w(3+itu+ir),*) irpt
        irpt=(irpt-509)/10 - 2
! 3     TU; W9XYZ K1ABC R 579 MA             1 28 28 1 3 13       74   ARRL RTTY contest
! 3     TU; W9XYZ G8ABC R 559 0013           1 28 28 1 3 13       74   ARRL RTTY (DX)
        write(c77,1010) itu,n28a,n28b,ir,irpt,nexch,i3
1010    format(b1,2b28.28,b1,b3.3,b13.13,b3.3)
     endif
  endif

  return
end subroutine pack77_3
