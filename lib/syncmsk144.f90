subroutine syncmsk144(cdat,npts,jpk,ipk,idf,rmax,snr,metric,msgreceived,fest)

! Attempt synchronization, and if successful decode using Viterbi algorithm.

  use iso_c_binding, only: c_loc,c_size_t
  use packjt
  use hashing
  use timer_module, only: timer

  parameter (NSPM=864,NSAVE=2000)
  character*22 msgreceived
  character*85 pchk_file,gen_file
  complex cdat(npts)                    !Analytic signal
  complex c(NSPM)
  complex ctmp(6000)                  
  complex cb(42)                        !Complex waveform for sync word 
  complex csum,cfac,cca,ccb
  complex cc(npts)
  complex cc1(npts)
  complex cc2(npts)
  complex cc3(npts)
  integer s8(8),hardbits(144),hardword(128),unscrambledhardbits(128)
  integer*1, target:: i1Dec8BitBytes(10)
  integer, dimension(1) :: iloc
  integer*4 i4Msg6BitWords(12)          !72-bit message as 6-bit words
  integer*4 i4Dec6BitWords(12)  
  integer*1 decoded(80)   
  integer*1, allocatable :: message(:)
  integer*1 i1hashdec
  logical ismask(6000)
  real cbi(42),cbq(42)
  real tonespec(6000)
  real rcw(12)
  real dd(npts)
  real pp(12)                          !Half-sine pulse shape
  real*8 dt, df, fs, twopi
  real softbits(144)
  real*8 unscrambledsoftbits(128)
  real lratio(128)
  logical first
  data first/.true./

  data s8/0,1,1,1,0,0,1,0/
  save first,cb,cd,pi,twopi,dt,f0,f1

  open(unit=78,file="/Users/sfranke/Builds/wsjtx_install/sfdebug.txt")
  if(first) then
     write(78,*) "Initializing ldpc."
     pchk_file="/Users/sfranke/Builds/wsjtx_install/peg-128-80-reg3.pchk"
     gen_file="/Users/sfranke/Builds/wsjtx_install/peg-128-80-reg3.gen"
     call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))
     write(78,*) "after init_ldpc"
! define half-sine pulse and raised-cosine edge window
     pi=4d0*datan(1d0)
     twopi=8d0*datan(1d0)
     dt=1.0/12000.0
     do i=1,12
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
       rcw(i)=(1-cos(angle))/2
     enddo

! define the sync word waveform
     s8=2*s8-1  
     cbq(1:6)=pp(7:12)*s8(1)
     cbq(7:18)=pp*s8(3)
     cbq(19:30)=pp*s8(5)
     cbq(31:42)=pp*s8(7)
     cbi(1:12)=pp*s8(2)
     cbi(13:24)=pp*s8(4)
     cbi(25:36)=pp*s8(6)
     cbi(37:42)=pp(1:6)*s8(8)
     cb=cmplx(cbi,cbq)

     first=.false.
  endif

  
! Coarse carrier frequency sync
! look for tones near 2k and 4k in the analytic signal spectrum 
! search range for coarse frequency error is +/- 100 Hz
  fs=12000.0
  nfft=6000      !using a zero-padded fft to get 2 Hz bins
  df=fs/nfft

  ctmp=cmplx(0.0,0.0)
  ctmp(1:npts)=cdat**2   
  ctmp(1:12)=ctmp(1:12)*rcw
  ctmp(npts-11:npts)=ctmp(npts-11:npts)*rcw(12:1:-1)
  call four2a(ctmp,nfft,1,-1,1)  
  tonespec=abs(ctmp)**2 
  ismask=.false.
  ismask(1901:2101)=.true.  ! high tone search window
  iloc=maxloc(tonespec,ismask)           
  ihpk=iloc(1)
  ah=tonespec(ihpk)
  ismask=.false.
  ismask(901:1101)=.true.   ! window for low tone
  iloc=maxloc(tonespec,ismask)           
  ilpk=iloc(1)
  al=tonespec(ilpk)
  if( ah .ge. al ) then
    ferr=(ihpk-2001)*df/2.0 
    tot=sum(tonespec(1901:2101))
    q1=200*ah/(tot-tonespec(ihpk))
  else
    ferr=(ilpk-1001)*df/2.0
    tot=sum(tonespec(901:1101))
    q1=200*al/(tot-tonespec(ilpk))
  endif
  fdiff=(ihpk-ilpk)*df

!  write(78,*) "Coarse frequency error: ",ferr
!  write(78,*) "Tone / avg            : ",q1
!  write(78,*) "Tone separation       : ",fdiff

! remove coarse freq error - should now be within a few Hz
  call tweak1(cdat,npts,-(1500+ferr),cdat)

