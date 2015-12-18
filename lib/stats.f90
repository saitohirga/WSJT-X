program stats

  character*8 arg
  character*40 infile
  character decoded*22

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: stats file1 ...'
     go to 999
  endif

  ttol=0.1
  nftol=1
  write(*,1000)
1000 format(' SNR  Nsigs  Sync    BM    FT  Hint Total  False BadSync'/  &
          67('-'))

  do ifile=1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,status='old')
     i1=index(infile,".")
     read(infile(i1+1:i1+2),*) snrgen
     snrgen=-snrgen
     nsynced=0
     nbm=0
     nftok=0
     nhint=0
     ngood=0
     nbad=0
     nbadsync=0

     do iline=1,999999
        read(10,1010,end=100) nutc,nsync,nsnr,dt,nfreq,ncandidates,nhard,  &
             ntotal,ntry,naggressive,nft,nqual,decoded
1010    format(i4.4,i3,i4,f6.2,i5,i7,i3,i4,i8,i3,i2,i5,1x,a22)
        ndfreq=9999
        do ifreq=600,2400,200
           n=abs(nfreq-ifreq)
           if(n.lt.ndfreq) ndfreq=n
        enddo

        if(nsync.ge.3 .and. abs(dt).le.ttol .and. ndfreq.le.nftol) then
           nsynced=nsynced+1
        else
           nbadsync=nbadsync+1
        endif
        if(decoded.eq.'                      ') cycle
        if(decoded(1:11).eq.'K1ABC W9XYZ') then
           ngood=ngood+1
           if(ncandidates.eq.0) nbm=nbm+1
           if(nft.eq.1) nftok=nftok+1
           if(nft.ge.1) nhint=nhint+1
        else
           nbad=nbad+1
        endif
     enddo

100  write(*,1100) snrgen,10*nutc,nsynced,nbm,nftok,nhint,ngood,nbad,   &
          nbadsync
1100 format(f5.1,8i6)
  enddo

999 end program stats
