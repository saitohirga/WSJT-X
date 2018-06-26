subroutine chk77_03(nwords,w,i3,n3)
! Check 0.3 and 0.4 (ARRL Field Day exchange)

  parameter (NSEC=83)      !Number of ARRL Sections
  character*13 w(19)
  character*6 bcall_1,bcall_2
  character*3 csec(NSEC),section
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
       "WV ","WWA","WY "/
  
  call chkcall(w(1),bcall_1,ok1)
  call chkcall(w(2),bcall_2,ok2)
  
  if(nwords.eq.4 .or. nwords.eq.5) then
     n=-1
     j=len(trim(w(nwords-1)))-1
     if(j.ge.2) read(w(nwords-1)(1:j),*,err=4) n      !Number of transmitters
4    m=len(trim(w(nwords)))                           !Length of section abbreviation
     if(ok1 .and. ok2 .and. n.ge.1 .and. n.le.32 .and. (m.eq.2 .or. m.eq.3)) then
        section='   '
        do i=1,NSEC
           if(csec(i).eq.w(nwords)) then
              section=csec(i)
              exit
           endif
        enddo
        if(section.ne.'   ') then
           i3=0
           if(n.ge.1 .and. n.le.16) n3=3    !Type 0.3 ARRL Field Day
           if(n.ge.17 .and. n.le.32) n3=4   !Type 0.4 ARRL Field Day
        endif
     endif
  endif

  return
end subroutine chk77_03
