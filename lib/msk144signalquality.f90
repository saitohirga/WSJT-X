  subroutine msk144signalquality(cframe,snr,freq,t0,softbits,msg,dxcall,  &
       nbiterrors,eyeopening,trained,pcoeffs)

  character*22 msg,msgsent
  character*12 dxcall
  character*12 training_dxcall
  character*12 trained_dxcall
  character*6 mygrid
  character*40 pcoeff_filename
  character*8 date
  character*10 time
  character*5 zone

  complex cframe(864)
  complex cross(864)
  complex cross_avg(864)
  complex canalytic(1024)
  complex cmodel(1024)

  integer i4tone(144)
  integer hardbits(144)
  integer msgbits(144)
  integer values(8)

  logical*1 bcontest
  logical*1 first
  logical*1 currently_training
  logical*1 trained
  logical*1 msg_has_dxcall
  logical*1 is_training_frame
 
  real abscross_avg(864)
  real softbits(144)
  real waveform(0:863)  
  real d(1024)
  real phase(864)
  real twopi,freq,phi,dphi0,dphi1,dphi
  real*8 x(145),y(145),pp(145),sigmay(145),a(5),chisqr
  real pcoeffs(3)

  data first/.true./
  save cross_avg,abscross_avg,wt_avg,first,currently_training,   &
       navg,tlast,training_dxcall,trained_dxcall

  if (first) then
    navg=0
    cross=cmplx(0.0,0.0)
    cross_avg=cmplx(0.0,0.0)
    wt_avg=0.0
    tlast=0.0
    trained_dxcall(1:12)=' '
    training_dxcall(1:12)=' '
    trained=.false.
    currently_training=.false.
    pcoeffs(1:3)=0.0
    first=.false.
  endif

  if( (trained .and. (dxcall .ne. trained_dxcall)) .or.    &
      (currently_training .and. (dxcall .ne. training_dxcall)) .or. &
      (navg .gt. 10 )) then !reset and retrain
    navg=0
    cross=cmplx(0.0,0.0)
    cross_avg=cmplx(0.0,0.0)
    wt_avg=0.0
    tlast=0.0
    trained_dxcall(1:12)=' '
    trained=.false.
    currently_training=.false.
    training_dxcall(1:12)=' '
    trained_dxcall(1:12)=' '
    pcoeffs(1:3)=0.0
write(*,*) 'reset to untrained state '
  endif

  indx_dxcall=index(msg,trim(dxcall))
  msg_has_dxcall = indx_dxcall .ge. 4

  if( msg_has_dxcall .and. (.not. trained) .and. .not. currently_training ) then
    currently_training=.true.
    training_dxcall=trim(dxcall)
    trained_dxcall(1:12)=' '
    pcoeffs(1:3)=0.0
write(*,*) 'start training on call ',training_dxcall
  endif

  if( msg_has_dxcall .and. currently_training ) then
    trained=.false. ! just to be sure
    trained_dxcall(1:12)=' '
    training_dxcall=dxcall
    pcoeffs(1:3)=0.0
  endif

! use decoded message to figure out how many bit errors in the frame 
  do i=1, 144
    hardbits(i)=0
    if(softbits(i) .gt. 0 ) hardbits(i)=1
  enddo

! generate tones from decoded message
  mygrid="EN50"
  ichk=0
  bcontest=.false.
  call genmsk144(msg,mygrid,ichk,bcontest,msgsent,i4tone,itype)

