subroutine exp_decode65(s3,mrs,mrs2,mrsym,mr2sym,mrprob,mode65,flip,   &
     mycall,hiscall0,hisgrid0,nexp_decode,qual,decoded)

  use packjt
  use prog_args
  parameter (NMAX=10000)
  real s3(64,63)
  integer*1 sym1(0:62,NMAX)
  integer*1 sym2(0:62,NMAX)
  integer mrs(63),mrs2(63)
  integer mrsym(0:62),mr2sym(0:62),mrprob(0:62)
  integer dgen(12),sym(0:62),sym_rev(0:62)
!  integer test(0:62)
  character*6 mycall,hiscall0,hisgrid0,hiscall(NMAX)
  character*4 hisgrid(NMAX)
  character callsign*12,grid*4
  character*180 line
  character ceme*3,msg*22
  character*22 msg0(2*NMAX+100),decoded
  logical*1 eme(NMAX)
  logical first
  data first/.true./
  save first,sym1,nused,msg0,sym2

  if(first) then
     neme=0
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


! NB: generation of test messages is not yet complete!
     j=0
     do i=1,ncalls
        j=j+1
        msg=mycall//' '//hiscall(i)//' '//hisgrid(i)
!        if(isnr.ne.-20) write(msg(14:18),"(i3,'  ')") isnr
        call fmtmsg(msg,iz)
        call packmsg(msg,dgen,itype)            !Pack message into 72 bits
        call rs_encode(dgen,sym_rev)            !RS encode
        sym(0:62)=sym_rev(62:0:-1)
        sym1(0:62,j)=sym

        call interleave63(sym_rev,1)            !Interleave channel symbols
        call graycode(sym_rev,63,1,sym_rev)     !Apply Gray code
        sym2(0:62,j)=sym_rev(0:62)
        msg0(j)=msg
     enddo
     nused=j
     first=.false.
  endif

  ref0=0.
  do j=1,63
     ref0=ref0 + s3(mrs(j)+1,j)
  enddo

  u1=0.
  u1=-99.0
  u2=u1
  dtotal=199.0

! Find u1 and u2 (best and second-best) codeword from a list, using 
! a bank of matched filters on the symbol spectra s3(i,j).
  ipk=1
  do k=1,nused
     if(k.ge.2 .and. k.le.64 .and. flip.lt.0.0) cycle
! Test all messages if flip=+1; skip the CQ messages if flip=-1.
     if(flip.gt.0.0 .or. msg0(k)(1:3).ne.'CQ ') then
        psum=0.
        ref=ref0
        do j=1,63
           i=sym2(j-1,k)+1
           psum=psum + s3(i,j)
           if(i.eq.mrs(j)+1) ref=ref - s3(i,j) + s3(mrs2(j)+1,j)
        enddo
        p=psum/ref

! Find the FT-defined soft distance
!        test=sym1(0:62,k)
!        nh=0
!        ns=0
!        do i=0,62
!           j=62-i
!           if(mrsym(j).ne.test(i)) then
!              nh=nh+1
!              if(mr2sym(j).ne.test(i)) ns=ns+mrprob(j)
!           endif
!        enddo
!        ds=ns*63.0/sum(mrprob)

        if(p.gt.u1) then
           u2=u1
           u1=p
           ipk=k
!           nhard=nh
!           dsoft=ds
!           dtotal=nh+ds
!           ncandidates=0
!           ntry=0
        endif
     endif
  enddo

  decoded='                      '
  qual=100.0*(u1-1.12*u2)
  qmin=1.0
  if(qual.ge.qmin) decoded=msg0(ipk)

  return
end subroutine exp_decode65
