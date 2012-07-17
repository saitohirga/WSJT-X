subroutine jtmsk(dat,npts,cfile6,t2,mswidth,ndb,nrpt,Nfreeze,       &
     ntol,MouseDF,pick)

! Decode a JTMS ping

  parameter (NZ=30*48000)
  real dat(npts)                        !Raw data
  complex cdat(NZ)                      !Analytic form of signal
  character*6 cfile6                    !FileID
  logical pick
  character*12 mycall,hiscall
  real s(NZ)                            !Power spectrum
  real s2(0:63,400)
  real r(60000)
  complex cw(168,0:63)                   !Complex waveforms for all codewords
  complex cwb(168)                       !Complex waveform for <space>
  logical first
  character msg*400,msg29*29
  character*90 line
  common/ccom/nline,tping(100),line(100)
  data first/.true./
  save first,cw,cwb
  save cdat                             !Fix its address, for four2

  if(first) call setupmsk(cw,cwb)       !Calculate waveforms for codewords
  first=.false.

  nsps=24                               !Samples per symbol
  f0=1000.0                             !Nominal frequency for bit=0
  n=log(float(npts))/log(2.0) + 1.0
  nfft1=2**n                            !FFT length
  call analytic(dat,npts,nfft1,s,cdat)  !Convert to analytic signal

  call mskdf(cdat,npts,t2,nfft1,f0,nfreeze,mousedf,ntol,     &
       dfx,snrsq2)                      !Get DF
  print*,'b',dfx,snrsq2
  sq2lim=7.0
  if(pick) sq2lim=5.0
  if(snrsq2.lt.sq2lim) go to 900           !Reject non-JTMS signals

  call tweak1(cdat,npts,-dfx,cdat)      !Mix to standard frequency

! DF is known, now establish character sync.

  call syncmsk(cdat,npts,cwb,r,i1)       !Get character sync

  call lenmsk(r,npts,msglen)             !Find message length
  
  s2=0.
  nchar=(npts-168+1-i1)/168
  if(nchar.gt.400) nchar=400

  call decodemsk(cdat,npts,cw,i1,nchar,s2,msg)   !Decode the message
  print*,'B',i1,msglen,nchar
  print*,msg(1:nchar)

!  ia=1
!  if(nchar.ge.40) ia=min(nchar/3,nchar-28)    
!  ib=min(ia+28,nchar)                   !Can better limits ia, ib be found?
!  print*,'A',ia,ib,nchar
!  print*,msg(1:nchar)
!  msg29=adjustl(msg(ia:ib))
  msg=adjustl(msg)
  ib=min(nchar,45)
  ndf=nint(dfx)
  nchk=max(20,nint(1.5*msglen))

  if(msglen.eq.0 .or. nchar.lt.nchk .or. pick) then
     if(nline.le.99) nline=nline+1
     tping(nline)=t2
     write(line(nline),1110) cfile6,t2,mswidth,ndb,nrpt,ndf,msg(1:45)
1110 format(a6,f5.1,i5,i3,1x,i2.2,i5,5x,a45)
  endif

  if(msglen.gt.0 .and. nchar.ge.nchk) then
     call foldmsk(s2,msglen,nchar,mycall,msg,msg29)   !Decode folded message
     if(nline.le.99) nline=nline+1
     tping(nline)=t2
     write(line(nline),1120) cfile6,t2,mswidth,ndb,nrpt,ndf,msg29
1120 format(a6,f5.1,i5,i3,1x,i2.2,i5,5x,a29,11x,'*')
   endif

900 continue

  return
end subroutine jtmsk
