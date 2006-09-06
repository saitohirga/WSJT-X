      subroutine spec2d65(dat,jz,nsym,flip,istart,f0,
     +  ftrack,nafc,mode65,s2)

C  Computes the spectrum for each of 126 symbols.
C  NB: At this point, istart, f0, and ftrack are supposedly known.
C  The JT65 signal has Sync bin + 2 guard bins + 64 data bins = 67 bins.
C  We add 5 extra bins at top and bottom for drift, making 77 bins in all.

      parameter (NMAX=2048)                !Max length of FFTs
      real dat(jz)                         !Raw data
      real s2(77,126)                      !Spectra of all symbols
      real s(77)
      real ref(77)
      real ps(77)
      real x(NMAX)
      real ftrack(126)
      real*8 pha,dpha,twopi
      complex cx(NMAX)
c      complex work(NMAX)
      include 'prcom.h'
      equivalence (x,cx)
      data twopi/6.28318530718d0/
      save

C  Peak up in frequency and time, and compute ftrack.
      call ftpeak65(dat,jz,istart,f0,flip,pr,nafc,ftrack)

      nfft=2048/mode65                     !Size of FFTs
      dt=2.0/11025.0
      df=0.5*11025.0/nfft
      call zero(ps,77)
      k=istart-nfft

C  NB: this could be done starting with array c3, in ftpeak65, instead
C  of the dat() array.  Would save some time this way ...

      do j=1,nsym
         call zero(s,77)
         do m=1,mode65
            k=k+nfft
            if(k.ge.1 .and. k.le.(jz-nfft)) then
C  Mix sync tone down to f=5*df (==> bin 6 of array cx, after FFT)
               dpha=twopi*dt*(f0 + ftrack(j) - 5.0*df)
               pha=0.0
               do i=1,nfft         
                  pha=pha+dpha
                  cx(i)=dat(k-1+i)*cmplx(cos(pha),-sin(pha))
               enddo

               call four2a(cx,nfft,1,-1,1)
               do i=1,77
                  s(i)=s(i) + real(cx(i))**2 + aimag(cx(i))**2
               enddo

            else
               call zero(s,77)
            endif
         enddo
         call move(s,s2(1,j),77)
         call add(ps,s,ps,77)
      enddo

C  Flatten the spectra by dividing through by the average of the 
C  "sync on" spectra, with the sync tone explicitly deleted.
      nref=nsym/2
      do i=1,77
C  First we sum all the sync-on spectra:
         ref(i)=0.
         do j=1,nsym
            if(flip*pr(j).gt.0.0) ref(i)=ref(i)+s2(i,j)
         enddo
         ref(i)=ref(i)/nref                 !Normalize
      enddo
C  Remove the sync tone itself:
      base=0.25*(ref(1)+ref(2)+ref(10)+ref(11))
      do i=3,9
         ref(i)=base
      enddo

C  Now flatten the spectra for all the data symbols:
      do i=1,77
         fac=1.0/ref(i)
         do j=1,nsym
            s2(i,j)=fac*s2(i,j)
            if(s2(i,j).eq.0.0) s2(i,j)=1.0   !### To fix problem in mfskprob
         enddo
      enddo

      return
      end
