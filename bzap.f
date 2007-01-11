      subroutine bzap(dat,jz,nadd,mode,fzap)

      parameter (NMAX=1024*1024)
      parameter (NMAXH=NMAX)
      real dat(jz),x(NMAX)
      real fzap(200)
      complex c(NMAX)
      equivalence (x,c)

      xn=log(float(jz))/log(2.0)
      n=xn
      if((xn-n).gt.0.) n=n+1
      nfft=2**n
      nh=nfft/nadd
      nq=nh/2
      do i=1,jz
         x(i)=dat(i)
      enddo
      if(nfft.gt.jz) call zero(x(jz+1),nfft-jz)

      call xfft(x,nfft)

C  This is a kludge:
      df=11025.0/(nadd*nfft)
      if(mode.eq.2) df=11025.0/(2*nadd*nfft)

      tol=10.
      itol=nint(2.0/df)
      do izap=1,200
         if(fzap(izap).eq.0.0) goto 10
         ia=(fzap(izap)-tol)/df 
         ib=(fzap(izap)+tol)/df
         smax=0.
         do i=ia+1,ib+1
            s=real(c(i))**2 + aimag(c(i))**2
            if(s.gt.smax) then
               smax=s
               ipk=i
            endif
         enddo
         fzap(izap)=df*(ipk-1)

         do i=ipk-itol,ipk+itol
            c(i)=0.
         enddo
      enddo

 10   ia=70/df
      do i=1,ia
         c(i)=0.
      enddo
      ia=2700.0/df
      do i=ia,nq+1
         c(i)=0.
      enddo
      do i=2,nq
         c(nh+2-i)=conjg(c(i))
      enddo

      call four2a(c,nh,1,1,-1)
      fac=1.0/nfft
      do i=1,jz/nadd
         dat(i)=fac*x(i)
      enddo

      return
      end
