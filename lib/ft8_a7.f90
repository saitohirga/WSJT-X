module ft8_a7

  parameter(MAXDEC=100)

! For the following three arrays
!    First index   i=decode number in this sequence
!    Second index  j=0 or 1 for even or odd sequence
!    Third index   k=0 or 1 for previous or current tally for this j
  real dt0(MAXDEC,0:1,0:1)                 !dt0(i,j,k)
  real f0(MAXDEC,0:1,0:1)                  !f0(i,j,k)
  character*37 msg0(MAXDEC,0:1,0:1)        !msg0(i,j,k)

  integer itone_a7(79)
  integer jseq                             !even=0, odd=1
  integer ndec(0:1,0:1)                    !ndec(j,k)
  data ndec/4*0/,jseq/0/

contains

subroutine ft8_a7_save(nutc,dt,f,msg)

  use packjt77
  character*37 msg,msg1
  character*13 w(19)
  character*4 g4
  integer nw(19)
  logical isgrid4

! Statement function:
  isgrid4(g4)=(len_trim(g4).eq.4 .and.                                        &
       ichar(g4(1:1)).ge.ichar('A') .and. ichar(g4(1:1)).le.ichar('R') .and.  &
       ichar(g4(2:2)).ge.ichar('A') .and. ichar(g4(2:2)).le.ichar('R') .and.  &
       ichar(g4(3:3)).ge.ichar('0') .and. ichar(g4(3:3)).le.ichar('9') .and.  &
       ichar(g4(4:4)).ge.ichar('0') .and. ichar(g4(4:4)).le.ichar('9'))

  j=mod(nutc/5,2)                        !j is 0 or 1 for odd/even sequence
  jseq=j

! Add this decode to current table for this sequence
  ndec(j,1)=ndec(j,1)+1                  !Number of decodes in this sequence
  i=ndec(j,1)                            !i is pointer to new table entry
  if(i.ge.MAXDEC-1) return               !Prevent table overflow
  if(index(msg,'<...>').ge.1) return     !Don't save an unknown hashcall

  dt0(i,j,1)=dt                          !Save dt in table
  f0(i,j,1)=f                            !Save f in table
  f0(i+1,j,1)=-99.0                      !Flag after last entry in current table
  call split77(msg,nwords,nw,w)          !Parse msg into words
  msg0(i,j,1)=trim(w(1))//' '//trim(w(2))
  if(w(1)(1:3).eq.'CQ ' .and. nw(2).le.2) then
     msg0(i,j,1)='CQ '//trim(w(2))//' '//trim(w(3))
  endif
  msg1=msg0(i,j,1)                       !Message without grid
  nn=len(trim(msg1))                     !Message length without grid
  if(isgrid4(w(nwords))) msg0(i,j,1)=trim(msg0(i,j,1))//' '//trim(w(nwords))

