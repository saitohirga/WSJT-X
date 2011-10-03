      subroutine astro(AppDir,nyear,month,nday,uth,nfreq,Mygrid,
     +     NStation,mode,MoonDX,AzSun,ElSun,AzMoon,ElMoon0,
     +     ntsky,doppler00,doppler,dbMoon,RAMoon,DecMoon,HA,Dgrd,sd,
     +     poloffset,xnr,auxra,auxdec,azaux,elaux)

C  Computes astronomical quantities for display in JT65, CW, and EME Echo mode.
C  NB: may want to smooth the Tsky map to 10 degrees or so.

      character*80 AppDir,fname
      character*6 MyGrid,HisGrid
      logical first,ltsky
      real LST
      real lat,lon
      real ldeg
      integer*1 n1sky(129600)
      integer*2 nsky
      common/sky/ nsky(360,180)
      common/echo/xdop(2),techo,ElMoon,mjd
      equivalence (n1sky,nsky)
      data first/.true./
      data rad/57.2957795/
      save

      if(first) then
	do i=80,1,-1
	   if(ichar(AppDir(i:i)).ne.0 .and. 
     +            ichar(AppDir(i:i)).ne.32) go to 1
	enddo
 1	lenappdir=i
        call zero(nsky,180*180)
	fname=Appdir(1:lenappdir)//'/TSKY.DAT'
        call cs_lock('astro')
#ifdef CVF
        open(13,file=fname,status='old',form='binary',err=10)
        read(13) nsky
        close(13)
#else
        open(13,file=fname,status='old',access='stream',err=10)
        read(13) nsky
        close(13)
#endif
        ltsky=.true.
        first=.false.
        call cs_unlock
      endif
      go to 20
 10   ltsky=.false.
      call cs_unlock

 20   call grid2deg(MyGrid,elon,lat)
      lon=-elon
      call sun(nyear,month,nday,uth,lon,lat,RASun,DecSun,LST,
     +    AzSun,ElSun,mjd)

      freq=nfreq*1.e6

      call MoonDop(nyear,month,nday,uth,lon,lat,RAMoon,DecMoon,
     +  LST,HA,AzMoon,ElMoon,ldeg,bdeg,vr,dist)

C  Compute spatial polarization offset
      xx=sin(lat/rad)*cos(ElMoon/rad) - cos(lat/rad)*
     +     cos(AzMoon/rad)*sin(ElMoon/rad)
      yy=cos(lat/rad)*sin(AzMoon/rad)
      if(NStation.eq.1) poloffset1=rad*atan2(yy,xx)
      if(NStation.eq.2) poloffset2=rad*atan2(yy,xx)

      techo=2.0 * dist/2.99792458e5                 !Echo delay time
      doppler=-freq*vr/2.99792458e5                 !One-way Doppler
      t408=ftsky(ldeg,bdeg)                         !Read sky map
      tsky=t408*(408.0/nfreq)**2.6                  !Tsky for obs freq
      if(ltsky.and.(tsky.lt.3.0)) tsky=3.0          !Minimum = 3 Kelvin

      xdop(NStation)=doppler
      if(NStation.eq.2) then
         HisGrid=MyGrid
         go to 900
      endif

      doppler00=2.0*xdop(1)
      if(mode.eq.2 .or. mode.eq.5) doppler=xdop(1)+xdop(2)
      if(mode.eq.3) doppler=2.0*xdop(1)
      dBMoon=-40.0*log10(dist/356903.)
      sd=16.23*370152.0/dist

!      if(NStation.eq.1 .and. MoonDX.ne.0 .and. 
!     +    (mode.eq.2 .or. mode.eq.5)) then
      if(NStation.eq.1 .and. MoonDX.ne.0) then
         poloffset=mod(poloffset2-poloffset1+720.0,180.0)
         if(poloffset.gt.90.0) poloffset=poloffset-180.0
         x1=abs(cos(2*poloffset/rad))
         if(x1.lt.0.056234) x1=0.056234
         xnr=-20.0*log10(x1)
         if(HisGrid(1:1).lt.'A' .or. HisGrid(1:1).gt.'Z') xnr=0
      endif

      tr=80.0                              !Good preamp
      tskymin=13.0*(408.0/nfreq)**2.6      !Cold sky temperature
      tsysmin=tskymin+tr
      tsys=tsky+tr
      dgrd=-10.0*log10(tsys/tsysmin) + dbMoon

 900  ElMoon0=Elmoon
      ntsky=nint(tsky)

      auxHA = 15.0*(LST-auxra)                       !HA in degrees
      pi=3.14159265
      pio2=0.5*pi
      call coord(pi,pio2-lat/rad,0.0,lat/rad,auxha*pi/180.0,
     +  auxdec/rad,azaux,elaux)
      AzAux=azaux*rad
      ElAux=ElAux*rad

      return

      end
