! Variable             Purpose                              Set in Thread
!-------------------------------------------------------------------------
real ps0               !Spectrum of best ping, FSK441/JT6m      Decoder
real psavg             !Average spectrum                        Decoder
integer*2 d2a          !Rx data, extracted from y1              Decoder
integer*2 d2b          !Rx data, selected by mouse-pick         Decoder
integer*2 b            !Pixel values for waterfall spectrum     GUI
integer shok           !Shorthand messages OK?                  GUI
integer sendingsh      !Sending a shorthand message?            SoundIn
integer dftolerance    !DF tolerance (Hz)                       GUI
logical LDecoded       !Was a message decoded?                  Decoder
logical rxdone         !Has the Rx sequence finished?      SoundIn,Decoder
character mycall*12    !My call sign                            GUI
character hiscall*12   !His call sign                           GUI
character hisgrid*6    !His grid locator                        GUI
character txmsg*28     !Message to be transmitted               GUI
character sending*28   !Message being sent                      SoundIn
character mode*6       !WSJT operating mode                     GUI
character utcdate*12   !UTC date                                GUI
character*24 fname0    !Filenames to be recorded, read, ...     Decoder
character*24 fnamea
character*24 fnameb
character*24 decodedfile
character*80 AppDir      !WSJT installation directory           GUI
character*80 filetokilla !Filenames (full path)                 Decoder
character*80 filetokillb

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