! reconstruct message bits from tones
  msgbits(1)=0
  do i=1,143
    if( i4tone(i) .eq. 0 ) then
      if( mod(i,2) .eq. 1 ) then
        msgbits(i+1)=msgbits(i)
      else 
        msgbits(i+1)=mod(msgbits(i)+1,2)
      endif
    else
      if( mod(i,2) .eq. 1 ) then
        msgbits(i+1)=mod(msgbits(i)+1,2)
      else 
        msgbits(i+1)=msgbits(i)
      endif
    endif
  enddo

  nbiterrors=0
  do i=1,144
    if( hardbits(i) .ne. msgbits(i) ) nbiterrors=nbiterrors+1
  enddo

  nplus=0
  nminus=0
  eyetop=1
  eyebot=-1
  do i=1,144
    if( msgbits(i) .eq. 1 ) then
      if( softbits(i) .lt. eyetop ) eyetop=softbits(i)
    else
      if( softbits(i) .gt. eyebot ) eyebot=softbits(i)
    endif
  enddo  
  eyeopening=eyetop-eyebot

  is_training_frame =                                    &
      (snr.gt.5.0 .and.(nbiterrors.lt.7))    .and.     &
      (abs(t0-tlast) .gt. 0.072)             .and.     &
      msg_has_dxcall                              
  if( currently_training .and. is_training_frame ) then
      twopi=8.0*atan(1.0)
      nsym=144
      if( i4tone(41) .lt. 0 ) nsym=40
      dphi0=twopi*(freq-500)/12000.0
      dphi1=twopi*(freq+500)/12000.0
      phi=-twopi/8
      indx=0
      do i=1,nsym
        if( i4tone(i) .eq. 0 ) then
          dphi=dphi0
        else
          dphi=dphi1
        endif
        do j=1,6  
          waveform(indx)=cos(phi);
          indx=indx+1
          phi=mod(phi+dphi,twopi)
        enddo 
      enddo
! convert the passband waveform to complex baseband
      npts=864
      nfft=1024
      d=0
      d(1:864)=waveform(0:863)
      call analytic(d,npts,nfft,canalytic,pcoeffs,.false.,.false.) ! don't equalize the model
      call tweak1(canalytic,nfft,-freq,cmodel)
      call four2a(cframe(1:864),864,1,-1,1)
      call four2a(cmodel(1:864),864,1,-1,1)

! Cross spectra from different messages can be averaged
! as long as all messages originate from dxcall. 
      cross=cmodel(1:864)*conjg(cframe)/1000.0
      cross=cshift(cross,864/2)
      cross_avg=cross_avg+10**(snr/20.0)*cross
      wt_avg=wt_avg+10**(snr/20.0)
      navg=navg+1
      tlast=t0
      phase=atan2(imag(cross_avg),real(cross_avg))
      df=12000.0/864.0
      nm=145
      do i=1,145
        x(i)=(i-73)*df/1000.0
      enddo
      y=phase((864/2-nm/2):(864/2+nm/2))
      sigmay=wt_avg/abs(cross_avg((864/2-nm/2):(864/2+nm/2)))
      mode=1
      npts=145
      nterms=5
      call polyfit(x,y,sigmay,npts,nterms,mode,a,chisqr)
      pp=a(1)+x*(a(2)+x*(a(3)+x*(a(4)+x*a(5)))) 
      rmsdiff=sum( (pp-phase((864/2-nm/2):(864/2+nm/2)))**2 )/145.0
write(*,*) 'training ',navg,sqrt(chisqr),rmsdiff
      if( (sqrt(chisqr).lt.1.5) .and. (rmsdiff.lt.1.1) .and. (navg.ge.5) ) then 
        open(18,file='phasefit.dat',status='unknown') 
        do i=1, 145
          write(18,*) x(i),pp(i),y(i),sigmay(i)
        enddo
        close(18)
        open(19,file='cframe.dat',status='unknown')
        do i=1,864
          write(19,*) i,real(cframe(i)),imag(cframe(i))
        enddo
        close(19)
        pcoeffs=a(3:5)
        trained_dxcall=dxcall
        training_dxcall(1:12)=' '
        currently_training=.false.
        trained=.true.
        call date_and_time(date,time,zone,values)
        write(pcoeff_filename,'(i2.2,i2.2,i2.2,"_",i2.2,i2.2,i2.2)')    &
          values(1)-2000,values(2),values(3),values(5),values(6),values(7)
        pcoeff_filename=trim(trained_dxcall)//"_"//pcoeff_filename//".pcoeff"
write(*,*) pcoeff_filename
        open(17,file=pcoeff_filename,status='new')
        write(17,'(i4,2f10.2,5f10.4)') navg,sqrt(chisqr),rmsdiff,a(1),a(2),a(3),a(4),a(5)
        close(17)
      endif
  endif

  return
  end subroutine msk144signalquality
