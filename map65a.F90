subroutine map65a(newdat)

!  Processes timf2 data from Linrad to find and decode JT65 signals.

  parameter (MAXMSG=1000)            !Size of decoded message list
  real tavg(-50:50)                  !Temp for finding local base level
  real base(4)                       !Local basel level at 4 pol'ns
  real tmp (200)                     !Temp storage for pctile sorting
  real sig(MAXMSG,30)                !Parameters of detected signals
  real a(5)
  character*22 msg(MAXMSG)
  character*3 shmsg0(4),shmsg
  integer indx(MAXMSG),nsiz(MAXMSG)
  logical done(MAXMSG)
  character decoded*22,blank*22
  include 'spcom.f90'
  real short(3,NFFT)                 !SNR dt ipol for potential shorthands
  real qphi(12)
  include 'gcom2.f90'
  include 'datcom.f90'
  data blank/'                      '/
  data shmsg0/'ATT','RO ','RRR','73 '/
  data nfile/0/,nutc0/-999/,nid/0/,ip000/1/,ip001/1/
  save

  pctlost=nlost/331.03
  if(ndebug.eq.2) write(*,3001) nutc,mod(int(sec_midn()),60),nlost,pctlost
3001 format('mod65a  1:',i5.4,i3.2,i8,f7.2,' %')

  rewind 11
  rewind 12
  if(nrw26.ne.0) then
     endfile (26)              !Compiler bug?  Don't write "end file 26" !!!
     rewind 26
     nrw26=0
  endif

#ifdef Win32
  open(23,file='CALL3.TXT',status='unknown',share='denynone')
#else
  open(23,file='CALL3.TXT',status='unknown')
#endif

  if(nutc.ne.nutc0) nfile=nfile+1
  nutc0=nutc
  nutcdata=nutc
  df=96000.0/NFFT                     !df = 96000/NFFT = 2.930 Hz
  ftol=0.020                          !Frequency tolerance (kHz)
  foffset=0.001*(1270 + nfcal)
  fselect=mousefqso + foffset
  nfilt=1
  dphi=idphi/57.2957795

  do i=12,3,-1
     if(hiscall(i:i).ne.' ') go to 1
  enddo
  i=0
1 len_hiscall=i

  iloop=0
2 if(ndphi.eq.1) dphi=30*iloop/57.2957795
  do nqd=1,0,-1
     if(nqd.eq.1) then                     !Quick decode, at fQSO
        fa=1000.0*(fselect+0.001*mousedf-100.0) - dftolerance
        fb=1000.0*(fselect+0.001*mousedf-100.0) + dftolerance
        ia=nint((fa+23000.0)/df + 1.0)     ! 23000 = 48000 - 25000
        ib=nint((fb+23000.0)/df + 1.0)
     else                                  !Wideband decode at all freqs
        fa=1000*(nfa-100)
        fb=1000*(nfb-100)
        ia=nint((fa+23000.0)/df + 1.0)     ! 23000 = 48000 - 25000
        ib=nint((fb+23000.0)/df + 1.0)
     endif

     km=0
     nkm=1
     nz=n/8

     do i=1,NFFT
        short(1,i)=0.
        short(2,i)=0.
        short(3,i)=0.
     enddo

     freq0=-999.
     sync10=-999.
     fshort0=-999.
     sync20=-999.
     ntry=0
     do i=ia,ib                               !Search over freq range
        call sleep_msec(0)
        freq=0.001*((i-1)*df - 23000) + 100.0

!  Find the local base level for each polarization; update every 10 bins.
        if(mod(i-ia,10).eq.0) then
           do jp=1,4
              do ii=-50,50
                 tavg(ii)=savg(jp,i+ii)
              enddo
              call pctile(tavg,tmp,101,50,base(jp))
           enddo
        endif

!  Find max signal at this frequency
        smax=0.
        do jp=1,4
           if(savg(jp,i)/base(jp).gt.smax) smax=savg(jp,i)/base(jp)
        enddo

        if(smax.gt.1.1) then
           ntry=ntry+1
!  Look for JT65 sync patterns and shorthand square-wave patterns.
           call ccf65(ss(1,1,i),nhsym,sync1,ipol,dt,flipk,              &
                syncshort,snr2,ipol2,dt2)

! ########################### Search for Shorthand Messages #################
           shmsg='   '
!  Is there a shorthand tone above threshold?
           if(syncshort.gt.1.0) then

