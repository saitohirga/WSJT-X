      subroutine lpf1(dat,jz,nz,mousedf,mousedf2)

      parameter (NMAX=1024*1024)
      parameter (NMAXH=NMAX)
      real dat(jz),x(NMAX)
      complex c(0:NMAXH)
      equivalence (x,c)

C  Find FFT length
      xn=log(float(jz))/log(2.0)
      n=xn
      if((xn-n).gt.0.) n=n+1
      nfft=2**n
      nh=nfft/2

C  Load data into real array x; pad with zeros up to nfft.
      do i=1,jz
         x(i)=dat(i)
      enddo
      if(nfft.gt.jz) call zero(x(jz+1),nfft-jz)
C  Do the FFT
      call xfft(x,nfft)
      df=11025.0/nfft

      ia=70/df
      do i=0,ia
         c(i)=0.
      enddo
      ia=5000.0/df
      do i=ia,nh
         c(i)=0.
      enddo

C  See if frequency needs to be shifted:
      ndf=0
      if(mousedf.lt.-600) ndf=-670
      if(mousedf.gt.600) ndf=1000
      if(mousedf.gt.1600) ndf=2000
      if(mousedf.gt.2600) ndf=3000

      if(ndf.ne.0) then
C  Shift frequency up or down by ndf Hz:
         i0=nint(ndf/df)
         if(i0.lt.0) then
            do i=nh,-i0,-1
               c(i)=c(i+i0)
            enddo
            do i=0,-i0-1
               c(i)=0.
            enddo
         else
            do i=0,nh-i0
               c(i)=c(i+i0)
            enddo
         endif
      endif

      mousedf2=mousedf-ndf            !Adjust mousedf
      call four2a(c,nh,1,1,-1)        !Return to time domain
      fac=1.0/nfft
      nz=jz/2
      do i=1,nz
         dat(i)=fac*x(i)
      enddo

      return
      end
