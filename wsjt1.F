	subroutine wsjt1(d,jz0,istart,samfacin,FileID,ndepth,MinSigdB,
     +    NQRN,DFTolerance,MouseButton,NClearAve,
     +    Mode,NFreeze,NAFC,NZap,mode65,idf,
     +    MyCall,HisCall,HisGrid,neme,nsked,ntx2,s2,
     +    ps0,npkept,lumsg,basevb,rmspower,nslim2,psavg,ccf,Nseg,
     +    MouseDF,NAgain,LDecoded,nspecial,ndf,ss1,ss2)

	parameter (NP2=1024*1024)

	integer*2 d(jz0)        !Buffer for raw one-byte data
	integer istart          !Starting location in original d() array
	character FileID*40     !Name of file being processed
	integer MinSigdB        !Minimum ping strength, dB
	integer NQRN            !QRN rejection parameter
	integer DFTolerance     !Defines DF search range
	integer NSyncOK         !Set to 1 if JT65 file synchronized OK
	character*12 mycall
	character*12 hiscall
	character*6 hisgrid
	real ps0(431)           !Spectrum of best ping
	integer npkept          !Number of pings kept and decoded
	integer lumsg           !Logical unit for decoded.txt
	real basevb             !Baseline signal level, dB
	integer nslim2          !Minimum strength for single-tone pings, dB
	real psavg(450)         !Average spectrum of the whole file
	integer Nseg            !First or second Tx sequence?
	integer MouseDF         !Freeze position for DF
	logical pick            !True if this is a mouse-picked ping
	logical stbest          !True if the best decode was Single-Tone
	logical STfound         !True if at least one ST decode
	logical LDecoded        !True if anything was decoded
	real s2(64,3100)        !2D spectral array
	real ccf(-5:540)        !X-cor function in JT65 mode (blue line)
	real red(512)
	real ss1(-224:224)	!Magenta curve (for JT65 shorthands)
	real ss2(-224:224)	!Orange curve (for JT65 shorthands)
	real yellow(216)
	real yellow0(216)
	real fzap(200)
	integer resample
	real*8 samfacin,samratio
	real dat2(NP2)
	character msg3*3
	character cfile6*6
	logical lcum
	integer indx(100)
	character*90 line
	common/avecom/dat(NP2),labdat,jza,modea
	common/ccom/nline,tping(100),line(100)
	common/limcom/ nslim2a
	common/clipcom/ nclip
	save

	lcum=.true.
	jz=jz0
	modea=Mode
	nclip=NQRN-5
	nslim2a=nclip
	MinWidth=40                            !Minimum width of pings, ms
	call zero(psavg,450)
	rewind 11
	rewind 12

 	do i=1,40
	   if(FileID(i:i).eq.'.') go to 3
	enddo
	i=4
 3	ia=max(1,i-6)
        cfile6=FileID(ia:i-1)

	nline=0
	ndiag=0
! If file "/wsjt.reg" exists, set ndiag=1
	open(16,file='/wsjt.reg',status='old',err=4)
	ndiag=1
	close(16)

 4	if(jz.gt.655360) jz=655360

	sum=0.
	do j=1,jz            !Convert raw data from i*2 to real, remove DC
           dat(j)=0.1*d(j)
	   sum=sum + dat(j)
	enddo
	ave=sum/jz
	samratio=1.d0/samfacin
	if(samratio.eq.1.d0) then
	   do j=1,jz
	      dat(j)=dat(j)-ave
	   enddo
	else
	   do j=1,jz
	      dat2(j)=dat(j)-ave
	   enddo

#if (USE_PORTAUDIO==1)  || defined(Win32)
	   ierr=resample(dat2,dat,samratio,jz)
	   if(ierr.ne.0) print*,'Resample error.',samratio
#endif

	endif

	if(ndiag.ne.0 .and. nclip.lt.0) then
C  Intentionally degrade SNR by -nclip dB.
	   sq=0.
	   do i=1,jz
	      sq=sq + dat(i)**2
	   enddo
	   p0=sq/jz
	   p1=p0*10.0**(-0.1*nclip)
	   dnoise=sqrt(4*(p1-p0))
	   idum=-1
	   do i=1,jz
	      dat(i)=dat(i) + dnoise*gran(idum)
	   enddo
	endif

	sq=0.
	do j=1,jz                  !Compute power level for whole array
	   sq=sq + dat(j)**2
	enddo
	avesq=sq/jz
	basevb=dB(avesq) - 44    !Base power level to send back to GUI
	if(avesq.eq.0) go to 900

	nz=600
	nstep=jz/nz
	sq=0.
	k=0
	do j=1,nz
	   sum=0.
	   do n=1,nstep
	      k=k+1
	      sum=sum+dat(k)**2
	   enddo
	   sum=sum/nstep
	   sq=sq + (sum-avesq)**2
	enddo
	rmspower=sqrt(sq/nz)

	pick=.false.
	if(istart.gt.1) pick=.true. !This is a mouse-picked decoding
   	if(.not.pick .and. (basevb.lt.-15.0 .or. basevb.gt.20.0)) goto 900
	nchan=64                   !Save 64 spectral channels
	nstep=221                  !Set step size to ~20 ms
	nz=jz/nstep - 1            !# of spectra to compute
	if(.not.pick) then
	   MouseButton=0
	   jza=jz
	   labdat=labdat+1
	endif
	tbest=0.
        NsyncOK=0

!  Only JT65 mode is supported.
!  Check for a JT65 shorthand message
	nstest=0
	if(ntx2.ne.1) call short65(dat,jz,NFreeze,MouseDF,
     +     DFTolerance,mode65,nspecial,nstest,dfsh,iderrsh,
     +     idriftsh,snrsh,ss1,ss2,nwsh,idfsh)
!  Lowpass filter and decimate by 2
	call lpf1(dat,jz,jz2,MouseDF,MouseDF2)
	idf=mousedf-mousedf2
	jz=jz2
	nadd=1
	fzap(1)=0.
	if(nzap.eq.1) call avesp2(dat,jz,nadd,mode,NFreeze,MouseDF2,
     +       DFTolerance,fzap)
	if(nzap.eq.1.and.nstest.eq.0) call bzap(dat,jz,nadd,mode,fzap)

	i=index(MyCall,char(0))
	if(i.le.0) i=index(MyCall,' ')
	mycall=MyCall(1:i-1)//'            '
	i=index(HisCall,char(0))
	if(i.le.0) i=index(HisCall,' ')
	hiscall=HisCall(1:i-1)//'            '

!  Offset data by about 1 s.
	if(jz.ge.126*2048) call wsjt65(dat(4097),jz-4096,cfile6,
     +      NClearAve,MinSigdB,DFTolerance,NFreeze,NAFC,mode65,Nseg,
     +      MouseDF2,NAgain,ndepth,neme,nsked,idf,idfsh,
     +      mycall,hiscall,hisgrid,lumsg,lcum,nspecial,ndf,
     +      nstest,dfsh,snrsh,
     +      NSyncOK,ccf,psavg,ndiag,nwsh)

 900	LDecoded = ((NSyncOK.gt.0) .or. npkept.gt.0)
	end file 11
	call flushqqq(11)
	call flushqqq(12)
	call flushqqq(21)

 	return
 	end