! ### Do shorthand AFC here (or maybe after finding a pair?) ###

              short(1,i)=syncshort
              short(2,i)=dt2
              short(3,i)=ipol2
!  Check to see if lower tone of shorthand pair was found.
              do j=2,4
                 i0=i-nint(j*53.8330078/df)
!  Should this be i0 +/- 1, or just i0?
!  Should we also insist that difference in DT be either 1.5 or -1.5 s?
                 if(short(1,i0).gt.1.0) then
                    fshort=0.001*((i0-1)*df - 23000) + 100.0

!  Keep only the best candidate within ftol.
!### NB: sync2 was not defined here!
!###                    sync2=syncshort                   !### try this ???
                    if(fshort-fshort0.le.ftol .and. sync2.gt.sync20    &
                         .and. nkm.eq.2) km=km-1
                    if(fshort-fshort0.gt.ftol .or.                     &
                         sync2.gt.sync20) then
                       km=km+1
                       sig(km,1)=nfile
                       sig(km,2)=nutc
                       sig(km,3)=fshort
                       sig(km,4)=syncshort
                       sig(km,5)=dt2
                       sig(km,6)=45*(ipol2-1)/57.2957795
                       sig(km,7)=0
                       sig(km,8)=snr2
                       sig(km,9)=0
                       sig(km,10)=0
!                           sig(km,11)=rms0
                       sig(km,12)=savg(ipol2,i)
                       sig(km,13)=0
                       sig(km,14)=0
                       sig(km,15)=0
                       sig(km,16)=0
!                           sig(km,17)=0
                       sig(km,18)=0
                       msg(km)=shmsg0(j)
                       fshort0=fshort
                       sync20=sync2
                       nkm=2
                    endif
                 endif
              enddo
           endif

! ########################### Search for Normal Messages ###########
!  Is sync1 above threshold?
           thresh1=1.0
           if(nqd.eq.1 .and. dftolerance.le.100) thresh1=0.  !Lower threshold at fQSO
           if(sync1.gt.thresh1) then

!  Keep only the best candidate within ftol.
!  (Am I deleting any good decodes by doing this?)
              if(freq-freq0.le.ftol .and. sync1.gt.sync10 .and.               &
                   nkm.eq.1) km=km-1
              if(freq-freq0.gt.ftol .or. sync1.gt.sync10) then
                 nflip=nint(flipk)
                 call decode1a(id(1,1,kbuf),newdat,nfilt,freq,nflip,        &
                      mycall,hiscall,hisgrid,neme,ndepth,nqd,dphi,ndphi,    &
                      ipol,sync2,a,dt,pol,nkv,nhist,qual,decoded)

!  If hiscall or hisgrid is in decoded message, save the pol'n angle.
                 i1=index(decoded,hiscall(1:len_hiscall))
                 i2=index(decoded,hisgrid(1:4))
                 if(i1.ge.5 .or. i2.ge.9) then
                    nhispol=nint(57.2957795*pol)
                 endif
                 km=km+1
                 sig(km,1)=nfile
                 sig(km,2)=nutc
                 sig(km,3)=freq
                 sig(km,4)=sync1
                 sig(km,5)=dt
                 sig(km,6)=pol
                 sig(km,7)=flipk
                 sig(km,8)=sync2
                 sig(km,9)=nkv
                 sig(km,10)=qual
!                 sig(km,11)=idphi
                 sig(km,12)=savg(ipol,i)
                 sig(km,13)=a(1)
                 sig(km,14)=a(2)
                 sig(km,15)=a(3)
                 sig(km,16)=a(4)
!                     sig(km,17)=a(5)
                 sig(km,18)=nhist
                 msg(km)=decoded
                 freq0=freq
                 sync10=sync1
                 nkm=1
              endif
           endif
        endif
     enddo
     if(nqd.eq.1) then
        nwrite=0
        do k=1,km
           decoded=msg(k)
           if(decoded.ne.'                      ') then
              nutc=sig(k,2)
              freq=sig(k,3)
              sync1=sig(k,4)
              dt=sig(k,5)
              npol=nint(57.2957795*sig(k,6))
              flip=sig(k,7)
              sync2=sig(k,8)
              nkv=sig(k,9)
              nqual=sig(k,10)
!              idphi=nint(sig(k,11))
              if(flip.lt.0.0) then
                 do i=22,1,-1
                    if(decoded(i:i).ne.' ') go to 8
                 enddo
                 stop 'Error in message format'
