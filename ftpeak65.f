      subroutine ftpeak65(dat,jz,istart,f0,flip,pr,nafc,ftrack)

C  Do the the JT65 "peakup" procedure in frequency and time; then 
C  compute ftrack.

      parameter (NMAX=30*11025)
      parameter (NS=1024)
      real dat(jz)
      real pr(126)
      real ftrack(126)
      complex c2(NMAX/2)
      complex c3(NMAX/4)
      complex c4(NMAX/16)
      complex c5(NMAX/64)
      complex c6(NMAX/64)
      complex z
      real s(NMAX/64)
      real ccf(-128:128)
      real c(-50:50,8)
      real*8 pha,dpha,twopi,dt,fsyncset

      twopi=8*datan(1.d0)
      fsyncset=-300.d0
      dt=2.d0/11025.d0               !Input dt (WSJT has downsampled by 2)
      call fil651(dat,jz,c2,n2)      !Filter and complex mix; rate 1/2
      dt=2.d0*dt                     !We're now downsampled by 4

      dpha=twopi*dt*(f0-fsyncset)    !Put sync tone at fsyncset
      pha=0.
      do i=1,n2
         pha=pha+dpha
         c2(i)=c2(i) * cmplx(cos(pha),-sin(pha))
      enddo

      call fil652(c2,n2,c3,n3)       !Low-pass at +/- 500 Hz; rate 1/2
      dt=2.d0*dt                     !Down by 8

      dpha=twopi*dt*fsyncset         !Mix sync tone to f=0
      pha=0.
      do i=1,n3
         pha=pha+dpha
         c3(i)=c3(i) * cmplx(cos(pha),-sin(pha))
      enddo

      call fil653(c3,n3,c4,n4)       !Low-pass at +/- 100 Hz; rate 1/4
      dt=4.d0*dt                     !Down by 32

      call fil653(c4,n4,c5,n5)       !Low-pass at +/- 25 Hz; rate 1/4
      dt=4.d0*dt                     !Down by 128

C  Use f0 and istart (as found by sync65) and do CCFs against the 
C  pr(126) array to get improved symbol synchronization.
C  NB: if istart is increased by 64, kpk will decrease by 1.

      k0=nint(istart/64.0 - 7.0)
      call symsync65(c5,n5,k0,s,flip,pr,16,kpk,ccf,smax)

C  Fix up the value of istart.  (The -1 is empirical.)
      istart=istart + 64.0*(kpk-1.0)

C  OK, we have symbol synchronization.  Now find peak ccf value as a 
C  function of DF, for each group of 16 symbols.

C      What about using filter fil657?

      df=0.25*11025.0/4096.0             !Oversample to get accurate peak
      idfmax=50
      iz=n5-31
      do idf=-idfmax,idfmax
         dpha=twopi*idf*df*dt
         pha=0.
         do i=1,iz
            pha=pha+dpha
            c6(i)=c5(i) * cmplx(cos(pha),-sin(pha))
         enddo

         z=0.
         do i=1,32
            z=z + c6(i)
         enddo
         s(1)=real(z)*real(z) + aimag(z)*aimag(z)
         do i=33,n5
            z=z + c6(i) - c6(i-32)
            s(i-31)=real(z)*real(z) + aimag(z)*aimag(z)
         enddo

         do n=1,8
            ia=nint((n-1)*126.0/8.0 + 1.0)
            ib=ia+15
            sum=0.
            do i=ia,ib
               j=32*(i-1) + k0 + kpk
               if(j.ge.1 .and. j.le.iz) sum=sum + flip*pr(i)*s(j)
            enddo
            c(idf,n)=sum/smax
         enddo
      enddo

C  Get drift rate and compute ftrack.
!      call getfdot(c,nafc,ftrack)

      jmax=0
      if(nafc.eq.1) jmax=25
      ssmax=0.
      do j=-jmax,jmax
         do i=-25,25
            ss=0.
            xj=j/7.0
            do n=1,8
               k=nint(i+(n-4.5)*xj)
               ss=ss + c(k,n)
            enddo
            if(ss.gt.ssmax) then
               ssmax=ss
               ipk=i
               jpk=j
            endif
         enddo
      enddo

      df=0.25*11025.0/4096.0
      dfreq=ipk*df
      fdot=jpk*df*60.0/(0.875*46.8)

      do i=1,126
         ftrack(i)=dfreq + fdot*(46.8/60.0)*(i-63.5)/126.0
      enddo

      pha=0.
      i0=k0 + kpk + 2000
      do i=1,iz
         k=nint(63.5 + (i-i0)/32.0)
         if(k.lt.1) k=1
         if(k.gt.126) k=126
         dpha=twopi*dt*ftrack(k)
         pha=pha+dpha
         c6(i)=c5(i) * cmplx(cos(pha),-sin(pha))
      enddo

      z=0.
      do i=1,32
         z=z + c6(i)
      enddo
      s(1)=real(z)*real(z) + aimag(z)*aimag(z)
      do i=33,n5
         z=z + c6(i) - c6(i-32)
         s(i-31)=real(z)*real(z) + aimag(z)*aimag(z)
      enddo

      sum=0.
      do i=1,126
         j=32*(i-1)+k0+kpk
         if(j.ge.1 .and. j.le.iz) sum=sum + flip*pr(i)*s(j)
      enddo

      return
      end
