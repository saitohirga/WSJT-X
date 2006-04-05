	subroutine spec441(dat,jz,s,f0)

C  Computes average spectrum over a range of dat, e.g. for a ping.
C  Returns spectral array and frequency of peak value.

	parameter (NFFT=256)
	parameter (NR=NFFT+2)
	parameter (NH=NFFT/2)
	real*4 dat(jz)
	real*4 x(NR),s(NH)
	complex c(0:NH)
	equivalence (x,c)

	call zero(s,NH)
	nz=jz/NFFT
	do n=1,nz
	   j=1 + (n-1)*NFFT
	   call move(dat(j),x,NFFT)
	   call xfft(x,NFFT)
	   do i=1,NH
	      s(i)=s(i)+real(c(i))**2 + aimag(c(i))**2
	   enddo
	enddo

	smax=0.
	df=11025.0/NFFT
	fac=1.0/(100.0*nfft*nz)
	do i=1,nh
	   s(i)=fac*s(i)
	   if(s(i).gt.smax) then
	      smax=s(i)
	      f0=i*df
	   endif
	enddo

 	return
	end
