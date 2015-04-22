subroutine avg4(nutc,snrsync,dtxx,flip,nfreq,mode4,ntol,ndepth,neme,       &
  mycall,hiscall,hisgrid,nfanoave,avemsg,qave,deepave,ichbest,ndeepave)

! Decodes averaged JT4 data

  use jt4
  character*22 avemsg,deepave,deepbest
  character mycall*12,hiscall*12,hisgrid*6
  character*1 csync,cused(64)
  real sym(207,7)
  integer iused(64)
  logical first
  data first/.true./
  save

  if(first) then
     iutc=-1
     nfsave=0
     dtdiff=0.2
     first=.false.
  endif

  do i=1,64
     if(nutc.eq.iutc(i) .and. abs(nhz-nfsave(i)).le.ntol) go to 10
  enddo  

! Save data for message averaging
  iutc(nsave)=nutc
  syncsave(nsave)=snrsync
  dtsave(nsave)=dtxx
  nfsave(nsave)=nfreq
  flipsave(nsave)=flip
  ppsave(1:207,1:7,nsave)=rsymbol(1:207,1:7)  

10 sym=0.
  syncsum=0.
  dtsum=0.
  nfsum=0
  nsum=0

  do i=1,64
     cused(i)='.'
     if(iutc(i).lt.0) cycle
     if(mod(iutc(i),2).ne.mod(nutc,2)) cycle  !Use only same (odd/even) sequence
     if(abs(dtxx-dtsave(i)).gt.dtdiff) cycle       !DT must match
     if(abs(nfreq-nfsave(i)).gt.ntol) cycle        !Freq must match
     if(flip.ne.flipsave(i)) cycle                 !Sync (*/#) must match
     sym(1:207,1:7)=sym(1:207,1:7) +  ppsave(1:207,1:7,i)
     syncsum=syncsum + syncsave(i)
     dtsum=dtsum + dtsave(i)
     nfsum=nfsum + nfsave(i)
     cused(i)='$'
     nsum=nsum+1
     iused(nsum)=i
  enddo
  if(nsum.lt.64) iused(nsum+1)=0

  syncave=0.
  dtave=0.
  fave=0.
  if(nsum.gt.0) then
     sym=sym/nsum
     syncave=syncsum/nsum
     dtave=dtsum/nsum
     fave=float(nfsum)/nsum
  endif

!  rewind 80
  do i=1,nsave
     csync='*'
     if(flipsave(i).lt.0.0) csync='#'
     write(14,1000) cused(i),iutc(i),syncsave(i),dtsave(i),nfsave(i),csync
1000 format(a1,i5.4,f6.1,f6.2,i6,1x,a1)
  enddo

  sqt=0.
  sqf=0.
  do j=1,64
     i=iused(j)
     if(i.eq.0) exit
     csync='*'
     if(flipsave(i).lt.0.0) csync='#'
!     write(80,3001) i,iutc(i),syncsave(i),dtsave(i),nfsave(i),csync
!3001 format(i3,i6.4,f6.1,f6.2,i6,1x,a1)
     sqt=sqt + (dtsave(i)-dtave)**2
     sqf=sqf + (nfsave(i)-fave)**2
  enddo
  rmst=0.
  rmsf=0.
  if(nsum.ge.2) then
     rmst=sqrt(sqt/(nsum-1))
     rmsf=sqrt(sqf/(nsum-1))
  endif
!  write(80,3002)
!3002 format(16x,'----- -----')
!  write(80,3003) dtave,nint(fave)
!  write(80,3003) rmst,nint(rmsf)
!3003 format(15x,f6.2,i6)
!  flush(80)

!  nadd=nused*mode4
  kbest=ich1
  do k=ich1,ich2
     call extract4(sym(1,k),ncount,avemsg)     !Do the Fano decode
     nfanoave=0
     if(ncount.ge.0) then
        ichbest=k
        nfanoave=nsum
        go to 900
     endif
     if(nch(k).ge.mode4) exit
  enddo

  deepave='                      '
  qave=0.

! Possibly should pass nadd=nused, also ?
  if(ndepth.ge.3) then
     flipx=1.0                     !Normal flip not relevant for ave msg
     qbest=0.
     do k=ich1,ich2
        call deep4(sym(2,k),neme,flipx,mycall,hiscall,hisgrid,deepave,qave)
!        write(82,3101) nutc,sym(51:53,k),flipx,k,qave,deepave
!3101    format(i4.4,4f8.1,i3,f7.2,2x,a22)
        if(qave.gt.qbest) then
           qbest=qave
           deepbest=deepave
           kbest=k
           ndeepave=nsum
!           print*,'b',qbest,k,deepbest
        endif
        if(nch(k).ge.mode4) exit
     enddo

     deepave=deepbest
     qave=qbest
     ichbest=kbest
  endif

900 return
end subroutine avg4
