subroutine exp_decode65(s3,mrs,mrs2,mode65,flip,mycall,qual,decoded)

  use packjt
  use prog_args
  parameter (NMAX=10000)
  real s3(64,63)
  real pp(NMAX)
  integer*1 sym1(0:62,NMAX)
  integer*1 sym2(0:62,NMAX)
  integer mrs(63),mrs2(63)
  integer dgen(12),sym(0:62),sym_rev(0:62)
  character*6 mycall,hiscall(NMAX)
  character*4 hisgrid(NMAX)
  character callsign*12,grid*4
  character*180 line
  character ceme*3,msg*22
  character*22 msg0(1000),decoded
  logical*1 eme(NMAX)
  logical first
  data first/.true./
  save first,sym1,nused,msg0,sym2

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

!### Special for tests ###
        do isnr=-20,-30,-1
           j=j+1
           msg=mycall//' '//hiscall(i)//' '//hisgrid(i)
           write(msg(14:18),"(i3,'  ')") isnr
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

     enddo
     nused=j
     first=.false.
  endif

  ref0=0.
  do j=1,63
     ref0=ref0 + s3(mrs(j)+1,j)
  enddo

  p1=-1.e30
  p2=-1.e30
  ip1=1                                    !Silence compiler warning
  do k=1,nused
     pp(k)=0.
     if(k.ge.2 .and. k.le.64 .and. flip.lt.0.0) cycle
! Test all messages if flip=+1; skip the CQ messages if flip=-1.
     if(flip.gt.0.0 .or. msg0(k)(1:3).ne.'CQ ') then
        sum=0.
        ref=ref0
        do j=1,63
!           i=ncode(j,k)+1
           i=sym2(j-1,k)+1
           sum=sum + s3(i,j)
           if(i.eq.mrs(j)+1) ref=ref - s3(i,j) + s3(mrs2(j)+1,j)
        enddo
        p=sum/ref
        pp(k)=p
        if(p.gt.p1) then
           p1=p
           ip1=k
        endif
     endif
!     write(*,3001) k,p,msg0(k)
!3001 format(i5,f10.3,2x,a22)
  enddo

  do i=1,nused
     if(pp(i).gt.p2 .and. pp(i).ne.p1) p2=pp(i)
  enddo

! ### DO NOT REMOVE ### 
!  call cs_lock('deep65')
  rewind 77
  write(77,*) p1,p2
  call flush(77)
!  call cs_unlock
! ### Works OK without it (in both Windows and Linux) if compiled 
! ### without optimization.  However, in Windows this is a colossal 
! ### pain because of the way F2PY wants to run the compile step.

  bias=max(1.12*p2,0.335)
  if(mode65.eq.2) bias=max(1.08*p2,0.405)
  if(mode65.ge.4) bias=max(1.04*p2,0.505)

  if(p2.eq.p1 .and. p1.ne.-1.e30) stop 'Error in deep65'
  qual=100.0*(p1-bias)
  if(qual.lt.0.0) qual=0.0
  decoded='                      '
  if(qual.ge.1.0) decoded=msg0(ip1)

  return
end subroutine exp_decode65
