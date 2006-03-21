
!----------------------------------------------------- getfile
subroutine getfile(fname,len)

#ifdef Win32
  use dflib
#endif

  parameter (NDMAX=60*11025)
  character*(*) fname
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom4.f90'


  integer*1 d1(NDMAX)
  integer*1 hdr(44),n1
  integer*2 d2(NDMAX)
  integer*2 nfmt2,nchan2,nbitsam2,nbytesam2
  character*4 ariff,awave,afmt,adata
  common/hdr/ariff,lenfile,awave,afmt,lenfmt,nfmt2,nchan2, &
     nsamrate,nbytesec,nbytesam2,nbitsam2,adata,ndata,d2
  equivalence (ariff,hdr),(n1,n4),(d1,d2)

1 if(ndecoding.eq.0) go to 2
#ifdef Win32
  call sleepqq(100)
#else
  call usleep(100*1000)
#endif

  go to 1

2 do i=len,1,-1
     if(fname(i:i).eq.'/' .or. fname(i:i).eq.'\\') go to 10
  enddo
  i=0
10 filename=fname(i+1:)
  ierr=0

#ifdef Win32
  open(10,file=fname,form='binary',status='old',err=998)
  read(10,end=998) hdr
  
#else
  call rfile2(fname,hdr,44+2*NDMAX,nr)
#endif

  if(nbitsam2.eq.8) then
     if(ndata.gt.NDMAX) ndata=NDMAX

#ifdef Win32
     call rfile(10,d1,ndata,ierr)
     if(ierr.ne.0) go to 999
#endif

     do i=1,ndata
        n1=d1(i)
        n4=n4+128
        d2c(i)=250*n1
     enddo
     jzc=ndata

  else if(nbitsam2.eq.16) then
     if(ndata.gt.2*NDMAX) ndata=2*NDMAX
#ifdef Win32
     call rfile(10,d2c,ndata,ierr)
     jzc=ndata/2
     if(ierr.ne.0) go to 999
#else
     jzc=ndata/2
     do i=1,jzc
        d2c(i)=d2(i)
     enddo
#endif
  endif

  if(monitoring.eq.0) then
! In this case, spec should read data from d2c
!     jzc=jzc/2048
!     jzc=jzc*2048
     ndiskdat=1
  endif

  mousebutton=0
  go to 999

998 ierr=1001
999 close(10)
  return
end subroutine getfile
