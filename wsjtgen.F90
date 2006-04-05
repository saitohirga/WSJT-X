subroutine wsjtgen

! Compute the waveform to be transmitted.  

! Input:    txmsg        message to be transmitted, up to 28 characters
!           samfacout    fsample_out/11025.d0

! Output:   iwave        waveform data, i*2 format
!           nwave        number of samples
!           sendingsh    0=normal; 1=shorthand (FSK441) or plain text (JT65)

  parameter (NMSGMAX=28)             !Max characters per message
  parameter (NSPD=25)                !Samples per dit
  parameter (NDPC=3)                 !Dits per character
  parameter (NWMAX=661500)         !Max length of waveform = 60*11025
  parameter (NTONES=4)               !Number of FSK tones

  integer   itone(84)
  character msg*28,msgsent*22,idmsg*22
  real*8 freq,pha,dpha,twopi,dt
  character testfile*27
  logical lcwid
  integer*2 icwid(110250)

  integer*1 hdr(44)
  integer*2 nfmt2,nchan2,nbitsam2,nbytesam2
  character*4 ariff,awave,afmt,adata
  common/hdr/ariff,lenfile,awave,afmt,lenfmt,nfmt2,nchan2, &
     nsamrate,nbytesec,nbytesam2,nbitsam2,adata,ndata
  equivalence (ariff,hdr)

  data twopi/6.28318530718d0/
  include 'gcom1.f90'
  include 'gcom2.f90'

  fsample_out=11025.d0*samfacout
  lcwid=.false.
  if(idinterval.gt.0) then
     n=(mod(int(tsec/60.d0),idinterval))
     if(n.eq.(1-txfirst)) lcwid=.true.
     if(idinterval.eq.1) lcwid=.true.
  endif

  msg=txmsg
  ntxnow=ntxreq
! Convert all letters to upper case
  do i=1,28
     if(msg(i:i).ge.'a' .and. msg(i:i).le.'z')                  &
          msg(i:i)= char(ichar(msg(i:i))+ichar('A')-ichar('a'))
  enddo
  txmsg=msg

! Find message length
  do i=NMSGMAX,1,-1
     if(msg(i:i).ne.' ') go to 10
  enddo
  i=1
10 nmsg=i
  nmsg0=nmsg

  if(msg(1:1).eq.'@') then
     if(msg(2:2).eq.'/' .or. ichar(msg(2:2)).eq.92) then
        if(msg(2:).ne.testfile) then
           testfile=msg(2:)

#ifdef Win32
           open(18,file=testfile,form='binary',status='old',err=12)
#else
           open(18,file=testfile,form='unformatted',status='old',err=12)
#endif

           go to 14
12         print*,'Cannot open test file ',msg(2:)
           go to 999
14         read(18) hdr
           if(ndata.gt.NTxMax) ndata=NTxMax
           call rfile(18,iwave,ndata,ierr)
           close(18)
           if(ierr.ne.0) print*,'Error reading test file ',msg(2:)
           nwave=ndata/2
           do i=nwave,NTXMAX
              iwave(i)=0
           enddo
        endif
        go to 999
     endif

! Transmit a fixed tone at specified frequency
     freq=1000.0
     if(msg(2:2).eq.'A' .or. msg(2:2).eq.'a') freq=882
     if(msg(2:2).eq.'B' .or. msg(2:2).eq.'b') freq=1323
     if(msg(2:2).eq.'C' .or. msg(2:2).eq.'c') freq=1764
     if(msg(2:2).eq.'D' .or. msg(2:2).eq.'d') freq=2205
     if(freq.eq.1000.0) then
        read(msg(2:),*,err=1) freq
        goto 2
1       txmsg='@1000'
        nmsg=5
        nmsg0=5
     endif
2    nwave=60*fsample_out
     dpha=twopi*freq/fsample_out
     do i=1,nwave
        iwave(i)=32767.0*sin(i*dpha)
     enddo
     goto 900
  endif

  dt=1.d0/fsample_out
  LTone=2

  if(mode(1:4).eq.'JT65') then
!  We're in JT65 mode.
     if(mode(5:5).eq.'A') mode65=1
     if(mode(5:5).eq.'B') mode65=2
     if(mode(5:5).eq.'C') mode65=4
     call gen65(msg,mode65,samfacout,iwave,nwave,sendingsh,msgsent)

     if(lcwid) then
!  Generate and insert the CW ID.
        wpm=25.
        freqcw=800.
        idmsg=MyCall//'          '
        call gencwid(idmsg,wpm,freqcw,samfacout,icwid,ncwid)
        k=nwave
        do i=1,ncwid
           k=k+1
           iwave(k)=icwid(i)
        enddo
        do i=1,2205                   !Add 0.2 s of silence
           k=k+1
           iwave(k)=0
        enddo
        nwave=k
     endif

     goto 900
  endif

  if(mode(1:4).eq.'Echo') then
!  We're in Echo mode.
!     dither=AmpA
!     call echogen(dither,wavefile,nbytes,f1)
!     AmpB=f1
     goto 900
  endif

  if(mode(1:4).eq.'JT6M') then
!  We're in JT6M mode.
     call gen6m(msg,samfacout,iwave,nwave)
     goto 900
  endif

  if(mode(1:2).eq.'CW') then
!  We're in CW mode
     wpm=15.
     freqcw=800.
     call gencw(msg,wpm,freqcw,samfacout,TRPeriod,iwave,nwave)
     goto 900
  endif

!  We're in FSK441 mode.
  if(nmsg.lt.28) nmsg=nmsg+1          !Add trailing blank if nmsg < 28

!  Check for shorthand messages
  sendingsh = 0
  if(shok.eq.1 .and. nmsg.le.4) then
     if (msg(1:3).eq.'R26') then
        msg='++'
        nmsg=2
        sendingsh = 1
     else if (msg(1:3).eq.'R27') then
        msg='**'
        nmsg=2
        sendingsh = 1
     else if (msg(1:3).eq.'RRR') then
        msg='%%'
        nmsg=2
        sendingsh = 1
     else if (msg(1:2).eq.'73') then
        msg='@@'
        nmsg=2
        sendingsh = 1
     endif
  endif

!  Encode the message
  call abc441(msg,nmsg,itone,ndits)
  ndata=ndits*nspd

! Generate iwave
  k=0
  df=11025.0/NSPD
  do m=1,ndits
     j=itone(m)
     freq=(LTone-1+itone(m))*df
     dpha=twopi*freq*dt
     do i=1,NSPD
        k=k+1
        pha=pha+dpha
        iwave(k)=nint(32767.0*sin(pha))
     enddo
  enddo
  nwave=k
  
900 sending=txmsg
  if(mode(1:4).eq.'JT65' .and. sendingsh.ne.1) sending=msgsent
  nmsg=nmsg0

  if(lcwid .and. (mode.eq.'FSK441' .or. mode(1:4).eq.'JT6M')) then
!  Generate and insert the CW ID.
     wpm=25.
     freqcw=440.
     idmsg=MyCall//'          '
     call gencwid(idmsg,wpm,freqcw,samfacout,icwid,ncwid)
     k=0
     do i=ncwid+1,int(trperiod*fsample_out)
        k=k+1
        if(k.gt.nwave) k=k-nwave
        iwave(i)=iwave(k)
     enddo
     do i=1,ncwid
        iwave(i)=icwid(i)
     enddo
     nwave=trperiod*fsample_out
  endif

999  return
end subroutine wsjtgen

