      subroutine avesp2(dat,jza,nadd,f0,mode,NFreeze,MouseDF,
     +  DFTolerance,fzap)

      real dat(jza)
      integer DFTolerance
      real psa(1024)                 !Ave ps, flattened and rolled off
      real ref(557)                  !Ref spectrum, lines excised
      real birdie(557)               !Birdie spectrum (ave-ref)
      real variance(557)
      real s2(557,323)
      real fzap(200)

      iz=557                              !Compute the 2d spectrum
      df=11025.0/2048.0
      nfft=nadd*1024
      jz=jza/nfft
      do j=1,jz
         k=(j-1)*nfft + 1
         call ps(dat(k),nfft,psa)
         call move(psa,s2(1,j),iz)
      enddo

C  Flatten s2 and get psa, ref, and birdie
      call flatten(s2,557,jz,psa,ref,birdie,variance)

      call zero(fzap,200)
      ia=300/df
      ib=2700/df
      n=0
      fmouse=0.
      if(mode.eq.2) fmouse=1270.46+MouseDF
      if(mode.eq.4) fmouse=1076.66+MouseDF

      do i=ia,ib
         if(birdie(i)-ref(i).gt.3.0) then
            f=i*df

C  Don't zap unless Freeze is OFF or birdie is outside the "Tol" range.
            if(NFreeze.eq.0 .or. 
     +           abs(f-fmouse).gt.float(DFTolerance)) then
               if(n.lt.200 .and. variance(i-1).lt.2.5 .and.
     +              variance(i).lt.2.5.and.variance(i+1).lt.2.5) then
                  n=n+1
                  fzap(n)=f
               endif
            endif

         endif
      enddo

      return
      end
