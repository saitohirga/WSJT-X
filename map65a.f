      subroutine map65a

C  Processes timf2 data from Linrad to find and decode JT65 signals.

      parameter (NMAX=60*96000)          !Samples per 60 s file
      parameter (MAXMSG=1000)            !Size of decoded message list
      integer*2 id(4,NMAX)               !46 MB: raw data from Linrad timf2
      parameter (NFFT=32768)             !Half symbol = 17833 samples;
      real ss(4,322,NFFT)                !169 MB: half-symbol spectra
      real savg(4,NFFT)
      real tavg(-50:50)                  !Temp for finding local base level
      real base(4)                       !Local basel level at 4 pol'ns
      real tmp (200)                     !Temp storage for pctile sorting
      real short(3,NFFT)                 !SNR dt ipol for potential shorthands
      real sig(MAXMSG,30)                !Parameters of detected signals
      real a(5)
      character*22 msg(MAXMSG)
      character*3 shmsg0(4),shmsg
      character arg*12,infile*11,outfile*11
      integer indx(MAXMSG),nsiz(MAXMSG)
      logical done(MAXMSG)
      integer rfile3
      character decoded*22,blank*22,cbad*1
      data blank/'                      '/
      data shmsg0/'ATT','RO ','RRR','73 '/

      tskip=0.
      fselect=0.
!      fselect=103.0
      nmin=1
      infile='061111.0745'

C  Initialize some constants

!      open(22,file='kvasd.dat',access='direct',recl=1024,
!     +     status='unknown')
      open(23,file='CALL3.TXT',status='unknown')

!      nbytes=8*(4*96000+9000)           !Empirical, for 061111_0744.dat.48
!      nskip=8*nint(96000*(tskip+4.09375))
!      n=rfile3(infile,id,nskip)          !Skip to start of minute
!      if(n.ne.nskip) go to 9999

      df=96000.0/NFFT                    !df = 96000/NFFT = 2.930 Hz
      fa=0.0
      fb=60000.0
      ia=nint((fa+23000.0)/df + 1.0)     ! 23000 = 48000 - 25000
      ib=nint((fb+23000.0)/df + 1.0)
      ftol=0.020                          !Frequency tolerance (kHz)
      kk=0
      nkk=1

      do nfile=1,nmin
!         n=rfile3(infile,id,8*NMAX)       !Read 60 s of data (approx 46 MB)
         n=8*NMAX
         call rfile3a(infile,id,n,ierr)
         newdat=1
         nz=n/8
         read(infile(8:11),*) nutc
         if(fselect.gt.0.0) then
            nfilt=1                      !nfilt=2 is faster for selected freq
            freq=fselect+1.600
            nflip=-1                     !May need to try both +/- 1
            ipol=4                       !Try all four?
            dt=2.314240                  !Not needed?
            call decode1a(id,newdat,nfilt,freq,nflip,ipol,sync2,
     +           a,dt,pol,nkv,nhist,qual,decoded)
            write(11,1010) nutc,nsync1,nsync2,dt,ndf,decoded,
     +           nkv,nqual
 1010       format(i4.4,i5,i4,f5.1,i5,2x,a22,2i3)
            if(nfile.eq.1) go to 999
         endif

         nfilt=1
         do i=1,NFFT
            short(1,i)=0.
            short(2,i)=0.
            short(3,i)=0.
         enddo

         call symspec(id,nz,ss,savg)

         freq0=-999.
         sync10=-999.
         fshort0=-999.
         sync20=-999.
         ntry=0
         do i=ia,ib                               !Search over freq range
            freq=0.001*((i-1)*df - 23000) + 100.0

C  Find the local base level for each polarization; update every 10 bins.
            if(mod(i-ia,10).eq.0) then
               do jp=1,4
                  do ii=-50,50
                     tavg(ii)=savg(jp,i+ii)
                  enddo
                  call pctile(tavg,tmp,101,50,base(jp))
               enddo
            endif

C  Find max signal at this frequency
            smax=0.
            do jp=1,4
               if(savg(jp,i)/base(jp).gt.smax) smax=savg(jp,i)/base(jp)
            enddo

            if(smax.gt.1.1) then
               ntry=ntry+1
C  Look for JT65 sync patterns and shorthand square-wave patterns.
               call ccf65(ss(1,1,i),sync1,ipol,dt,flipk,
     +                syncshort,snr2,ipol2,dt2)

               shmsg='   '
C  Is there a shorthand tone above threshold?
               if(syncshort.gt.1.0) then

C### Do shorthand AFC here (or maybe after finding a pair?) ###

                  short(1,i)=syncshort
                  short(2,i)=dt2
                  short(3,i)=ipol2
C  Check to see if lower tone of shorthand pair was found.
                  do j=2,4
                     i0=i-nint(j*53.8330078/df)
C  Should this be i0 +/- 1, or just i0?
C  Should we also insist that difference in DT be either 1.5 or -1.5 s?
                     if(short(1,i0).gt.1.0) then
                        fshort=0.001*((i0-1)*df - 23000) + 100.0

