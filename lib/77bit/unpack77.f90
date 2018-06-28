subroutine unpack77(c77,msg)

  parameter (NSEC=84)      !Number of ARRL Sections
  parameter (NUSCAN=65)    !Number of US states and Canadian provinces
  parameter (MAXGRID4=32400)
  integer*8 n58
  integer ntel(3)
  character*77 c77
  character*37 msg
  character*13 call_1,call_2,call_3
  character*11 c11
  character*3 crpt,cntx
  character*3 cmult(NUSCAN)
  character*6 cexch,grid6
  character*4 grid4,cserial
  character*3 csec(NSEC)
  character*38 c

  data c/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/'/
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
       "LB ","NU ","VT ","PEI","DC "/

  read(c77(72:77),'(2b3)') n3,i3
  msg=repeat(' ',37)
  if(i3.eq.0 .and. n3.eq.0) then
! 0.0  Free text
     call unpacktext77(c77(1:71),msg(1:13))
     msg(14:)='                        '
     msg=adjustl(msg)
     
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

  else if(i3.eq.0 .and. n3.eq.5) then
! 0.5   0123456789abcdef01                 71               71   Telemetry (18 hex)
     read(c77,1006) ntel
1006 format(b23,2b24)
     write(msg,1007) ntel
1007 format(3z6.6)
     do i=1,18
        if(msg(i:i).ne.'0') exit
        msg(i:i)=' '
     enddo
     msg=adjustl(msg)

  else if(i3.eq.1 .or. i3.eq.2) then
! Standard message (Type 1) or "/P" form of standard message for EU VHF contest (Type 2)
     !### Here and elsewhere, must enable rpt/RRR/RR73/73 in igrid4
     read(c77,1000) n28a,ipa,n28b,ipb,ir,igrid4,i3
1000 format(2(b28,b1),b1,b15,b3)
     call unpack28(n28a,call_1)
     call unpack28(n28b,call_2)
     if(call_1(1:3).eq.'CQ_') call_1(3:3)=' '
     i=index(call_1,' ')
     if(i.ge.4 .and. ipa.eq.1 .and. i3.eq.1) call_1(i:i+1)='/R'
     if(i.ge.4 .and. ipa.eq.1 .and. i3.eq.2) call_1(i:i+1)='/P'
     if(i.ge.4 .and. ipb.eq.1 .and. i3.eq.1) call_2(i:i+1)='/R'
     if(i.ge.4 .and. ipb.eq.1 .and. i3.eq.2) call_2(i:i+1)='/P'

     if(igrid4.le.MAXGRID4) then
        n=igrid4
        j1=n/(18*10*10)
        n=n-j1*18*10*10
        j2=n/(10*10)
        n=n-j2*10*10
        j3=n/10
        j4=n-j3*10
        grid4(1:1)=char(j1+ichar('A'))
        grid4(2:2)=char(j2+ichar('A'))
        grid4(3:3)=char(j3+ichar('0'))
        grid4(4:4)=char(j4+ichar('0'))
        if(ir.eq.0) msg=trim(call_1)//' '//trim(call_2)//' '//grid4
        if(ir.eq.1) msg=trim(call_1)//' '//trim(call_2)//' R '//grid4
     else
        irpt=igrid4-MAXGRID4
        if(irpt.eq.1) msg=trim(call_1)//' '//trim(call_2)
        if(irpt.eq.2) msg=trim(call_1)//' '//trim(call_2)//' RRR'
        if(irpt.eq.2) msg=trim(call_1)//' '//trim(call_2)//' RR73'
        if(irpt.eq.4) msg=trim(call_1)//' '//trim(call_2)//' 73'
        if(irpt.ge.5) then
           write(crpt,'(i3.2)') irpt-35
           if(crpt(1:1).eq.' ') crpt(1:1)='+'
           if(ir.eq.0) msg=trim(call_1)//' '//trim(call_2)//' '//crpt
           if(ir.eq.1) msg=trim(call_1)//' '//trim(call_2)//' R'//crpt
        endif
     endif

  else if(i3.eq.3) then
! Type 3: ARRL RTTY Contest
     read(c77,1040) itu,n28a,n28b,ir,irpt,nexch,i3
1040 format(b1,2b28.28,b1,b3.3,b13.13,b3.3)
     write(crpt,1042) irpt+2
1042 format('5',i1,'9')
     nserial=nexch
     imult=-1
     if(nexch.gt.8000) then
        imult=nexch-8000
        nserial=-1
     endif
     call unpack28(n28a,call_1)
     call unpack28(n28b,call_2)
     imult=0
     nserial=0
     if(nexch.gt.8000) imult=nexch-8000
     if(nexch.lt.8000) nserial=nexch
     
     if(imult.ge.1 .and.imult.le.NUSCAN) then
        if(itu.eq.0 .and. ir.eq.0) msg=trim(call_1)//' '//trim(call_2)//             &
             ' '//crpt//' '//cmult(imult)
        if(itu.eq.1 .and. ir.eq.0) msg='TU; '//trim(call_1)//' '//trim(call_2)//     &
             ' '//crpt//' '//cmult(imult)
        if(itu.eq.0 .and. ir.eq.1) msg=trim(call_1)//' '//trim(call_2)//             &
             ' R '//crpt//' '//cmult(imult)
        if(itu.eq.1 .and. ir.eq.1) msg='TU; '//trim(call_1)//' '//trim(call_2)//     &
             ' R '//crpt//' '//cmult(imult)
     else if(nserial.ge.1 .and. nserial.le.7999) then
        write(cserial,'(i4.4)') nserial
        if(itu.eq.0 .and. ir.eq.0) msg=trim(call_1)//' '//trim(call_2)//             &
             ' '//crpt//' '//cserial
        if(itu.eq.1 .and. ir.eq.0) msg='TU; '//trim(call_1)//' '//trim(call_2)//     &
             ' '//crpt//' '//cserial
        if(itu.eq.0 .and. ir.eq.1) msg=trim(call_1)//' '//trim(call_2)//             &
             ' R '//crpt//' '//cserial
        if(itu.eq.1 .and. ir.eq.1) msg='TU; '//trim(call_1)//' '//trim(call_2)//     &
             ' R '//crpt//' '//cserial
     endif
  else if(i3.eq.4) then
     read(c77,1050) n13,n58,iflip,nrpt
1050 format(b13,b58,b1,b2)
     do i=11,1,-1
        j=mod(n58,38)+1
        c11(i:i)=c(j:j)
        n58=n58/38
     enddo
     call hash13(n13,call_3,-1)
     if(iflip.eq.0) then
        call_1=call_3
        call_2=adjustl(c11)//'  '
     else
        call_1=adjustl(c11)//'  '
        call_2=call_3
     endif
     if(nrpt.eq.0) msg=trim(call_1)//' '//trim(call_2)
     if(nrpt.eq.1) msg=trim(call_1)//' '//trim(call_2)//' RRR'
     if(nrpt.eq.2) msg=trim(call_1)//' '//trim(call_2)//' RR73'
     if(nrpt.eq.3) msg=trim(call_1)//' '//trim(call_2)//' 73'
  endif

  return
end subroutine unpack77
