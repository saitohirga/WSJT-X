program fer65

! End-to-end simulator for testing JT65.

! Options 
!  jt65sim                             jt65
!----------------------------------------------------------------
!                                      -a aggressive
!  -d Doppler spread                   -d depth
!  -f Number of files                  -f freq
!  -m (sub)mode                        -m (sub)mode
!  -n number of generated sigs         -n ntrials
!  -t Time offset (s)                  -r robust sync
!  -p Do not seed random #s            -c mycall
!                                      -x hiscall
!                                      -g hisgrid
!                                      -X hinted-decode flags
!  -s S/N in 2500 Hz                   -s single-decode mode

  implicit real*8 (a-h,o-z)
  real*8 s(7),sq(7)
  character arg*12,cmnd*100,decoded*22,submode*1,csync*1,f1*15,f2*15
  character*12 outfile
  logical syncok

  nargs=iargc()
  if(nargs.ne.7) then
     print*,'Usage:   fer65 submode fspread snr1 snr2 Navg  DS  iters'
     print*,'Example: fer65    C      3.0   -28  -12    8    1  1000'
     go to 999
  endif

  call getarg(1,submode)
  call getarg(2,arg)
  read(arg,*) d
  call getarg(3,arg)
  read(arg,*) snr1
  call getarg(4,arg)
  read(arg,*) snr2
  call getarg(5,arg)
  read(arg,*) navg
  call getarg(6,arg)
  read(arg,*) nds
  call getarg(7,arg)
  read(arg,*) iters

  write(outfile,1001) submode,d,navg,nds
1001 format(a1,f6.2,'_',i2.2,'_',i1)
  if(outfile(2:2).eq.' ') outfile(2:2)='0'
  if(outfile(3:3).eq.' ') outfile(3:3)='0'

  ndepth=3
  if(navg.gt.1) ndepth=ndepth+16
  if(nds.ne.0) ndepth=ndepth+32

  dfmax=3
  if(submode.eq.'b' .or. submode.eq.'B') dfmax=6
  if(submode.eq.'c' .or. submode.eq.'C') dfmax=11

  ntrials=1000
  naggressive=10

  open(20,file=outfile,status='unknown')
  open(21,file='fer65.21',status='unknown')

  write(20,1000) submode,iters,ntrials,naggressive,d,ndepth,navg,nds
1000 format(/'JT65',a1,'  Iters:',i5,'  T:',i6,'  Aggr:',i3,  &
          '  Dop:',f6.2,'  Depth:',i2,'  Navg:',i3,'  DS:',i2)
  write(20,1002) 
1002 format(/'  dB  nsync ngood nbad     sync       dsnr        ',     &
            'DT       Freq      Nsum     Width'/85('-'))
  flush(20)

  do isnr=0,20
     snr=snr1+isnr
     if(snr.gt.snr2) exit
     nsync=0
     ngood=0
     nbad=0
     s=0.
     sq=0.
     do iter=1,iters
        write(cmnd,1010) submode,d,snr,navg
1010    format('./jt65sim -n 1 -m ',a1,' -d',f7.2,' -s \\',f5.1,' -f',i3,' >devnull')
        call unlink('000000_????.wav')
        call system(cmnd)
        if(navg.gt.1) then
           do i=navg,2,-1
              j=2*i-1
              write(f1,1011) i
              write(f2,1011) j
1011          format('000000_',i4.4,'.wav')
              call rename(f1,f2)
           enddo
        endif
        call unlink('decoded.txt')
        call unlink('fort.13')
        isync=0
        nsnr=0
        dt=0.
        nfreq=0
        ndrift=0
        nwidth=0
        cmnd='./jt65 -m A -a 10 -c K1ABC -f 1500 -n 1000 -d  5 -s 000000_????.wav > decoded.txt'
        cmnd(11:11)=submode
        write(cmnd(47:48),'(i2)') ndepth
        call system(cmnd)
        open(13,file='fort.13',status='old',err=20)
        do i=1,navg
           read(13,1012) nutc,isync,nsnr,dt,nfreq,ndrift,nwidth,decoded,     &
             nft,nsum,nsmo
