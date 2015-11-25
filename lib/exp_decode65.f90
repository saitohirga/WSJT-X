subroutine exp_decode65(mrsym,mrprob,mr2sym,nexp_decode,nhard,nsoft,nbest,  &
     correct)

  use packjt
  use prog_args
  parameter (NMAX=10000)
  integer*1 sym1(0:62,NMAX)
  integer mrsym(0:62),mr2sym(0:62),mrprob(0:62)
  integer dgen(12),sym(0:62),sym_rev(0:62)
  integer test(0:62)  
  integer correct(0:62)
  character*6 mycall,hiscall(NMAX)
  character*4 hisgrid(NMAX)
  character callsign*12,grid*4
  character*180 line
  character ceme*3,msg*22
  logical*1 eme(NMAX)
  logical first
  data first/.true./
  save first,sym1,nused

!###
  mycall='VK7MO'                   !### TEMPORARY ###
  if(first) then
     neme=1

     open(23,file=trim(data_dir)//'/CALL3.TXT',status='unknown')
     icall=0
     j=0
     do i=1,NMAX
        read(23,1002,end=10) line
1002    format(a80)
        if(line(1:4).eq.'ZZZZ') cycle
        if(line(1:2).eq.'//') cycle
        i1=index(line,',')
        if(i1.lt.4) cycle
        i2=index(line(i1+1:),',')
        if(i2.lt.5) cycle
        i2=i2+i1
        i3=index(line(i2+1:),',')
        if(i3.lt.1) i3=index(line(i2+1:),' ')
        i3=i2+i3
        callsign=line(1:i1-1)
        grid=line(i1+1:i2-1)
        ceme=line(i2+1:i3-1)
        eme(i)=ceme.eq.'EME'
        if(neme.eq.1 .and. (.not.eme(i))) cycle
        j=j+1
        hiscall(j)=callsign(1:6)               !### Fix for compound callsigns!
        hisgrid(j)=grid
     enddo
10   ncalls=j
     close(23)

     j=0
     do i=1,ncalls
        if(neme.eq.1 .and. (.not.eme(i))) cycle
        j=j+1
        msg=mycall//' '//hiscall(i)//' '//hisgrid(i)
        call fmtmsg(msg,iz)
        call packmsg(msg,dgen,itype)            !Pack message into 72 bits
        call rs_encode(dgen,sym_rev)            !RS encode
        sym(0:62)=sym_rev(62:0:-1)
        sym1(0:62,j)=sym
     enddo
     nused=j
     first=.false.
  endif
!###

  nbest=999999
  do j=1,nused
     test=sym1(0:62,j)
     nh=0
     ns=0
     do i=0,62
        k=62-i
        if(mrsym(k).ne.test(i)) then
           nh=nh+1
           if(mr2sym(k).ne.test(i)) ns=ns+mrprob(k)
        endif
     enddo
     ns=63*ns/sum(mrprob)

     if(nh+ns.lt.nbest) then
        nhard=nh
        nsoft=ns
        nbest=nhard+nsoft
        ncandidates=0
        ntry=0
        correct=test
     endif
  enddo

  return
end subroutine exp_decode65
