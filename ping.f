	subroutine ping(s,nz,dtbuf,slim,wmin,pingdat,nping)

C  Detect pings and make note of their start time, duration, and peak strength.

	real*4 s(nz)
	real*4 pingdat(3,100)
	logical inside

	nping=0
	peak=0.
	inside=.false.
c###	sdown=slim-1.0
	snrlim=10.0**(0.1*slim) - 1.0
	sdown=10.0*log10(0.25*snrlim+1.0)

	do i=2,nz
	   if(s(i).ge.slim .and. .not.inside) then
	      i0=i
	      tstart=i0*dtbuf
	      inside=.true.
	      peak=0.
	   endif
	   if(inside .and. s(i).gt.peak) then
	      peak=s(i)
	   endif
	   if(inside .and. (s(i).lt.sdown .or. i.eq.nz)) then
	      if(i.gt.i0) then
		 if(dtbuf*(i-i0).ge.wmin) then
		    if(nping.le.99) nping=nping+1
		    pingdat(1,nping)=tstart
		    pingdat(2,nping)=dtbuf*(i-i0)
		    pingdat(3,nping)=peak
		 endif
	        inside=.false.
	        peak=0.
	     endif
	   endif
	enddo

 	return
	end
