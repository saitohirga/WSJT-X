program fer65

! End-to-end simulator for testing JT65.

! Options 
! jt65sim                             jt65sim
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
  real*8 s(5),sq(5)
  character arg*12,cmnd*100,decoded*22,submode*1,csync*1
  logical syncok

  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:   fer65 submode fspread snr1 snr2 iters'
     print*,'Example: fer65    C      3.0   -28  -12  1000'
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
  read(arg,*) iters

  dfmax=min(d,0.5*2.69)
  if(submode.eq.'b' .or. submode.eq.'B') dfmax=min(d,2.69)
  if(submode.eq.'c' .or. submode.eq.'C') dfmax=min(d,2.0*2.69)
  if(dfmax.lt.0.5*2.69) dfmax=0.5*2.69

  ntrials=1000
  naggressive=10

  open(20,file='fer65.20',status='unknown')
  open(21,file='fer65.21',status='unknown')

  write(20,1000) iters,ntrials,naggressive,d
1000 format('Iters:',i6,'   T:',i7,'   Aggressive:',i3,'   Doppler:',f6.1)
  write(20,1002) 
1002 format('  dB  nsync ngood nbad    sync       snr         ',    &
            'DT        Freq       Drift'/77('-'))

  do isnr=0,20
     snr=snr1+isnr
     if(snr.gt.snr2) exit

     nsync=0
     ngood=0
     nbad=0
     s=0.
     sq=0.
     do iter=1,iters
        write(cmnd,1010) submode,d,snr
1010    format('./jt65sim -n 1 -m ',a1,' -d',f6.1,' -s \\',f5.1,' >devnull')
        call unlink('000000_0001.wav')
!        print*,cmnd
        call system(cmnd)
        call unlink('decoded.txt')
        call unlink('fort.13')
        isync=0
        nsnr=0
        dt=0.
        freq=0.
        ndrift=0
        cmnd='./jt65 -m A -a 10 -f 1500 -n 1000 -d 3 -s -X 32 000000_0001.wav > decoded.txt'
        cmnd(11:11)=submode
!        print*,cmnd
        call system(cmnd)
        open(13,file='fort.13',status='old',err=20)
        read(13,1012) nutc,isync,nsnr,dt,freq,ndrift,decoded,nft,nsum,nsmo
1012    format(i4,i4,i5,f6.2,f8.0,i4,3x,a22,5x,3i3)
        close(13)
        syncok=abs(dt).lt.0.2 .and. abs(freq-1500.0).lt.dfmax
        csync=' '
        if(syncok) csync='*'
        write(21,1014) nutc,isync,nsnr,dt,freq,ndrift,nft,nsum,nsmo,csync,   &
             decoded(1:16)
1014    format(i4,i4,i5,f6.2,f8.0,i4,3x,3i3,1x,a1,1x,a16)

        if(syncok) then
           nsync=nsync+1
           if(decoded.eq.'K1ABC W9XYZ EN37      ') then
              ngood=ngood+1
              s(1)=s(1) + isync
              s(2)=s(2) + nsnr
              s(3)=s(3) + dt
              s(4)=s(4) + freq
              s(5)=s(5) + ndrift

              sq(1)=sq(1) + isync*isync
              sq(2)=sq(2) + nsnr*nsnr
              sq(3)=sq(3) + dt*dt
              sq(4)=sq(4) + freq*freq
              sq(5)=sq(5) + ndrift*ndrift
           else if(decoded.ne.'                      ') then
              nbad=nbad+1
              print*,nbad,decoded
           endif
        endif
20      continue
        fsync=float(nsync)/iter
        fgood=float(ngood)/iter
        fbad=float(nbad)/iter
        write(*,1020) iter,isync,nsnr,dt,int(freq),ndrift,fsync,fgood,fbad,  &
             decoded(1:16)
1020    format(i8,2i4,f7.2,i6,i4,2f7.3,f10.6,1x,a16)
     enddo

     if(ngood.ge.1) then
        xsync=s(1)/ngood
        xsnr=s(2)/ngood
        xdt=s(3)/ngood
        xfreq=s(4)/ngood
        xdrift=s(5)/ngood
     endif
     if(ngood.ge.2) then
        esync=sqrt(sq(1)/ngood - xsync**2)
        esnr=sqrt(sq(2)/ngood - xsnr**2)
        edt=sqrt(sq(3)/ngood - xdt**2)
        efreq=sqrt(sq(4)/ngood - xfreq**2)
        edrift=sqrt(sq(5)/ngood - xdrift**2)
     endif

     dsnr=xsnr-snr
     write(20,1100) snr,nsync,ngood,nbad,xsync,esync,dsnr,esnr,  &
          xdt,edt,xfreq,efreq,xdrift,edrift
1100 format(f5.1,2i6i4,2f6.1,f6.1,f5.1,f6.2,f5.2,f7.1,3f5.1)
     flush(20)

  enddo

999 end program fer65
