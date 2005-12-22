      subroutine stdecode(s2,nchan,nz,sigma,dtbuf,df,stlim0,
     +    DFTolerance,cfile6,pick,istart)

C  Search for and decode single-tone messages.

      real s2(nchan,nz)
      integer DFTolerance
      logical pick
      character cfile6*6,msg3*3
      character*90 line
      common/ccom/nline,tping(100),line(100)

      NSPD=25                                !Change if FSK110 is implemented
      LTone=2
      NBaud=11025/NSPD

      stlim=stlim0
      if(pick) stlim=stlim0-1.0
      iwidth=1
      ts0=-1.0
      dt=1.0/11025.0

C  In each time slice, find largest peak between LTone*NBaud-DFTolerance and
C  (LTone+3)*NBaud+DFTolerance.

      ia=(LTone*NBaud-DFTolerance)/df - 5.0
      ib=((LTone+3)*NBaud+DFTolerance)/df - 4.0
      do j=1,nz
         smax=0.
         do i=ia,ib                      !Get the spectral peak
            if(s2(i,j).gt.smax) then
               smax=s2(i,j)
               ipk=i
            endif
         enddo
         peak=dB(smax/sigma) - 14.0  !Empirical
C  constant should be dB(43/2500) = -17.6 dB?

         if(peak.gt.stlim) then
C  To minimize false ST decodings from QRN and MT pings, find the
C  second best peak (excluding points around the first peak).
            smax2=0.
            do i=ia,ib
               if((abs(i-ipk).gt.iwidth) .and. s2(i,j).gt.smax2) then
                  smax2=s2(i,j)
                  ipk2=i
               endif
            enddo

C  Larger values of ratlim make it more likely to report ST decodings.
            ratlim=0.18
            if(stlim.lt.-2.5) ratlim=0.20
            if(stlim.lt.-3.5) ratlim=0.22
            if(stlim.lt.-4.5) ratlim=0.24
            if(pick) ratlim=0.27                !Fine tuning here...
            if(smax2/smax.gt.ratlim) goto 20

            call peakup(s2(ipk-1,j),s2(ipk,j),s2(ipk+1,j),dx)
            freq=(ipk+5+dx)*df
            tstart=j*dtbuf + dt*(istart-1)
            mswidth=20
            nwidth=0
            nstrength=0
            n=nint(freq/NBaud)
            noffset=freq-n*NBaud
            if((noffset.lt.-DFTolerance) .or.
     +        (noffset.gt.DFTolerance)) goto 20

C  The numbers 2 and 5 depend on Ltone:
            if(n.lt.2 .or. n.gt.5) goto 20

C  OK, this detection has survived all tests.  Save it for output
C  (uness perhaps it is redundant).

            if(n.eq.LTone)   msg3='R26'
            if(n.eq.LTone+1) msg3='R27'
            if(n.eq.LTone+2) msg3='RRR'
            if(n.eq.LTone+3) msg3='73'

C  Now check for redundant detections.  (Not sure, now, why I chose
C  the time span 0.11 s.)
            if(tstart-ts0.gt.0.11) then
               peak0=0.                 !If time diff>0.11s, start fresh
            else
               if(peak.le.peak0) goto 20
               nline=nline-1            !Delete previous, this one's better
               peak0=peak               !Save best peak
            endif

C  OK, we want to output this one.  Save the information.
            if(nline.le.99) nline=nline+1
            ts0=tstart
            tping(nline)=tstart
            nst=(int(smax/smax2)-4)/2 + 1
            if(nst.lt.1) nst=1
            if(nst.gt.3) nst=3
            write(line(nline),1050) cfile6,tstart,mswidth,int(peak),
     +           nwidth,nstrength,noffset,msg3,nst
 1050       format(a6,f5.1,i5,i3,1x,2i1,i5,1x,a3,40x,i3)
         endif

 20      continue
      enddo

      return
      end