C  Keep only the best candidate within ftol.
                        if(fshort-fshort0.le.ftol .and. sync2.gt.sync20
     +                         .and. nkk.eq.2) kk=kk-1
                        if(fshort-fshort0.gt.ftol .or. 
     +                                            sync2.gt.sync20) then
                           kk=kk+1
                           sig(kk,1)=nfile
                           sig(kk,2)=nutc
                           sig(kk,3)=fshort
                           sig(kk,4)=syncshort
                           sig(kk,5)=dt2
                           sig(kk,6)=45*(ipol2-1)/57.2957795
                           sig(kk,7)=0
                           sig(kk,8)=snr2
                           sig(kk,9)=0
                           sig(kk,10)=0
!                           sig(kk,11)=rms0
                           sig(kk,12)=savg(ipol2,i)
                           sig(kk,13)=0
                           sig(kk,14)=0
                           sig(kk,15)=0
                           sig(kk,16)=0
!                           sig(kk,17)=0
                           sig(kk,18)=0
                           msg(kk)=shmsg0(j)
                           fshort0=fshort
                           sync20=sync2
                           nkk=2
                        endif
                     endif
                  enddo
               endif

C  Is sync1 above threshold?
               if(sync1.gt.1.0) then

C  Keep only the best candidate within ftol.
C  (Am I deleting any good decodes by doing this?  Any harm in omitting
C  these statements??)
                  if(freq-freq0.le.ftol .and. sync1.gt.sync10 .and. 
     +                 nkk.eq.1) kk=kk-1

                  if(freq-freq0.gt.ftol .or. sync1.gt.sync10) then
                     nflip=nint(flipk)

                     call decode1a(id,newdat,nfilt,freq,nflip,ipol,
     +                    sync2,a,dt,pol,nkv,nhist,qual,decoded)

                     kk=kk+1
                     sig(kk,1)=nfile
                     sig(kk,2)=nutc
                     sig(kk,3)=freq
                     sig(kk,4)=sync1
                     sig(kk,5)=dt
                     sig(kk,6)=pol
                     sig(kk,7)=flipk
                     sig(kk,8)=sync2
                     sig(kk,9)=nkv
                     sig(kk,10)=qual
!                     sig(kk,11)=rms0                  
                     sig(kk,12)=savg(ipol,i)
                     sig(kk,13)=a(1)
                     sig(kk,14)=a(2)
                     sig(kk,15)=a(3)
                     sig(kk,16)=a(4)
!                     sig(kk,17)=a(5)
                     sig(kk,18)=nhist
                     msg(kk)=decoded
                     freq0=freq
                     sync10=sync1
                     nkk=1
                  endif
               endif
            endif
         enddo

!         write(*,1010)

C  Trim the list and produce a sorted index and sizes of groups.
C  (Should trimlist remove all but best SNR for given UTC and message content?)
         call trimlist(sig,kk,indx,nsiz,nz)

         do i=1,kk
            done(i)=.false.
         enddo
         j=0
         ilatest=-1
         do n=1,nz
            ifile0=0
            do m=1,nsiz(n)
               i=indx(j+m)
               ifile=sig(i,1)
               if(ifile.gt.ifile0 .and.msg(i).ne.blank) then
                  ilatest=i
                  ifile0=ifile
               endif
            enddo
            i=ilatest
            if(i.ge.1) then
               if(.not.done(i)) then
                  done(i)=.true.
                  nutc=sig(i,2)
                  freq=sig(i,3)
                  sync1=sig(i,4)
                  dt=sig(i,5)
                  npol=nint(57.2957795*sig(i,6))
                  flip=sig(i,7)
                  sync2=sig(i,8)
                  nkv=sig(i,9)
                  nqual=min(sig(i,10),10.0)
!                  rms0=sig(i,11)
                  nsavg=sig(i,12)                   !Was used for diagnostic ...
                  do k=1,5
                     a(k)=sig(i,12+k)
                  enddo
                  nhist=sig(i,18)
                  decoded=msg(i)

                  if(flip.lt.0.0) then
                     do i=22,1,-1
                        if(decoded(i:i).ne.' ') go to 10
                     enddo
                     stop 'Error in message format'
 10                  if(i.le.18) decoded(i+2:i+4)='OOO'
                  endif
                  nkHz=nint(freq-1.600)
                  f0=144.0+0.001*nkHz
                  ndf=nint(1000.0*(freq-1.600-nkHz))
                  ndf0=nint(a(1))
                  ndf1=nint(a(2))
                  ndf2=nint(a(3))
                  nsync1=sync1
                  nsync2=nint(10.0*log10(sync2)) - 40 !### empirical ###
                  cbad=' '

                  if(abs(f0-144.103).lt.0.001) then
                     write(11,1010) nutc,nsync1,nsync2,dt,ndf,decoded,
     +                    nkv,nqual
                  endif

                  write(19,1012) f0,ndf,npol,nutc,decoded
 1012             format(f7.3,i5,i4,i5.4,2x,a22)

                  write(26,1014) f0,ndf,ndf0,ndf1,ndf2,dt,npol,nsync1,
     +                 nsync2,nutc,decoded,nkv,nqual,nhist
 1014             format(f7.3,i5,3i3,f5.1,i5,i3,i4,i5.4,2x,a22,3i3)

               endif
            endif
            j=j+nsiz(n)
         enddo
         call display(nutc)
!         if(nfile.ge.1) go to 999
 100     continue
      enddo

 999  call four2a(cx,-1,1,1,1)  !Destroy the FFTW plans

 9999 end
