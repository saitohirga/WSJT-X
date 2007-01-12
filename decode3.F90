!---------------------------------------------------- decode3
subroutine decode3(d2,jz,istart,filename)

#ifdef Win32
  use dfport
#endif

  integer*2 d2(jz),d2d(65*11025)
  character*24 filename
  character FileID*40
  include 'gcom1.f90'
  include 'gcom2.f90'
  
  if(ichar(filename(1:1)).eq.0) go to 999
    
  FileID=filename
  decodedfile=filename
  lumsg=11
  nqrn=nclip+5
  nmode=1
  if(mode(1:4).eq.'JT65') then
     nmode=2
     if(mode(5:5).eq.'A') mode65=1
     if(mode(5:5).eq.'B') mode65=2
     if(mode(5:5).eq.'C') mode65=4
  endif
  if(mode.eq.'Echo') nmode=3
  if(mode.eq.'JT6M') nmode=4

  sum=0.
  do i=1,jz
     sum=sum+d2(i)
  enddo
  nave=nint(sum/jz)
  do i=1,jz
     d2(i)=d2(i)-nave
     d2d(i)=d2(i)
  enddo

  nseg=1
  if(mode(1:4).eq.'JT65') then
     i=index(FileID,'.')-3
     if(FileID(i:i).eq.'1'.or.FileID(i:i).eq.'3'.or.FileID(i:i).eq.'5'  &
          .or.FileID(i:i).eq.'7'.or.FileID(i:i).eq.'9') nseg=2
  endif

  open(23,file=appdir(:lenappdir)//'/CALL3.TXT',status='unknown')
  if(nadd5.eq.1) then
     nzero=5*11025
     do i=jz,nzero+1,-1
        d2d(i)=d2d(i-nzero)
     enddo
     do i=1,nzero
        d2d(i)=0
     enddo
     jz=min(60*11025,jz+nzero)
  endif
!  call wsjt1(d2d,jz,istart,samfacin,FileID,ndepth,MinSigdB,           &
!       NQRN,DFTolerance,MouseButton,NClearAve,                        &
!       nMode,NFreeze,NAFC,NZap,mode65,idf,                            &
!       MyCall,HisCall,HisGrid,neme,nsked,ntx2,s2,                     &
!       ps0,npkept,lumsg,basevb,rmspower,nslim2,psavg,ccf,Nseg,        &
!       MouseDF,NAgain,LDecoded,nspecial,ndf,ss1,ss2)
  basevb=-999.
  close(23)
  if(basevb.le.-98.0) go to 999

! See whether this file should be saved or erased from disk
  if(nsave.eq.1 .and. ldecoded) filetokilla=''
  if(nsave.eq.3 .or. (nsave.eq.2 .and. lauto.eq.1)) then
     filetokilla=''
     filetokillb=''
  endif
  if(nsavelast.eq.1) filetokillb=''
  nsavelast=0
  ierr=unlink(filetokillb)
  
  nclearave=0
  nagain=0
  call pix2d65(d2d,jz)

999 return
end subroutine decode3
