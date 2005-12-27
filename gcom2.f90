! Variable             Purpose                                  Set by
!-------------------------------------------------------------------------
real ps0               !Spectrum of best ping, FSK441/JT6m      wsjt1
real psavg             !Average spectrum                        wsjt1
integer*2 d2a,d2b,b
integer shok,sendingsh
integer dftolerance
logical LDecoded,rxdone
character mycall*12,hisgrid*6
character hiscall*12,txmsg*28,sending*28,mode*6,utcdate*12
character*24 fname0,fnamea,fnameb,decodedfile
character*80 AppDir,filetokilla,filetokillb

common/gcom2/ps0(431),psavg(450),s2(64,3100),ccf(-5:540),             &
     green(500),ngreen,dgain,iter,ndecoding,ndecoding0,mousebutton,   &
     ndecdone,npingtime,ierr,lauto,mantx,nrestart,ntr,nmsg,nsave,     &
     dftolerance,LDecoded,rxdone,monitoring,nzap,nsavecum,minsigdb,   &
     nclearave,nfreeze,nafc,nmode,mode65,nclip,ndebug,nblank,nport,   &
     mousedf,neme,nsked,naggressive,ntx2,nslim2,nagain,nsavelast,     &
     shok,sendingsh,d2a(661500),d2b(661500),b(60000),jza,jzb,ntime,   &
     idinterval,msmax,lenappdir,ndiskdat,nlines,nflat,ntxreq,ntxnow,  &
     ndepth,nspecial,ndf,ss1(-224:224),ss2(-224:224),                 &
     mycall,hiscall,hisgrid,txmsg,sending,mode,fname0,fnamea,         &
     fnameb,decodedfile,AppDir,filetokilla,filetokillb,utcdate

!### volatile /gcom2/
