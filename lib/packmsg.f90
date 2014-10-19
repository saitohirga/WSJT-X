subroutine packmsg(msg,dat,itype)

! Packs a JT4/JT9/JT65 message into twelve 6-bit symbols

! itype Message Type
!--------------------
!   1   Standardd message
!   2   Type 1 prefix
!   3   Type 1 suffix
!   4   Type 2 prefix
!   5   Type 2 suffix
!   6   Free text
!  -1   Does not decode correctly

  parameter (NBASE=37*36*10*27*27*27)
  parameter (NBASE2=262178562)
  character*22 msg
  integer dat(12)
  character*12 c1,c2
  character*4 c3
  character*6 grid6
  logical text1,text2,text3

  itype=1
  call fmtmsg(msg,iz)

  if(msg(1:6).eq.'CQ DX ') msg(3:3)='9'

! See if it's a CQ message
  if(msg(1:3).eq.'CQ ') then
     i=3
! ... and if so, does it have a reply frequency?
     if(msg(4:4).ge.'0' .and. msg(4:4).le.'9' .and.                  &
          msg(5:5).ge.'0' .and. msg(5:5).le.'9' .and.                &
          msg(6:6).ge.'0' .and. msg(6:6).le.'9') i=7
     go to 1
  endif

  do i=1,22
     if(msg(i:i).eq.' ') go to 1       !Get 1st blank
  enddo
  go to 10                             !Consider msg as plain text
      
1 ia=i
  c1=msg(1:ia-1)
  do i=ia+1,22
     if(msg(i:i).eq.' ') go to 2       !Get 2nd blank
  enddo
  go to 10                             !Consider msg as plain text

2 ib=i
  c2=msg(ia+1:ib-1)

  do i=ib+1,22
     if(msg(i:i).eq.' ') go to 3       !Get 3rd blank
  enddo
  go to 10                             !Consider msg as plain text

3 ic=i
  c3='    '
  if(ic.ge.ib+1) c3=msg(ib+1:ic)
  if(c3.eq.'OOO ') c3='    '           !Strip out the OOO flag
  call getpfx1(c1,k1,nv2a)
  if(nv2a.ge.4) go to 10
  call packcall(c1,nc1,text1)
  if(text1) go to 10
  call getpfx1(c2,k2,nv2b)
  call packcall(c2,nc2,text2)
  if(text2) go to 10
  if(nv2a.eq.2 .or. nv2a.eq.3 .or. nv2b.eq.2 .or. nv2b.eq.3) then
     if(k1.lt.0 .or. k2.lt.0 .or. k1*k2.ne.0) go to 10
     if(k2.gt.0) k2=k2+450
     k=max(k1,k2)
     if(k.gt.0) then
        call k2grid(k,grid6)
        c3=grid6(:4)
     endif
  endif
  call packgrid(c3,ng,text3)

  if(nv2a.lt.4 .and. nv2b.lt.4 .and. (.not.text1) .and. (.not.text2) .and.  &
       (.not.text3)) go to 20

  nc1=0
  if(nv2b.eq.4) then
     if(c1(1:3).eq.'CQ ')  nc1=262178563 + k2
     if(c1(1:4).eq.'QRZ ') nc1=264002072 + k2 
     if(c1(1:3).eq.'DE ')  nc1=265825581 + k2
  else if(nv2b.eq.5) then
     if(c1(1:3).eq.'CQ ')  nc1=267649090 + k2
     if(c1(1:4).eq.'QRZ ') nc1=267698375 + k2
     if(c1(1:3).eq.'DE ')  nc1=267747660 + k2
  endif
  if(nc1.ne.0) go to 20

! The message will be treated as plain text.
10 itype=6
  call packtext(msg,nc1,nc2,ng)
  ng=ng+32768

! Encode data into 6-bit words
20 continue
  if(itype.ne.6) itype=max(nv2a,nv2b)
  dat(1)=iand(ishft(nc1,-22),63)                !6 bits
  dat(2)=iand(ishft(nc1,-16),63)                !6 bits
  dat(3)=iand(ishft(nc1,-10),63)                !6 bits
  dat(4)=iand(ishft(nc1, -4),63)                !6 bits
  dat(5)=4*iand(nc1,15)+iand(ishft(nc2,-26),3)  !4+2 bits
  dat(6)=iand(ishft(nc2,-20),63)                !6 bits
  dat(7)=iand(ishft(nc2,-14),63)                !6 bits
  dat(8)=iand(ishft(nc2, -8),63)                !6 bits
  dat(9)=iand(ishft(nc2, -2),63)                !6 bits
  dat(10)=16*iand(nc2,3)+iand(ishft(ng,-12),15) !2+4 bits
  dat(11)=iand(ishft(ng,-6),63)
  dat(12)=iand(ng,63)

  return
end subroutine packmsg

