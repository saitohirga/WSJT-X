subroutine jt65a(dd,npts,newdat,nutc,nfa,nfqso,ntol,nagain,ndecoded)

!  Process dd() data to find and decode JT65 signals.

  parameter (NSZ=3413)
  parameter (NZMAX=60*12000)
  parameter (NFFT=8192)
  real dd(NZMAX)
  real*4 ss(322,NSZ)
  real*4 savg(NSZ)
  logical done(NSZ)
  real a(5)
  character decoded*22
  save

  if(newdat.ne.0) then
     call timer('symsp65 ',0)
     call symspec65(dd,npts,ss,nhsym,savg)    !Get normalized symbol spectra
     call timer('symsp65 ',1)
  endif

  df=12000.0/NFFT                     !df = 12000.0/16384 = 0.732 Hz
  ftol=16.0                           !Frequency tolerance (Hz)
  mode65=1                            !Decoding JT65A only, for now.
  done=.false.
  freq0=-999.

  do nqd=1,0,-1
     if(nqd.eq.1) then                !Quick decode, at fQSO
        fa=nfqso - ntol
        fb=nfqso + ntol
     else                             !Wideband decode at all freqs
        fa=200
        fb=nfa
     endif
     ia=max(51,nint(fa/df))
     ib=min(NSZ-51,nint(fb/df))
     
     thresh0=1.5

     do i=ia,ib                               !Search over freq range
        if(savg(i).lt.thresh0 .or. done(i)) cycle
        freq=i*df

        call timer('ccf65   ',0)
        call ccf65(ss(1,i),nhsym,savg(i),sync1,dt,flipk,syncshort,snr2,dt2)
        call timer('ccf65   ',1)

! ########################### Search for Shorthand Messages #################
!  include 'shorthand1.f90'

! ########################### Search for Normal Messages ###########
        thresh1=1.0
!  Use lower thresh1 at fQSO
        if(nqd.eq.1 .and. ntol.le.100) thresh1=0.

!  Is sync1 above threshold?
        if(sync1.lt.thresh1) cycle

!  Keep only the best candidate within ftol.
        if(freq-freq0.lt.ftol) cycle

        nflip=nint(flipk)
        call timer('decod65a',0)
        call decode65a(dd,npts,newdat,freq,nflip,mode65,sync2,a,dt,   &
             nbmkv,nhist,decoded)
        call timer('decod65a',1)

!        write(71,3001) ia,ib,i,nfqso,freq0,freq,freq+a(1),decoded
!3001    format(4i6,3f10.3,2x,a22)
!        call flush(71)

        if(freq+a(1)-freq0.lt.ftol) cycle

        if(decoded.ne.'                      ') then
           ndecoded=1
           nfreq=nint(freq+a(1))
           ndrift=nint(2.0*a(2))
           s2db=10.0*log10(sync2) - 32             !### empirical (was 40) ###
           nsnr=nint(s2db)
           if(nsnr.lt.-30) nsnr=-30
           if(nsnr.gt.-1) nsnr=-1
           write(*,1010) nutc,nsnr,dt,nfreq,decoded
1010       format(i4.4,i4,f5.1,i5,1x,'#',1x,a22)
           write(13,1012) nutc,nint(sync1),nsnr,dt,float(nfreq),ndrift,  &
                decoded,nbmkv
1012       format(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22,' JT65',i4)
           freq0=freq+a(1)
           i2=min(NSZ,i+15)                !### ??? ###
           done(i:i2)=.true.
        endif
     enddo
     if(nagain.eq.1) exit
  enddo

  return
end subroutine jt65a
