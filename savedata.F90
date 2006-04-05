!----------------------------------------------------------- savedata
subroutine savedata

#ifdef Win32
  use dfport
#endif

  character fname*24,longname*80
  data ibuf0z/1/
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  save

  if(mode(1:4).eq.'JT65') then
     call get_fname(hiscall,ntime,trperiod,lauto,fname0)
     ibuf1=ibuf0
     ibuf2=ibuf
     go to 1
  else
     call get_fname(hiscall,ntime-trperiod,trperiod,lauto,fname0)
  endif

  if(ibuf0.eq.ibuf0z) go to 999         !Startup condition, do not save
  if(ntrbuf(ibuf0z).eq.1) go to 999     !We were transmitting, do not save

! Get buffer pointers, then copy completed Rx sequence from y1 to d2a:
  ibuf1=ibuf0z
  ibuf2=ibuf0-1
1 jza=2048*(ibuf2-ibuf1)
  if(jza.lt.0) jza=jza+NRxMax
  lenok=1
  if(jza.lt.110250) go to 999           !Don't save files less than 10 s
  if(jza.gt.60*11025) go to 999         !Don't save if something's fishy
  k=2048*(ibuf1-1)
  if(mode(1:4).ne.'JT65') k=k+3*2048
  if(mode(1:4).ne.'JT65' .and. jza.gt.30*11025) then
     k=k + (jza-30*11025)
     if(k.gt.NRxMax) k=k-NRxMax
     jza=30*11025
  endif

! Check timestamps of buffers used for this data
  msbig=0
  i=k/2048
  if(msmax.eq.0) i=i+1
  nz=jza/2048
  if(msmax.eq.0) then
     i=i+1
     nz=nz-1
  endif
  do n=1,nz
     i=i+1
     if(i.gt.1024) i=i-1024
     i0=i-1
     if(i0.lt.1) i0=i0+1024
     dtt=tbuf(i)-tbuf(i0)
     ms=0
     if(dtt.gt.0.d0 .and. dtt.lt.80000.0) ms=1000.d0*dtt
     msbig=max(ms,msbig)
  enddo

  if(ndebug.gt.0 .and. msbig.gt.msmax .and. msbig.gt.330) then
     write(*,1020) msbig
1020 format('Warning: interrupt service interval',i11,' ms.')
  endif
  msmax=max(msbig,msmax)

  do i=1,jza
     k=k+1
     if(k.gt.NRxMax) k=k-NRxMax
     xx=dgain*y1(k)
     xx=min(32767.0,max(-32767.0,xx))
     d2a(i)=nint(xx)
  enddo
  fnamea=fname0

  npingtime=0
  fname=fnamea                   !Save filename for output to disk
  nagain=0
  ndecoding=1                    !Request decoding
  
! Generate file name and write data to file
!    if(nsave.ge.2 .and. ichar(fname(1:1)).ne.0) then
  if(ichar(fname(1:1)).ne.0) then

! Generate header for wavefile:
     ariff='RIFF'
     awave='WAVE'
     afmt='fmt '
     adata='data'
     lenfmt=16
     nfmt2=1
     nchan2=1
     nsamrate=11025
     nbytesam2=2
     nbytesec=nchan2*nsamrate*nbytesam2
     nbitsam2=16
     ndata=2*jza
     nbytes=ndata+44
     nchunk=nbytes-8
     
     do i=80,1,-1
        if(appdir(i:i).ne.' ') go to 10
     enddo
10   longname=AppDir(1:i)//'/RxWav/'//fname

#ifdef Win32
     open(17,file=longname,status='unknown',form='binary',err=20)
#else
     open(17,file=longname,status='unknown',form='unformatted',err=20)
#endif
     write(17) ariff,nchunk,awave,afmt,lenfmt,nfmt2,nchan2,nsamrate, &
          nbytesec,nbytesam2,nbitsam2,adata,ndata,(d2a(j),j=1,jza)
     close(17)
     filetokillb=filetokilla
     filetokilla=longname
     go to 30
20   print*,'Error opening Fortran unit 17.'
     print*,longname
30   continue
  endif

999 if(mode(1:4).ne.'JT65') then
     ibuf0z=ibuf0
     ntime0=ntime
     call get_fname(hiscall,ntime,trperiod,lauto,fname0)
  endif

  return
end subroutine savedata
