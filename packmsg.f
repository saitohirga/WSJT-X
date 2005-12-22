      subroutine packmsg(msg,dat)

      parameter (NBASE=37*36*10*27*27*27)
      character*22 msg
      integer dat(12)
      character*12 c1,c2
      character*4 c3
      character*6 grid6
c      character*3 dxcc                  !Where is DXCC implemented?
      logical text1,text2,text3

C  Convert all letters to upper case
      do i=1,22
         if(msg(i:i).ge.'a' .and. msg(i:i).le.'z') 
     +     msg(i:i)= char(ichar(msg(i:i))+ichar('A')-ichar('a'))
      enddo

C  See if it's a CQ message
      if(msg(1:3).eq.'CQ ') then
         i=3
C  ... and if so, does it have a reply frequency?
         if(msg(4:4).ge.'0' .and. msg(4:4).le.'9' .and. 
     +      msg(5:5).ge.'0' .and. msg(5:5).le.'9' .and. 
     +      msg(6:6).ge.'0' .and. msg(6:6).le.'9') i=7
         go to 1
      endif

      do i=1,22
         if(msg(i:i).eq.' ') go to 1       !Get 1st blank
      enddo 
      go to 10                             !Consider msg as plain text
      
 1    ia=i
      c1=msg(1:ia-1)
      do i=ia+1,22
         if(msg(i:i).eq.' ') go to 2       !Get 2nd blank
      enddo
      go to 10                             !Consider msg as plain text

 2    ib=i
      c2=msg(ia+1:ib-1)

      do i=ib+1,22
         if(msg(i:i).eq.' ') go to 3       !Get 3rd blank
      enddo
      go to 10                             !Consider msg as plain text

 3    ic=i
      c3='    '
      if(ic.ge.ib+1) c3=msg(ib+1:ic)
      if(c3.eq.'OOO ') c3='    '           !Strip out the OOO flag
      call getpfx1(c1,k1)
      call packcall(c1,nc1,text1)
      call getpfx1(c2,k2)
      call packcall(c2,nc2,text2)
      if(k1.lt.0 .or. k2.lt.0 .or. k1*k2.ne.0) go to 10
      if(k2.gt.0) k2=k2+450
      k=max(k1,k2)
      if(k.gt.0) then
         call k2grid(k,grid6)
         c3=grid6
      endif
      call packgrid(c3,ng,text3)
      if((.not.text1) .and. (.not.text2) .and. (.not.text3)) go to 20

C  The message will be treated as plain text.
 10   call packtext(msg,nc1,nc2,ng)
      ng=ng+32768

C  Encode data into 6-bit words
 20   dat(1)=iand(ishft(nc1,-22),63)                !6 bits
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
      end