! correlate with sync word waveform
  cc=0
  cc1=0
  cc2=0
  cc3=0
  do i=1,npts-448-41
    cc1(i)=sum(cdat(i:i+41)*conjg(cb))
    cc2(i)=sum(cdat(i+56*6:i+56*6+41)*conjg(cb))
  enddo
  cc=cc1+cc2
  dd=abs(cc1)*abs(cc2)
  iloc=maxloc(abs(cc))           
  ic1=iloc(1)
  iloc=maxloc(dd)           
  ic2=iloc(1)
  
!  write(78,*) "Syncs: ic1,ic2 ",ic1,ic2
  ic=ic2

!  do i=1,npts-448-41
!    write(78,*) i,abs(cc1(i)),abs(cc2(i)),abs(cc(i)),dd(i),abs(cc3(i))
!  enddo

  cca=sum(cdat(ic:ic+41)*conjg(cb))
  ccb=sum(cdat(ic+56*6:ic+56*6+41)*conjg(cb))
  phase0=atan2(imag(cca+ccb),real(cca+ccb))
  cfac=ccb*conjg(cca)
  ferr2=atan2(imag(cfac),real(cfac))/(twopi*56*6*dt)
 write(78,*) "Fine frequency error: ",ferr2
 write(78,*) "Coarse Carrier phase       : ",phase0

  fest=1500+ferr+ferr2
  write(78,*) "Estimated f0        : ",fest

! Remove fine frequency error
  call tweak1(cdat,npts,-ferr2,cdat)

! Estimate final carrier phase
  cca=sum(cdat(ic:ic+41)*conjg(cb))
  ccb=sum(cdat(ic+56*6:ic+56*6+41)*conjg(cb))
  cfac=ccb*conjg(cca)
  ffin=atan2(imag(cfac),real(cfac))/(twopi*56*6*dt)
  phase0=atan2(imag(cca+ccb),real(cca+ccb))
  write(78,*) "Final freq    error: ",ffin

  cfac=cmplx(cos(phase0),sin(phase0))
  cdat=cdat*conjg(cfac)

  do i=1,864
    ii=ic+i-1
    if( ii .gt. npts ) then
      ii=ii-864
    endif
    c(i)=cdat(ii)
  enddo
  do i=1,72
    softbits(2*i-1)=imag(c(1+(i-1)*12))
    softbits(2*i)=real(c(7+(i-1)*12))  
  enddo
  hardbits=0
  do i=1,144
    if( softbits(i) .ge. 0.0 ) then
      hardbits(i)=1
    endif
  enddo 
!  write(78,*) hardbits(1:8)
!  write(78,*) hardbits(57:57+7)

  hardword(1:48)=hardbits(9:9+47)  
  hardword(49:128)=hardbits(65:65+80-1)  
  unscrambledhardbits(1:127:2)=hardword(1:64) 
  unscrambledhardbits(2:128:2)=hardword(65:128) 
  sav=sum(softbits)/144
  s2av=sum(softbits*softbits)/144
  ssig=sqrt(s2av-sav*sav)
  softbits=softbits/ssig

  sigma=0.65
  lratio(1:48)=softbits(9:9+47)
  lratio(49:128)=softbits(65:65+80-1)
  lratio=exp(2.0*lratio/(sigma*sigma))
  
  unscrambledsoftbits(1:127:2)=lratio(1:64) 
  unscrambledsoftbits(2:128:2)=lratio(65:128) 

  max_iterations=20
  max_dither=100
  call ldpc_decode(unscrambledsoftbits, decoded, max_iterations, niterations, max_dither, ndither)
  write(78,*) 'Decoder used ',niterations,'iterations and ',ndither,' dither trials.'

  if( niterations .lt. 0 ) then 
    msgreceived=' '
    return
  endif

! The decoder found a codeword - compare decoded hash with calculated
! Collapse 80 decoded bits to 10 bytes. Bytes 1-9 are the message, byte 10 is the hash
    do ibyte=1,10   
      itmp=0
      do ibit=1,8
        itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*8+ibit))
      enddo
      i1Dec8BitBytes(ibyte)=itmp
    enddo

! Calculate the hash using the first 9 bytes.
    ihashdec=nhash(c_loc(i1Dec8BitBytes),int(9,c_size_t),146)
    ihashdec=2*iand(ihashdec,255)

! Compare calculated hash with received byte 10 - if they agree, keep the message.
    i1hashdec=ihashdec

    if( i1hashdec .eq. i1Dec8BitBytes(10) ) then
! Good hash --- unpack 72-bit message
      do ibyte=1,12
        itmp=0
        do ibit=1,6
          itmp=ishft(itmp,1)+iand(1,decoded((ibyte-1)*6+ibit))
        enddo
        i4Dec6BitWords(ibyte)=itmp
      enddo
      call unpackmsg(i4Dec6BitWords,msgreceived)
    endif
close(78)
return

end subroutine syncmsk144
