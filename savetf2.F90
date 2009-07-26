subroutine savetf2(id,fnamedate,savedir)

  parameter (NZ=60*96000)
  parameter (NSPP=174)
  parameter (NPKTS=NZ/NSPP)
  integer*2 id(4,NZ)
  character*80 savedir,fname
  character cdate*8,ctime2*10,czone*5,fnamedate*6
  integer  itt(8)
  data nloc/-1/
  save nloc

  call cs_lock('savetf2')
  call date_and_time(cdate,ctime2,czone,itt)
  nh=itt(5)-itt(4)/60
  nm=itt(6)
  ns=itt(7)
  if(ns.lt.50) nm=nm-1
  if(nm.lt.0) then
     nm=nm+60
     nh=nh-1
  endif
  if(nh.lt.0) nh=nh+24
  if(nh.ge.24) nh=nh-24
  write(fname,1001) fnamedate,nh,nm
1001 format('/',a6,'_',2i2.2,'.tf2')
  do i=80,1,-1
     if(savedir(i:i).ne.' ') go to 1
  enddo
1 iz=i
  fname=savedir(1:iz)//fname
#ifdef CVF
  open(17,file=fname,status='unknown',form='binary',err=998)
#else
  open(17,file=fname,status='unknown',access='stream',err=998)
#endif

  if(nloc.eq.-1) nloc=loc(id)
  n=abs(loc(id)-nloc)
  if(n.eq.0 .or. n.eq.46080000) then
     write(17,err=997) id
  else
     print*,'Address of id() clobbered???',nloc,loc(id)
  endif
  close(17)
  go to 999

997 print*,'Error writing tf2 file'
  print*,fname
  go to 999

998 print*,'Cannot open file:'
  print*,fname

999 continue
  call cs_unlock
  return
end subroutine savetf2
