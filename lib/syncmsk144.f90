subroutine syncmsk144(cdat,npts,msgreceived,fest)
  use iso_c_binding, only: c_loc,c_size_t
  use packjt
  use hashing
  use timer_module, only: timer

  parameter (NSPM=864)
  character*22 msgreceived
  character*85 pchk_file,gen_file
  complex cdat(npts)                    !Analytic signal
  complex cdat2(npts)
  complex c(NSPM)
  complex ctmp(6000)                  
  complex cb(42)                        !Complex waveform for sync word 
  complex csum,cfac,cca,ccb
  complex cc(npts)
  complex cc1(npts)
  complex cc2(npts)
  complex bb(6)
  integer s8(8),hardbits(144),hardword(128),unscrambledhardbits(128)
  integer*1, target:: i1Dec8BitBytes(10)
  integer, dimension(1) :: iloc
  integer*4 i4Msg6BitWords(12)          !72-bit message as 6-bit words
  integer*4 i4Dec6BitWords(12)  
  integer*1 decoded(80)   
  integer*1, allocatable :: message(:)
  integer*1 i1hashdec
  integer ipeaks(10)
  logical ismask(6000)
  real cbi(42),cbq(42)
  real tonespec(6000)
  real rcw(12)
  real dd(npts)
  real pp(12)                          !Half-sine pulse shape
  real*8 dt, df, fs, pi, twopi
  real softbits(144)
  real*8 unscrambledsoftbits(128)
  real lratio(128)
  logical first
  data first/.true./

  data s8/0,1,1,1,0,0,1,0/
  save first,cb,pi,twopi,dt,f0,f1

  if(first) then
! These files can be found in /lib/ldpc/jtmode_codes directory
     pchk_file="peg-128-80-reg3.pchk"
     gen_file="peg-128-80-reg3.gen"
     call init_ldpc(trim(pchk_file)//char(0),trim(gen_file)//char(0))
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
! look for tones near 2k and 4k in the (analytic signal)**2 spectrum 
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
  fdiff=(ihpk-ilpk)*df 
  ferrh=(ihpk-2001)*df/2.0 
  ferrl=(ilpk-1001)*df/2.0
  if( abs(fdiff-2000) .le. 16.0 ) then  
    if( ah .ge. al ) then
      ferr=ferrh
    else 
      ferr=ferrl
    endif
  else   
    msgreceived=' '
    goto 999 
  endif
 
! remove coarse freq error - should now be within a few Hz
  call tweak1(cdat,npts,-(1500+ferr),cdat)

! attempt frame synchronization
! correlate with sync word waveforms - the resulting complex
! correlations provide all synch information.
  cc=0
  cc1=0
  cc2=0
  do i=1,npts-(56*6+41)
    cc1(i)=sum(cdat(i:i+41)*conjg(cb))
    cc2(i)=sum(cdat(i+56*6:i+56*6+41)*conjg(cb))
  enddo
  cc=cc1+cc2
  dd=abs(cc1)*abs(cc2)

! Find 5 largest peaks
  do ipk=1,5
    iloc=maxloc(abs(cc))           
    ic1=iloc(1)
    iloc=maxloc(dd)           
    ic2=iloc(1)
    ipeaks(ipk)=ic2
    dd(max(1,ic2-7):min(npts-56*6-41,ic2+7))=0.0
  enddo

! See if we can find "closed brackets" - a pair of peaks that differ by 864, plus or minus
! This information is not yet used for anything
  do ii=1,5
    do jj=ii+1,5
      if( (ii .ne. jj) .and. (abs( abs(ipeaks(ii)-ipeaks(jj))-864) .le. 5) ) then
!      write(*,*) "closed brackets: ",ii,jj,ipeaks(ii),ipeaks(jj),abs(ipeaks(ii)-ipeaks(jj))
      endif
    enddo
  enddo

  do iav=1,6  
  do ipk=1,5 
  do id=1,3
    if( id .eq. 1 ) is=0
    if( id .eq. 2 ) is=-1
    if( id .eq. 3 ) is=1

! we want ic to be the index of the first sample of the message
    ic=ipeaks(ipk)

    if( ic .le. 864 ) ic=ic+864
    if( ic .gt. 2*864 ) ic=ic-864
! now do fine adjustment of sync index
! bb is used to place the sampling index at the center of the eye
  do i=1,6
   io=i-3
   ill=max(1,ic+io)
   iul=min(ic+io+6+864,npts)
   bb(i) = sum( ( cdat(ic+io:iul-6:6) * conjg( cdat(ic+io+6:iul:6) ) )*2 )
  enddo
  iloc=maxloc(abs(bb))
  ibb=iloc(1)

! Adjust frame index to place peak of bb at desired lag
  ic=ic + ibb-2+is
  if( ic .le. 864 ) ic=ic+864
  if( ic .gt. 2*864 ) ic=ic-864

! Sanity check - recompute bb and verify that peak is now at designated lag.
!  do i=1,6
!   io=i-3
!   bb(i) = sum( ( cdat(ic+io:ic+io+864:6) * conjg( cdat(ic+io+6:ic+io+6+864:6) ) )*2 )
!  enddo
!  iloc=maxloc(abs(bb))
!  ibb=iloc(1)
! write(*,*) 'ic1: ',ic,'bb peak is at : ',ibb

! Estimate fine frequency error. 
! Should a larger separation be used when frames are averaged?
  cca=sum(cdat(ic:ic+41)*conjg(cb))
  ccb=sum(cdat(ic+56*6:ic+56*6+41)*conjg(cb))
  cfac=ccb*conjg(cca)
  ferr2=atan2(imag(cfac),real(cfac))/(twopi*56*6*dt)

! Final estimate of the carrier frequency - returned to the calling program
  fest=1500+ferr+ferr2
! Remove fine frequency error
  call tweak1(cdat,npts,-ferr2,cdat2)

! place the beginning of the central frame at NSPM+1
  cdat2=cshift(cdat2,ic-865)

! Try each of the three frames individually, and then
! do frame averaging on passes 4 and 5
  if( iav .eq. 1 ) then
    c=cdat2(NSPM+1:2*NSPM)
  elseif( iav .eq. 2 ) then
    c=cdat2(2*NSPM+1:npts)
  elseif( iav .eq. 3 ) then
    c=cdat2(1:NSPM)
  elseif( iav .eq. 4 ) then
    c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)
  elseif( iav .eq. 5 ) then
    c=cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:npts)
  elseif( iav .eq. 6 ) then
    c=cdat2(1:NSPM)+cdat2(NSPM+1:2*NSPM)+cdat2(2*NSPM+1:npts)
  endif 