1012       format(i4,i4,i5,f6.2,i5,i4,i3,1x,a22,5x,3i3)
           if(nft.gt.0) exit
        enddo
        close(13)
        syncok=abs(dt).lt.0.2 .and. float(abs(nfreq-1500)).lt.dfmax
        csync=' '
        if(syncok) csync='*'
        write(21,1014) nutc,isync,nsnr,dt,nfreq,ndrift,nwidth,     &
             nft,nsum,nsmo,csync,decoded(1:16),nft,nsum,nsmo
1014    format(i4,i4,i5,f6.2,i5,i4,3x,4i3,1x,a1,1x,a16,i2,2i3)
        flush(21)

        if(syncok) then
           nsync=nsync+1
           s(1)=s(1) + isync
           sq(1)=sq(1) + isync*isync
           s(6)=s(6) + nwidth
           sq(6)=sq(6) + nwidth*nwidth
           if(decoded.eq.'K1ABC W9XYZ EN37      ') then
              ngood=ngood+1
              s(2)=s(2) + nsnr
              s(3)=s(3) + dt
              s(4)=s(4) + nfreq
              s(5)=s(5) + ndrift
              s(7)=s(7) + nsum

              sq(2)=sq(2) + nsnr*nsnr
              sq(3)=sq(3) + dt*dt
              sq(4)=sq(4) + nfreq*nfreq
              sq(5)=sq(5) + ndrift*ndrift
              sq(7)=sq(7) + nsum*nsum
           else if(decoded.ne.'                      ') then
              nbad=nbad+1
              print*,'Nbad:',nbad,decoded
           endif
        endif
20      continue
        fsync=float(nsync)/iter
        fgood=float(ngood)/iter
        fbad=float(nbad)/iter
        write(*,1020) nint(snr),iter,isync,nsnr,dt,nfreq,ndrift,nwidth,fsync,  &
             fgood,fbad,decoded(1:16),nft,nsum,nsmo
1020    format(i3,i5,i3,i4,f6.2,i5,i3,i3,2f6.3,f7.4,1x,a16,i2,2i3)
     enddo

     if(nsync.ge.1) then
        xsync=s(1)/nsync
        xwidth=s(6)/nsync
     endif
     esync=0.
     if(nsync.ge.2) then
        esync=sqrt(sq(1)/nsync - xsync**2)
        ewidth=sqrt(sq(6)/nsync - xwidth**2)
     endif

     if(ngood.ge.1) then
        xsnr=s(2)/ngood
        xdt=s(3)/ngood
        xfreq=s(4)/ngood
        xdrift=s(5)/ngood
        xsum=s(7)/ngood
     endif
     if(ngood.ge.2) then
        esnr=sqrt(sq(2)/ngood - xsnr**2)
        edt=sqrt(sq(3)/ngood - xdt**2)
        efreq=sqrt(sq(4)/ngood - xfreq**2)
        edrift=sqrt(sq(5)/ngood - xdrift**2)
        esum=sqrt(sq(7)/ngood - xsum**2)
     endif

     dsnr=xsnr-snr
     dfreq=xfreq-1500.0
     if(ngood.eq.0) then
        dsnr=0.
        dfreq=0.
     endif
     write(20,1100) snr,nsync,ngood,nbad,xsync,esync,dsnr,esnr,  &
          xdt,edt,dfreq,efreq,xsum,esum,xwidth,ewidth
1100 format(f5.1,2i6,i4,2f6.1,f6.1,f5.1,f6.2,f5.2,6f5.1)
     flush(20)
     if(ngood.ge.int(0.99*iters)) exit
  enddo

999 end program fer65
