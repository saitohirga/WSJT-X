subroutine unpack77(c77,msg)

  parameter (NSEC=84)      !Number of ARRL Sections
  character*77 c77
  character*37 msg
  character*13 call_1,call_2,call_3
  character*3 crpt,cntx
  character*6 cexch,grid6
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

  read(c77(72:77),'(2b3)') n3,i3
  msg=repeat(' ',37)
  if(i3.eq.0 .and. n3.eq.0) then
! 0.0  Free text
     call unpacktext77(c77(1:71),msg(1:13))
     msg(14:)='                        '
     
  else if(i3.eq.0 .and. n3.eq.1) then
! 0.1  K1ABC RR73; W9XYZ <KH1/KH7Z> -11   28 28 10 5       71   DXpedition Mode
     read(c77,1010) n28a,n28b,n10,n5
1010 format(2b28,b10,b5)
     irpt=2*n5 - 30
     write(crpt,1012) irpt
1012 format(i3.2)
     if(irpt.ge.0) crpt(1:1)='+'
     call unpack28(n28a,call_1)
     call unpack28(n28b,call_2)
     call hash10(n10,call_3,-1)
     msg=trim(call_1)//' RR73; '//trim(call_2)//' '//trim(call_3)//' '//crpt
     
  else if(i3.eq.0 .and. n3.eq.2) then
! 0.2  PA3XYZ/P R 590003 IO91NP           28 1 1 3 12 25   70   EU VHF contest
     read(c77,1020) n28a,ip,ir,irpt,iserial,igrid6
1020 format(b28,2b1,b3,b12,b25)
     call unpack28(n28a,call_1)
     nrs=52+irpt
     if(ip.eq.1) call_1=trim(call_1)//'/P'//'        '
     write(cexch,1022) nrs,iserial
1022 format(i2,i4.4)
     n=igrid6
     j1=n/(18*10*10*24*24)
     n=n-j1*18*10*10*24*24
     j2=n/(10*10*24*24)
     n=n-j2*10*10*24*24
     j3=n/(10*24*24)
     n=n-j3*10*24*24
     j4=n/(24*24)
     n=n-j4*24*24
     j5=n/24
     j6=n-j5*24
     grid6(1:1)=char(j1+ichar('A'))
     grid6(2:2)=char(j2+ichar('A'))
     grid6(3:3)=char(j3+ichar('0'))
     grid6(4:4)=char(j4+ichar('0'))
     grid6(5:5)=char(j5+ichar('A'))
     grid6(6:6)=char(j6+ichar('A'))  
     msg=trim(call_1)//' '//cexch//' '//grid6
     if(ir.eq.1) msg=trim(call_1)//' R '//cexch//' '//grid6

  else if(i3.eq.0 .and. (n3.eq.3 .or. n3.eq.4)) then
! 0.3   WA9XYZ KA1ABC R 16A EMA            28 28 1 4 3 7    71   ARRL Field Day
! 0.4   WA9XYZ KA1ABC R 32A EMA            28 28 1 4 3 7    71   ARRL Field Day
     read(c77,1030) n28a,n28b,ir,intx,nclass,isec
1030 format(2b28,b1,b4,b3,b7)
     call unpack28(n28a,call_1)
     call unpack28(n28b,call_2)
     ntx=intx+1
     if(n3.eq.4) ntx=ntx+16
     write(cntx(1:2),1032) ntx
1032 format(i2)
     cntx(3:3)=char(ichar('A')+nclass)
     if(ir.eq.0 .and. ntx.lt.10) msg=trim(call_1)//' '//trim(call_2)//     &
          cntx//' '//csec(isec)
     if(ir.eq.1 .and. ntx.lt.10) msg=trim(call_1)//' '//trim(call_2)//     &
          ' R'//cntx//' '//csec(isec)
     if(ir.eq.0 .and. ntx.ge.10) msg=trim(call_1)//' '//trim(call_2)//     &
          ' '//cntx//' '//csec(isec)
     if(ir.eq.1 .and. ntx.ge.10) msg=trim(call_1)//' '//trim(call_2)//     &
          ' R '//cntx//' '//csec(isec)
  endif

  return
end subroutine unpack77
