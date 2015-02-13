subroutine jt65a(dd0,npts,newdat,nutc,nf1,nf2,nfqso,ntol,nagain,ndecoded)

!  Process dd() data to find and decode JT65 signals.

  parameter (NSZ=3413)
  parameter (NZMAX=60*12000)
  parameter (NFFT=8192)
  real dd0(NZMAX)
  real dd(NZMAX)
  real*4 ss(322,NSZ)
  real*4 savg(NSZ)
  logical done(NSZ)
  real a(5)
  character decoded*22
  common/decstats/num65,numbm,numkv,num9,numfano
  save

  dd=0.
  tskip=2.0
  nskip=12000*tskip
  dd(1+nskip:npts+nskip)=dd0(1:npts)
  npts=npts+nskip

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
        fa=nf1
        fb=nf2
     endif
     ia=max(51,nint(fa/df))
     ib=min(NSZ-51,nint(fb/df))
     
     thresh0=1.5

     do i=ia,ib                               !Search over freq range
        freq=i*df
        if(savg(i).lt.thresh0 .or. done(i)) cycle

        call timer('ccf65   ',0)
        call ccf65(ss(1,i),nhsym,savg(i),sync1,dt,flipk,syncshort,snr2,dt2)
        call timer('ccf65   ',1)

        ftest=abs(freq-freq0)
        thresh1=1.0
        if(nqd.eq.1 .and. ntol.le.100) thresh1=0.
        if(sync1.lt.thresh1 .or. ftest.lt.ftol) cycle

        nflip=nint(flipk)
        call timer('decod65a',0)
        call decode65a(dd,npts,newdat,nqd,freq,nflip,mode65,sync2,a,dt,   &
             nbmkv,nhist,decoded)
        call timer('decod65a',1)

        ftest=abs(freq+a(1)-freq0)
        if(ftest.lt.ftol) cycle

        if(decoded.ne.'                      ') then
           ndecoded=1
           nfreq=nint(freq+a(1))
           ndrift=nint(2.0*a(2))
           s2db=10.0*log10(sync2) - 32             !### empirical (was 40) ###
           nsnr=nint(s2db)
           if(nsnr.lt.-30) nsnr=-30
           if(nsnr.gt.-1) nsnr=-1
           dt=dt-tskip
           if(nbmkv.eq.1) numbm=numbm+1
           if(nbmkv.eq.2) numkv=numkv+1 

! Serialize writes - see also decjt9.f90

           !$omp critical(decode_results) 

           write(*,1010) nutc,nsnr,dt,nfreq,decoded
1010       format(i4.4,i4,f5.1,i5,1x,'#',1x,a22)
           write(13,1012) nutc,nint(sync1),nsnr,dt,float(nfreq),ndrift,  &
                decoded,nbmkv
1012       format(i4.4,i4,i5,f6.1,f8.0,i4,3x,a22,' JT65',i4)
           call flush(6)
           call flush(13)
           !$omp end critical(decode_results)

           freq0=freq+a(1)
           i2=min(NSZ,i+15)                !### ??? ###
           done(i:i2)=.true.
        endif
     enddo
     if(nagain.eq.1) exit
  enddo

  return
end subroutine jt65a
