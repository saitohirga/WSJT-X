subroutine qra_loops(c00,npts2,mode,mode64,nsubmode,nFadingModel,      &
     ndepth,nc1,nc2,ng2,naptype,jpk0,xdt,f0,width,snr2,irc,dat4)

  use packjt
  use timer_module, only: timer
  parameter (LN=1152*63)
  character*37 decoded
  complex c00(0:720000)            !Analytic representation of dd(), 6000 Hz
  complex c0(0:720000)             !Ditto, with freq shift
  real a(3)                        !twkfreq params f,f1,f2
  real s3(LN)                      !Symbol spectra
  integer dat4(12),dat4x(12)       !Decoded message (as 12 integers)
  integer nap(0:11)                !AP return codes
  data nap/0,2,3,2,3,4,2,3,6,4,6,6/

  irc=-99
  s3lim=20.
  ibwmax=11
  if(mode64.le.4) ibwmax=9
  ibwmin=ibwmax
  idtmax=3
  call qra_params(ndepth,maxaptype,idfmax,idtmax,ibwmin,ibwmax)
  LL=64*(mode64+2)
  NN=63
  napmin=99
  ncall=0
  nsps=3456                                   !QRA64
  if(mode.eq.65) nsps=3840                    !QRA65  ### Is 3840 too big? ###
  maxdist=5
  if(ndepth.eq.2) maxdist=10
  if(ndepth.eq.3) maxdist=30

  do idf=1,idfmax
     ndf=idf/2
     if(mod(idf,2).eq.0) ndf=-ndf
     a=0.
     a(1)=-(f0+0.4*ndf)
     call twkfreq(c00,c0,npts2,6000.0,a)
     do idt=1,idtmax
        ndt=idt/2
        if(mod(idt,2).eq.0) ndt=-ndt
        jpk=jpk0 + 240*ndt                  !240/6000 = 0.04 s = tsym/32
        if(jpk.lt.0) jpk=0
        call timer('spec64  ',0)
        call spec64(c0,nsps,mode,jpk,s3,LL,NN)
        call timer('spec64  ',1)
        call pctile(s3,LL*NN,40,base)
        s3=s3/base
        where(s3(1:LL*NN)>s3lim) s3(1:LL*NN)=s3lim
        do ibw=ibwmax,ibwmin,-2
           ndist=ndf**2 + ndt**2 + ((ibwmax-ibw)/2)**2
           if(ndist.gt.maxdist) cycle
           b90=1.728**ibw
           if(b90.gt.230.0) cycle
           if(b90.lt.0.15*width) exit
           ncall=ncall+1
           call timer('qra64_de',0)
           call qra64_dec(s3,nc1,nc2,ng2,naptype,0,nSubmode,b90,      &
                nFadingModel,dat4,snr2,irc)
           call timer('qra64_de',1)
           if(irc.eq.0) go to 200
           if(irc.gt.0) call badmsg(irc,dat4,nc1,nc2,ng2)
           iirc=max(0,min(irc,11))
           if(irc.gt.0 .and. nap(iirc).lt.napmin) then
              dat4x=dat4
              b90x=b90
              snr2x=snr2
              napmin=nap(iirc)
              irckeep=irc
              xdtkeep=jpk/6000.0 - 1.0
              f0keep=-a(1)
              idfkeep=idf
              idtkeep=idt
              ibwkeep=ibw
              ndistx=ndist
              go to 100   !###
           endif
        enddo  ! ibw (b90 loop)
!###        if(iand(ndepth,3).lt.3 .and. irc.ge.0) go to 100
     enddo  ! idt (DT loop)
  enddo  ! idf (f0 loop)

100 if(napmin.ne.99) then
     dat4=dat4x
     b90=b90x
     snr2=snr2x
     irc=irckeep
     xdt=xdtkeep
     f0=f0keep
     idt=idtkeep
     idf=idfkeep
     ibw=ibwkeep
     ndist=ndistx
  endif

200 if(mode.eq.65) xdt=xdt+0.4        !### Empirical -- WHY ??? ###

!### For tests only:
  if(irc.ge.0) then
     open(53,file='fort.53',status='unknown',position='append')
     call unpackmsg(dat4,decoded)               !Unpack the user message
     write(53,3053) idf,idt,ibw,b90,xdt,f0,snr2,ndist,irc,decoded(1:22)
3053 format(3i5,f7.1,f7.2,2f7.1,2i5,2x,a22)
     close(53)
  endif
!###  
  return
end subroutine qra_loops
