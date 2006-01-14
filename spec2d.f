	subroutine spec2d(data,jz,nstep,s2,nchan,nz,psavg0,sigma)

C  Computes 2d spectrogram for FSK441 single-tone search and waterfall
C  display.

	parameter (NFFT=256)
	parameter (NR=NFFT+2)
	parameter (NH=NFFT/2)
	parameter (NQ=NFFT/4)

	real data(jz)
	real s2(nchan,nz)
	real x(NR)
	real w1(7),w2(7)
	real psavg(128)
	real psavg0(128)
	real ps2(128)
	complex c(0:NH)
	common/acom/a1,a2,a3,a4
	common/fcom/s(3100),indx(3100)
	equivalence (x,c)
	save

	df=11025.0/NFFT

C  Compute the 2d spectrogram s2(nchan,nz).  Note that in s2 the frequency
C  bins are shifted down 5 bins from their natural positions.

	call set(0.0,psavg,NH)
	do n=1,nz
	   j=1 + (n-1)*nstep
	   call move(data(j),x,NFFT)
	   call xfft(x,NFFT)

	   sum=0.
	   do i=1,NQ
	      s2(i,n)=real(c(5+i))**2 + imag(c(5+i))**2
	      sum=sum+s2(i,n)
	   enddo
	   s(n)=sum/NQ

C  Accumulate average spectrum for the whole file.
	   do i=1,nh
	      psavg0(i) = psavg0(i)+ real(c(i))**2 + imag(c(i))**2
	   enddo
	enddo
	if(sum.eq.0.0) then
	   sigma=-999.
	   go to 999
	endif

C  Normalize and save a copy of psavg0 for plotting.  Roll off the
C  spectrum at 300 and 3000 Hz.
	do i=1,nh
	   psavg0(i)=3.e-5*psavg0(i)/nz
	   f=df*i
	   fac=1.0
	   if(f.lt.300.0) fac=f/300.0
	   if(f.gt.3000.0) fac=max(0.00333,(3300.0-f)/300.0)
	   psavg0(i)=(fac**2)*psavg0(i)
	enddo

C  Compute an average spectrum from the weakest 25% of time slices.
	call indexx(nz,s,indx)
	call zero(ps2,NQ)
	do j=1,nz/4
	   k=indx(j)
	   do i=1,NQ
	      ps2(i+5)=ps2(i+5)+s2(i,k)
	   enddo
	enddo
	ps2(1)=ps2(5)
	ps2(2)=ps2(5)
	ps2(3)=ps2(5)
	ps2(4)=ps2(5)
	sum=0.
	do i=6,59
	   sum=sum+ps2(i)
	enddo

C  Compute a smoothed spectrum without local peaks, and find its max.
	smaxx=0.
	do i=4,NQ
	   sum=0.
	   do k=1,7
	      w1(k)=ps2(i+k-4)
	      sum=sum+w1(k)
	   enddo
	   ave=sum/7.0
	   if(i.ge.14 .and. i.le.58) then
	      call pctile(w1,w2,7,50,base)
	      ave=0.25*(w2(1)+w2(2)+w2(3)+w2(4))
	   endif
	   psavg(i)=ave
	   smaxx=max(psavg(i),smaxx)
	enddo

C  Save scale factors for flattening spectra of pings.
	a1=1.0
	a2=psavg(nint(2*441/df))/psavg(nint(3*441/df))
	a3=psavg(nint(2*441/df))/psavg(nint(4*441/df))
	a4=psavg(nint(2*441/df))/psavg(nint(5*441/df))
	afac=4.0/(a1+a2+a3+a4)
	a1=afac*a1
	a2=afac*a2
	a3=afac*a3
	a4=afac*a4

C  Normalize 2D spectrum by the average based on weakest 25% of time
C  slices, smoothed, and with local peaks removed.

	do i=1,NQ
	   do j=1,nz
	      s2(i,j)=s2(i,j)/max(psavg(i+5),0.01*smaxx)
	   enddo
	enddo

C  Find average of active spectral region, over the whole file.
	sum=0.
	do i=9,52
	   do j=1,nz
	      sum=sum+s2(i,j)
	   enddo
	enddo
	sigma=sum/(44*nz)

 999	return
	end
