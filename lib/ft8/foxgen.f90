subroutine foxgen()

  ! Called from MainWindow::foxTxSequencer() to generate the Tx waveform in
  ! FT8 Fox mode.  The Tx message can contain up to 5 "slots", each carrying
  ! its own FT8 signal.
  
  ! Encoded messages can be of the form "HoundCall FoxCall rpt" (a standard FT8
  ! message with i3bit=0) or "HoundCall_1 RR73; HoundCall_2 <FoxCall> rpt", 
  ! a new message type with i3bit=1.  The waveform is generated with
  ! fsample=48000 Hz; it is compressed to reduce the PEP-to-average power ratio,
  ! with (currently disabled) filtering afterware to reduce spectral growth.

  ! Input message information is provided in character array cmsg(5), in
  ! common/foxcom/.  The generated wave(NWAVE) is passed back in the same
  ! common block.
  
  use crc
  parameter (NN=79,ND=58,KK=87,NSPS=4*1920)
  parameter (NWAVE=NN*NSPS,NFFT=614400,NH=NFFT/2)
  character*32 cmsg
  character*22 msg,msgsent
  character*6 mygrid
  character*87 cbits
  character*88 cb88
  logical bcontest
  integer itone(NN)
  integer icos7(0:6)
  integer*1 msgbits(KK),codeword(3*ND),msgbits2
  integer*1, target:: i1Msg8BitBytes(11)
  integer*1, target:: mycall
  real x(NFFT),y(NFFT)
  real*8 dt,twopi,f0,fstep,dfreq,phi,dphi
  complex cx(0:NH),cy(0:NH)
  common/foxcom/wave(NWAVE),nslots,i3bit(5),cmsg(5),mycall(6)
  common/foxcom2/itone2(NN),msgbits2(KK)
  equivalence (x,cx),(y,cy)
  data icos7/2,5,6,0,4,1,3/                   !Costas 7x7 tone pattern

  bcontest=.false.
  fstep=60.d0
  dfreq=6.25d0
  dt=1.d0/48000.d0
  twopi=8.d0*atan(1.d0)
  wave=0.
  mygrid='      '
  irpt=0

  do n=1,nslots
     i3b=i3bit(n)
     if(i3b.eq.0) then
        msg=cmsg(n)(1:22)                     !Stansard FT8 message
     else
        i1=index(cmsg(n),' ')                 !Special Fox message
        i2=index(cmsg(n),';')
        i3=index(cmsg(n),'<')
        i4=index(cmsg(n),'>')
        msg=cmsg(n)(1:i1)//cmsg(n)(i2+1:i3-2)//'                   '
        read(cmsg(n)(i4+2:i4+4),*) irpt
     endif
     call genft8(msg,mygrid,bcontest,0,msgsent,msgbits,itone)

     if(i3b.eq.1) then
        icrc10=crc10(c_loc(mycall),6)
        nrpt=irpt+30
        write(cbits,1001) msgbits(1:56),icrc10,nrpt,i3b,0
1001    format(56b1.1,b10.10,b6.6,b3.3,b12.12)
        read(cbits,1002) msgbits
1002    format(87i1)

        cb88=cbits//'0'
        read(cb88,1003) i1Msg8BitBytes(1:11)
1003    format(11b8)
        icrc12=crc12(c_loc(i1Msg8BitBytes),11)

        print*,'BB',icrc10,nrpt,i3b,icrc12
        write(cbits,1001) msgbits(1:56),icrc10,nrpt,i3b,icrc12
        read(cbits,1002) msgbits

        call encode174(msgbits,codeword)      !Encode the test message
        
! Message structure: S7 D29 S7 D29 S7
        itone(1:7)=icos7
        itone(36+1:36+7)=icos7
        itone(NN-6:NN)=icos7
        k=7
        do j=1,ND
           i=3*j -2
           k=k+1
           if(j.eq.30) k=k+7
           itone(k)=codeword(i)*4 + codeword(i+1)*2 + codeword(i+2)
        enddo
     endif
     
! Make copies of itone() and msgbits() for ft8sim
     itone2=itone
     msgbits2=msgbits

     f0=1800.d0 + fstep*(n-1)
     phi=0.d0
     k=0
     do j=1,NN
        f=f0 + dfreq*itone(j)
        dphi=twopi*f*dt
        do ii=1,NSPS
           k=k+1
           phi=phi+dphi
           xphi=phi
           wave(k)=wave(k)+sin(xphi)
        enddo
     enddo
  enddo

  sqx=0.
  do i=1,NWAVE
     sqx=sqx + wave(i)*wave(i)
  enddo
  sigmax=sqrt(sqx/NWAVE)
  wave=wave/sigmax                    !Force rms=1.0

  do i=1,NWAVE
     wave(i)=h1(wave(i))              !Compress the waveform
  enddo
  
  fac=1.0/maxval(abs(wave))           !Set maxval = 1.0
  wave=fac*wave

  if(NWAVE.ne.-99) go to 100             !### Omit filtering, for now ###

  x(1:k)=wave
  x(k+1:)=0.
  call four2a(x,nfft,1,-1,0)

  nadd=64
  k=0
  df=48000.0/NFFT
  rewind(29)
  do i=1,NH/nadd - 1
     sx=0.
!     sy=0.
     do j=1,nadd
        k=k+1
        sx=sx + real(cx(k))**2 + aimag(cx(k))**2
!        sy=sy + real(cy(k))**2 + aimag(cy(k))**2
     enddo
     freq=df*(k-nadd/2+0.5)
     write(29,1022) freq,sx,sy,db(sx)-90.0,db(sy)-90.0
1022 format(f10.3,2e12.3,2f10.3)
     if(freq.gt.3000.0) exit
  enddo
  flush(29)

100 continue

  return
end subroutine foxgen