! Estimate final frequency error and carrier phase. 
  cca=sum(c(1:1+41)*conjg(cb))
  ccb=sum(c(1+56*6:1+56*6+41)*conjg(cb))
  cfac=ccb*conjg(cca)
  ffin=atan2(imag(cfac),real(cfac))/(twopi*56*6*dt)
  phase0=atan2(imag(cca+ccb),real(cca+ccb))

! Remove the static phase error from the data
  cfac=cmplx(cos(phase0),sin(phase0))
  c=c*conjg(cfac)

! sample to get softsamples
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

! calculated the number of sync-word bits that are incorrect
! this might come in handy some day
  nbadsync=sum(s8*(2*hardbits(1:8)-1))
  nbadsync=nbadsync+sum(s8*(2*hardbits(57:57+7)-1))
  nbadsync=16-nbadsync

  if( nbadsync .gt. 6 ) cycle

! this could be used to count the number of hard errors that were corrected
  hardword(1:48)=hardbits(9:9+47)  
  hardword(49:128)=hardbits(65:65+80-1)  
  unscrambledhardbits(1:127:2)=hardword(1:64) 
  unscrambledhardbits(2:128:2)=hardword(65:128) 

! normalize the softsymbols before submitting to decoder
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

  max_iterations=10
  max_dither=100
  call ldpc_decode(unscrambledsoftbits, decoded, max_iterations, niterations, max_dither, ndither)

  if( niterations .ge. 0.0 ) then
    goto 778
  endif

enddo
enddo
enddo

msgreceived=' '
goto 999

778 continue
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
    else
      msgreceived=' '
    endif

write(78,1001) iav,ipk,is,fdiff,fest,nbadsync,phase0,niterations,ndither,i1hashdec,i1Dec8BitBytes(10),msgreceived
1001 format(i6,i6,i6,f10.1,f10.1,i6,f10.2,i6,i6,i6,i6,4x,a22)
999 return

end subroutine syncmsk144
