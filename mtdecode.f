      subroutine mtdecode(dat,jz,nz,MinSigdB,MinWidth,
     +    NQRN,DFTolerance,istart,pick,cfile6,ps0)

C  Decode Multi-Tone FSK441 mesages.

      real dat(jz)                !Raw audio data
      integer NQRN
      integer DFTolerance
      logical pick
      character*6 cfile6,cf*1

      real sigdb(3100)             !Detected signal in dB, sampled at 20 ms
      real work(3100)
      integer indx(3100)
      real pingdat(3,100)
      real ps(128)
      real ps0(128)
      character msg*40,msg3*3
      character*90 line
      common/ccom/nline,tping(100),line(100)

      slim=MinSigdB
      wmin=0.001*MinWidth * (19.95/20.0)
      nf1=-DFTolerance
      nf2=DFTolerance
      msg3='   '
      nq=64
      dt=1.0/11025.0
      df=11025.0/256.0

C  Find signal power at suitable intervals to search for pings.
      istep=221
      dtbuf=istep/11025.
      do n=1,nz
         s=0.
         ib=n*istep
         ia=ib-istep+1
         do i=ia,ib
            s=s+dat(i)**2
         enddo
         sigdb(n)=s/istep
      enddo

!#####################################################################
      if(.not.pick) then
! Remove initial transient from sigdb
         call indexx(nz,sigdb,indx)
         imax=0
         do i=1,50
            if(indx(i).gt.50) go to 10
            imax=max(imax,indx(i))
         enddo
 10      do i=1,50
            if(indx(nz+1-i).gt.50) go to 20
            imax=max(imax,indx(nz+1-i))
         enddo
 20      imax=imax+6            !Safety margin
         base1=sigdb(indx(nz/2))
         do i=1,imax
            sigdb(i)=base1
         enddo
      endif
!##################################################################

      call smooth(sigdb,nz)

C  Remove baseline and one dB for good measure.
      call pctile (sigdb,work,nz,50,base1)
      do i=1,nz
         sigdb(i)=dB(sigdb(i)/base1) - 1.0
      enddo

      call ping(sigdb,nz,dtbuf,slim,wmin,pingdat,nping)

C  If this is a "mouse pick" and no ping was found, force a pseudo-ping 
C  at center of data.
	if(pick.and.nping.eq.0) then
           if(nping.le.99) nping=nping+1
	   pingdat(1,nping)=0.5*jz*dt
	   pingdat(2,nping)=0.16
	   pingdat(3,nping)=1.0
	endif

      bigpeak=0.
      do iping=1,nping
C  Find starting place and length of data to be analyzed:
         tstart=pingdat(1,iping)
         width=pingdat(2,iping)
         peak=pingdat(3,iping)
         mswidth=10*nint(100.0*width)
         jj=(tstart-0.02)/dt
         if(jj.lt.1) jj=1
         jjz=nint((width+0.02)/dt)+1
         jjz=min(jjz,jz+1-jj)

C  Compute average spectrum of this ping.
         call spec441(dat(jj),jjz,ps,f0)

C  Decode the message.
         msg=' '
         call longx(dat(jj),jjz,ps,DFTolerance,noffset,msg,
     +     msglen,bauderr)
         qrnlimit=4.4*1.5**(5.0-NQRN)
         if(NQRN.eq.0) qrnlimit=99.
         if(msglen.eq.0) go to 100

C  Assemble a signal report:
         nwidth=0
         if(width.ge.0.04) nwidth=1     !These might depend on NSPD
         if(width.ge.0.12) nwidth=2
         if(width.gt.1.00) nwidth=3
         nstrength=6
         if(peak.ge.11.0) nstrength=7
         if(peak.ge.17.0) nstrength=8
         if(peak.ge.23.0) nstrength=9

!         if(peak.gt.5.0 .and.mswidth.ge.100) then
!            call specsq(dat(jj),jjz,DFTolerance,0,noffset2)
!            noffset=noffset2
!         endif

C  Discard this ping if DF outside tolerance limits or bauderr too big.
C  (However, if the ping was mouse-picked, proceed anyway.)

         if(.not.pick .and. ((noffset.lt.nf1 .or. noffset.gt.nf2) .or.
     +      (abs(bauderr).gt.qrnlimit))) goto 100 

C  If it's the best ping yet, save the spectrum:
         if(peak.gt.bigpeak) then
            bigpeak=peak
            do i=1,128
               ps0(i)=ps(i)
            enddo
         endif
   
         tstart=tstart + dt*(istart-1)
         cf=' '
         if(nline.le.99) nline=nline+1
         tping(nline)=tstart
         snr=10.0*log10(10.0**(0.1*peak)-1.0)
         write(line(nline),1050) cfile6,tstart,mswidth,int(peak),
     +        nwidth,nstrength,noffset,msg3,msg,cf
 1050    format(a6,f5.1,i5,i3,1x,2i1,i5,1x,a3,1x,a40,1x,a1)
 100  enddo

      return
      end