! If a transmission at this frequency with this message fragment
! was decoded in the previous sequence, flag it as "DO NOT USE" because
! we have already decoded that station's next transmission.

  call split77(msg1,nwords,nw,w)          !Parse msg into words
  do i=1,ndec(j,0)
     if(f0(i,j,0).le.-98.0) cycle
     i2=index(msg0(i,j,0),' '//trim(w(2)))
     if(abs(f-f0(i,j,0)).lt.2.0 .and. i2.ge.3) then
        f0(i,j,0)=-98.0           !Remove from list of to-be-tried a7 decodes
     endif
  enddo
  
  return
end subroutine ft8_a7_save

subroutine ft8_dec7(cd,xdt0,f0,msg0,xdt,xsnr,msgbest,snr7,snr7b)

! Get a7 (q3-style) decodes for FT8.

  use packjt77
  parameter(NN=79,NSPS=32)
  parameter(NWAVE=NN*NSPS)               !2528
  parameter(NZ=3200,NLAGS=NZ-NWAVE)
  parameter(MAXMSG=206)
  character*12 call_1,call_2
  character*13 w(19)
  character*4 grid4
  character*37 msg0,msg,msgbest,msgsent
  character c77*77
  complex cwave(0:NWAVE-1)
  complex cd(0:NZ-1)
  complex z
  real xjunk(NWAVE)
  real ccf(0:NLAGS-1)
  real ccfmsg(MAXMSG)
  integer itone(NN)
  integer nw(19)
  integer*1 msgbits(77)
  logical std_1,std_2

  if(xdt0.eq.-999.0) return                !Silence compiler warning

  snr7=0.
  ccfmsg=0.
  call split77(msg0,nwords,nw,w)          !Parse msg0 into words
  call_1=w(1)(1:12)
  call_2=w(2)(1:12)
  grid4=w(3)(1:4)
  if(call_1(1:3).eq.'CQ_') call_1(3:3)=' '
  
  call stdcall(call_1,std_1)
  if(call_1(1:3).eq.'CQ ') std_1=.true.
  call stdcall(call_2,std_2)

  fs=200.0                               !Sample rate (Hz)
  bt=2.0
  ccfbest=0.
  lagbest=-1
  imsgbest=1

  do imsg=1,MAXMSG
     msg=trim(call_1)//' '//trim(call_2)
     i=imsg
     if(call_1(1:3).eq.'CQ ' .and. i.ne.5) msg='CQ0XYZ '//trim(call_2)
     if(.not.std_1) then
        if(i.eq.1 .or. i.ge.6)  msg='<'//trim(call_1)//'> '//trim(call_2)
        if(i.ge.2 .and. i.le.4) msg=trim(call_1)//' <'//trim(call_2)//'>'
     else if(.not.std_2) then
        if(i.le.4 .or. i.eq.6) msg='<'//trim(call_1)//'> '//trim(call_2)
        if(i.ge.7) msg=trim(call_1)//' <'//trim(call_2)//'>'
     endif
     j0=len(trim(msg))+2
     if(i.eq.2) msg(j0:j0+2)='RRR'
     if(i.eq.3) msg(j0:j0+3)='RR73'
     if(i.eq.4) msg(j0:j0+1)='73'
     if(i.eq.5) then
        if(std_2) then
           msg='CQ '//trim(call_2)
           if(call_1(3:3).eq.'_') msg=trim(call_1)//' '//trim(call_2)
           if(grid4.ne.'RR73') msg=trim(msg)//' '//grid4
        endif
        if(.not.std_2) msg='CQ '//trim(call_2)
     endif
     if(i.eq.6 .and. std_2) msg(j0:j0+3)=grid4
     if(i.ge.7) then
        isnr = -50 + (i-7)/2
        if(iand(i,1).eq.1) then
           write(msg(j0:j0+2),'(i3.2)') isnr
           if(msg(j0:j0).eq.' ') msg(j0:j0)='+'
        else
           write(msg(j0:j0+3),'("R",i3.2)') isnr
           if(msg(j0+1:j0+1).eq.' ') msg(j0+1:j0+1)='+'
        endif
     endif

! Source-encode, then get itone()
     i3=-1
     n3=-1
     call pack77(msg,i3,n3,c77)
     call genft8(msg,i3,n3,msgsent,msgbits,itone)
     ! Generate complex cwave
     f00=0.0
     call gen_ft8wave(itone,NN,NSPS,bt,fs,f00,cwave,xjunk,1,NWAVE)

     lagmax=-1
     ccfmax=0.
     nsum=32*2
     lag0=200.0*(xdt0+0.5)
     lag1=max(0,lag0-20)
     lag2=min(nlags-1,lag0+20)
     do lag=lag1,lag2
        z=0.
        s=0.
        do i=0,NWAVE-1
           z=z + cd(i+lag)*conjg(cwave(i))
           if(mod(i,nsum).eq.nsum-1 .or. i.eq.NWAVE-1) then
              s=s + abs(z)
              z=0.
           endif
        enddo
        ccf(lag)=s
        if(ccf(lag).gt.ccfmax) then
           ccfmax=ccf(lag)
           lagmax=lag
        endif
     enddo ! lag
     ccfmsg(imsg)=ccfmax
     if(ccfmax.gt.ccfbest) then
        ccfbest=ccfmax
        lagbest=lagmax
        msgbest=msg
        imsgbest=imsg
        itone_a7=itone
     endif
  enddo  ! imsg

  call pctile(ccfmsg,MAXMSG,50,base)
  call pctile(ccfmsg,MAXMSG,84,sigma)
  sigma=sigma-base
  if(sigma.eq.0.0) sigma=1.0
  ccfmsg=(ccfmsg-base)/sigma
  xdt=lagbest/200.0 - 0.5
  snr7=maxval(ccfmsg)
  ccfmsg(imsgbest)=0.
  snr7b=snr7/maxval(ccfmsg)
  if(index(msgbest,'CQ0XYZ').ge.1) snr7=0.
  xsnr=-99.0
  if(snr7.gt.4.0) xsnr=db(snr7)-24.0

  return
end subroutine ft8_dec7


end module ft8_a7
