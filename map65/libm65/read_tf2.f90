subroutine read_tf2(k)

  parameter (NFFT=32768)
  integer k                                 !data sample pointer
  integer*2 id2(4,174)
  character*80 fname(100)
  logical first,eof
  real*8 fcenter
  common/datcom/dd(4,5760000),ss(4,322,NFFT),savg(4,NFFT),fcenter,nutc,junk(38)
  data first/.true./,n1/0/
  save

  if(first) then
     open(27,file='mockRTfiles.txt',status='old',err=999)
     do i=1,100
        read(27,1000,end=10) fname(i)
1000    format(a)
     enddo
10   nfiles=i-1
     ifile=0
     close(27)
  endif

  if(k.eq.0) then
     ifile=ifile+1
     if(ifile.eq.2 .and. n1.eq.1) ifile=1
     if(ifile.eq.1) n1=n1+1
     if(ifile.gt.nfiles) ifile=1
     if(.not.first) close(27)
     first=.false.
     i1=index(fname(ifile),'.tf2')
     read(fname(ifile)(i1-4:i1-1),*) nutc
     open(27,file=fname(ifile),status='old',access='stream',err=999)
     print*,ifile,n1,nutc,trim(fname(ifile))
     eof=.false.
     read(27) fcenter
  endif

  if(eof) then
     id2=0
  else
     read(27,end=20) id2
  endif
  go to 30
20 eof=.true.
  id2=0
30 do i=1,174
     k=k+1
     dd(1,k)=id2(1,i)
     dd(2,k)=id2(2,i)
     dd(3,k)=id2(3,i)
     dd(4,k)=id2(4,i)
  enddo

999 return
end subroutine read_tf2
