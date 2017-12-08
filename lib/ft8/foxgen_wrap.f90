subroutine foxgen_wrap(msg32,msgbits,itone)

  parameter (NN=79,ND=58,KK=87,NSPS=4*1920)
  parameter (NWAVE=NN*NSPS)

  character*32 msg32,cmsg
  character*6 mycall6
  integer*1 msgbits(KK),msgbits2
  integer itone(NN)
  common/foxcom/wave(NWAVE),nslots,i3bit(5),cmsg(5),mycall6
  common/foxcom2/itone2(NN),msgbits2(KK)

  nslots=1
  i1=index(msg32,'<')
  i2=index(msg32,'>')
  mycall6=msg32(i1+1:i2-1)//'    '
  cmsg(1)=msg32
  i3bit(1)=1
  call foxgen()
  msgbits=msgbits2
  itone=itone2

  return
end subroutine foxgen_wrap
