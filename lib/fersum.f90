program fersum

  character mode*5
  character infile*40
  real dop(0:9)
  real thresh(0:9,12),threshsync(0:9,12)
  data dop/0.25,0.5,1.0,2.0,4.0,8.0,16.0,32.0,64.0,128.0/

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: fersum <infile>'
     go to 999
  endif
  call getarg(1,infile)
  open(10,file=infile,status='old')
  thresh=0.
  threshsync=0.

  do iblk=1,999
1    read(10,1002,end=100) mode,iters,ntot,naggr,d,navg,nds
1002 format(a5,8x,i5,4x,i6,7x,i3,6x,f6.2,17x,i3,5x,i2)
     write(33,*) iblk,mode
     if(mode.eq.'     ') go to 1
     read(10,1002)
     read(10,1002)
     read(10,1002)

     nsync0=0
     ngood0=0
     xsum0=0.
     do n=1,99
        read(10,1010,end=100) snr,nsync,ngood,nbad,xsync,esync,dsnr,esnr,   &
             xdt,edt,dfreq,efreq,xsum,esum,xwidth,ewidth
1010    format(f5.1,2i6i4,2f6.1,f6.1,f5.1,f6.2,f5.2,6f5.1)
        if(snr.eq.0.0) exit
        if(mode(5:5).eq.'A') nmode=1
        if(mode(5:5).eq.'B') nmode=2
        if(mode(5:5).eq.'C') nmode=3
        j=nint(log(d)/log(2.0) + 2.0)
        if(navg.eq.1 .and. nds.eq.0) k=nmode
        if(navg.eq.1 .and. nds.eq.1) k=nmode+3
        if(navg.gt.1 .and. nds.eq.0) k=nmode+6
        if(navg.gt.1 .and. nds.eq.1) k=nmode+9
        if(nsync0.le.iters/2 .and. nsync.ge.iters/2) then
           threshsync(j,k)=snr-float(nsync-iters/2)/(nsync-nsync0)
        endif
        if(ngood0.le.iters/2 .and. ngood.ge.iters/2) then
           threshold=snr-float(ngood-iters/2)/(ngood-ngood0)
           xsumavg=max(1.0,0.5*(xsum0+xsum))
!           write(*,1020) mode,iters,ntot,naggr,d,navg,nds,threshold,xsumavg
!1020       format(a5,i7,i7,i3,f7.2,i3,i3,f7.1,f6.1)
           thresh(j,k)=threshold
        endif
        nsync0=nsync
        ngood0=ngood
        xsum0=xsum
     enddo
  enddo

100 write(12,1100)
1100 format(' ')
  do i=0,9
     write(12,1110) dop(i),thresh(i,1:12)
1110 format(f6.2,13f6.1)
  enddo

  write(12,1110)
  do i=0,9
     write(12,1110) dop(i),threshsync(i,1:12)
  enddo

999 end program fersum