8                if(i.le.18) decoded(i+2:i+4)='OOO'
              endif
              nkHz=nint(freq-foffset)
              f0=144.0+0.001*nkHz
              ndf=nint(1000.0*(freq-foffset-nkHz))
!              ndf0=nint(a(1))
!              ndf1=nint(a(2))
!              ndf2=nint(a(3))
              nsync1=sync1
              nsync2=nint(10.0*log10(sync2)) - 40 !### empirical ###
              if(decoded(1:4).eq.'RO  ' .or. decoded(1:4).eq.'RRR  ' .or.  &
                 decoded(1:4).eq.'73  ') nsync2=nsync2-6
              nw=0                                !### Fix this! ###
              nwrite=nwrite+1
              if(ndphi.eq.0) then
                 write(11,1010) nkHz,ndf,npol,nutc,dt,nsync2,decoded,nkv,nqual
1010             format(i3,i5,i4,i5.4,f5.1,i4,2x,a22,i5,i4,i4)
              else
		 if(iloop.ge.1) qphi(iloop)=sig(k,10)
                 write(11,1010) nkHz,ndf,npol,nutc,dt,nsync2,decoded,nkv,  &
                      nqual,30*iloop
                 write(27,1011) 30*iloop,nkHz,ndf,npol,nutc,  &
                      dt,sync2,nkv,nqual,decoded
1011             format(i3,i4,i5,i4,i5.4,f5.1,f7.1,i3,i5,2x,a22)
              endif
           endif
        enddo
        if(nwrite.eq.0) then
           write(11,1012) mousefqso,nutc
1012          format(i3,9x,i5.4)
        endif
   
     endif
     if(ndphi.eq.1 .and.iloop.lt.12) then
        iloop=iloop+1
        go to 2
     endif
     if(ndphi.eq.1 .and.iloop.eq.12) call getdphi(qphi)
     if(nqd.eq.1) then
        write(11,*) '$EOF'
        call flushqqq(11)
        ndecdone=1
        t2=sec_midn()
        if(ndebug.eq.2) write(*,3002) mod(int(t2),60)
3002    format('mod65a  2:'i8.2)
     endif
     if(nagain.eq.1) go to 999
  enddo

!  Trim the list and produce a sorted index and sizes of groups.
!  (Should trimlist remove all but best SNR for given UTC and message content?)
  call trimlist(sig,km,indx,nsiz,nz)

  do i=1,km
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
10            if(i.le.18) decoded(i+2:i+4)='OOO'
           endif
           nkHz=nint(freq-foffset)
           f0=144.0+0.001*nkHz
           ndf=nint(1000.0*(freq-foffset-nkHz))
           ndf0=nint(a(1))
           ndf1=nint(a(2))
           ndf2=nint(a(3))
           nsync1=sync1
           nsync2=nint(10.0*log10(sync2)) - 40 !### empirical ###
           if(decoded(1:4).eq.'RO  ' .or. decoded(1:4).eq.'RRR  ' .or.  &
                decoded(1:4).eq.'73  ') nsync2=nsync2-6
           write(26,1014) f0,ndf,ndf0,ndf1,ndf2,dt,npol,nsync1,       &
                nsync2,nutc,decoded,nkv,nqual,nhist
           write(21,1014) f0,ndf,ndf0,ndf1,ndf2,dt,npol,nsync1,       &
                nsync2,nutc,decoded,nkv,nqual,nhist
1014       format(f7.3,i5,3i3,f5.1,i5,i3,i4,i5.4,2x,a22,3i3)

        endif
     endif
     j=j+nsiz(n)
  enddo
  write(26,1015) nutc
1015 format(39x,i4.4)
  call flushqqq(26)
  call display(nkeep,ncsmin)
  ndecdone=2

  if(nsave.gt.0 .and. ndiskdat.eq.0) call savetf2(id(1,1,kbuf),nsave,   &
       ntime,nutc,savedir)

999 close(23)
  ndphi=0
  if(kbuf.eq.1) kkdone=60*96000
  if(kbuf.eq.2 .or. ndiskdat.eq.1) kkdone=0
  kk=kkdone
  if(nagain.eq.0) then
     t3=sec_midn()
     if(ndebug.eq.2) write(*,3003) mod(int(t3),60)
3003 format('mod65a  3:'i8.2)
     if(ndebug.eq.1) write(*,3004) nutc,mod(t2,60.0),mod(t3,60.0),    &
          nlost,pctlost
3004 format('mod65a:',i5.4,1x,2f6.1,i6,f8.2,' %')
  endif
  nagain=0

  return
end subroutine map65a
