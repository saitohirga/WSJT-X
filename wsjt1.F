	subroutine wsjt1(d,jz0,istart,samfacin,FileID,ndepth,MinSigdB,
     +    NQRN,DFTolerance,NSaveCum,MouseButton,NClearAve,
     +    Mode,NFreeze,NAFC,NZap,AppDir,utcdate,mode441,mode65,
     +    MyCall,HisCall,HisGrid,neme,nsked,naggressive,ntx2,s2,
     +    ps0,npkept,lumsg,basevb,rmspower,nslim2,psavg,ccf,Nseg,
     +    MouseDF,NAgain,LDecoded,nspecial,ndf,ss1,ss2)

	parameter (NP2=1024*1024)

	integer*2 d(jz0)        !Buffer for raw one-byte data
	integer istart          !Starting location in original d() array
	character FileID*40     !Name of file being processed
	integer MinSigdB        !Minimum ping strength, dB
	integer NQRN            !QRN rejection parameter
	integer DFTolerance     !Defines DF search range
	integer NSaveCum        !Set to 1 if cumulative file is to be saved
	integer NSyncOK         !Set to 1 if JT65 file synchronized OK
	character AppDir*80     !Installation directory for WSJT
	character*12 utcdate
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

	integer*1 dtmp
	character msg3*3
	character cfile6*6
	character fname*99,fcum*99
	logical lcum
	integer indx(100)
	character*90 line
	character*24 today

	common/avecom/dat(NP2),labdat,jza,modea
	common/avecom2/f0a
	common/ccom/nline,tping(100),line(100)
	common/limcom/ nslim2a
	common/clipcom/ nclip
	equivalence (dtmp,ntmp)
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
	if(mode.eq.4 .and. jz.gt.330750) jz=330750	!### Fix this!

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

#ifdef Win32
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

	if(mode.ne.2 .and. nzap.ne.0) then
	   if(jz.gt.100000) call avesp2(dat,jz,2,f0a,NFreeze,MouseDF,
     +         DFTolerance,fzap)
	   nadd=1
 	   call bzap(dat,jz,nadd,mode,fzap)
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

!  If we're in JT65 mode, call the decode65 routines.
  	if(mode.eq.2) then
! 	   if(rmspower.gt.34000.0) go to 900     !Reject very noisy data
!  Check for a JT65 shorthand message
 	   nstest=0
 	   if(ntx2.ne.1) call short65(dat,jz,NFreeze,MouseDF,
     +        DFTolerance,mode65,nspecial,nstest,dfsh,iderrsh,
     +        idriftsh,snrsh,ss1,ss2,nwsh)
!  Lowpass filter and decimate by 2
 	   call lpf1(dat,jz,jz2)
 	   jz=jz2
 	   nadd=1
 	   fzap(1)=0.
 	   if(nzap.eq.1) call avesp2(dat,jz,nadd,f0a,NFreeze,MouseDF,
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
     +        NClearAve,MinSigdB,DFTolerance,NFreeze,NAFC,mode65,Nseg,
     +        MouseDF,NAgain,ndepth,neme,nsked,
     +        mycall,hiscall,hisgrid,lumsg,lcum,nspecial,ndf,
     +        nstest,dfsh,iderrsh,idriftsh,snrsh,
     +        NSyncOK,ccf,psavg,ndiag,nwsh)
 	   goto 900
 	endif

! If we're in JT6M mode, call the 6M decoding routines.
	if(mode.eq.4) then
	   do i=1,jz                    !### Why is it level-sensitive?
	      dat(i)=dat(i)/25.0
	   enddo
! For waterfall plot
	   call spec2d(dat,jz,nstep,s2,nchan,nz,psavg,sigma)
	   if(sigma.lt.0.0) basevb=-99.0
	   if(jz/11025.0.lt.3.9 .or. sigma.lt.0.0) go to 900

	   f0=1076.66
	   if(NFreeze.eq.1) f0=1076.66+mousedf
	   call syncf0(dat,jz,NFreeze,DFTolerance,jstart,f0,smax)
	   call synct(dat,jz,jstart,f0,smax)
	   call syncf1(dat,jz,jstart,f0,NFreeze,DFTolerance,smax,red)

	   f0a=f0
	   do i=1,512
	      ccf(i-6)=dB(red(i))
	   enddo
	   df=11025./256.
	   do i=1,64
	      sum=0.
	      do k=8*i-7,8*i
		 sum=sum+red(k)
	      enddo
	      psavg(i)=5.0*sum
	      fac=1.0
	      freq=i*df
	      if(freq.gt.2500.0) fac=((freq-2500.)/20.0)**(-1.0)
	      psavg(i)=fac*psavg(i)
	      psavg(i+64)=0.001
	   enddo

	   jz=jz-jstart+1
	   nslim=MinSigdB
	   NFixLen=0
	   call decode6m(dat(jstart),jz,cfile6,nslim,istart,
     +       NFixLen,lcum,f0,lumsg,npkept,yellow)
	   if(npkept.eq.0) f0a=0.

	   if(pick) then
	      do i=1,216
		 ps0(i)=yellow0(i)
	      enddo
	   else
	      ps0(216)=yellow(216)
	      yellow0(216)=yellow(216)
	      do i=1,215
		 ps0(i)=2*yellow(i)
		 yellow0(i)=ps0(i)
	      enddo
	   endif
	   goto 800
	endif

!  We're in FSK441 mode. Compute the 2D spectrum.
	df=11025.0/256.0            !FFT resolution ~43 Hz
	dtbuf=nstep/11025.0
	stlim=nslim2                !Single-tone threshold
	call spec2d(dat,jz,nstep,s2,nchan,nz,psavg,sigma)
	if(sigma.lt.0.0) basevb=-99.0
	if(sigma.lt.0.0) go to 900
	nline0=nline
	STfound=.false.
	npkept=0

C  Look for single-tone messages
	if((.not.pick) .or. MouseButton.eq.1) then
	   call stdecode(s2,nchan,nz,sigma,dtbuf,df,stlim,
     +       DFTolerance,cfile6,pick,istart)
	endif
	if(nline.gt.nline0) STfound=.true.  !ST message(s) found

C  Now the multi-tone decoding
	call mtdecode(dat,jz,s2,nchan,nz,MinSigdB,MinWidth,
     +    NQRN,DFTolerance,istart,pick,MouseButton,NSaveCum,
     +    cfile6,ps0)

	npkept=nline             !Number of pings that were kept
	smax=0.
	stbest=.false.
	if(npkept.gt.0) then
	   call indexx(npkept,tping,indx) !Merge the ST and MT decodes
	   do i=1,npkept
	      j=indx(i)
	      if(pick .and. STFound .and.
     +          line(j)(29:31).eq.'   ') goto 10
	      write(lumsg,1050) line(j)	!Write to decoded.txt
 1050	      format(a79)
	      if(lcum) write(21,1050) line(j) !Write to decoded.cum
	      read(line(j),1060) sig,msg3
 1060	      format(16x,f3.0,9x,a3)
	      if(sig.gt.smax) then
		 smax=sig
		 tbest=tping(j)
		 stbest = (msg3.ne.'   ')
	      endif
 10	   enddo
	endif

	dt=1.0/11025.0                !Compute spectrum for pink curve
	if(stbest) then
	   jj=nint(tbest/dt)
	   call spec441(dat(jj),1102,ps0,f0)
	endif

 800	continue
        call s2shape(s2,nchan,nz,tbest)

 900	continue
	end file 11
	LDecoded = ((NSyncOK.gt.0) .or. npkept.gt.0)

 	return
 	end

