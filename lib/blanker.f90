subroutine blanker(iwave,nz,dwell_time,fblank,npct)

  integer*2 iwave(nz)
  integer hist(0:32768)
  real dwell_time                 !Blanking dwell time (s)
  real fblank                     !Fraction of points to be blanked
  data ncall/0/,thresh/0.0/,fblanked/0.0/
  save ncall,thresh,fblanked

  ncall=ncall+1  
  ndropmax=nint(1.0 + dwell_time*12000.0)
  hist=0
  do i=1,nz
     n=abs(iwave(i))
     hist(n)=hist(n)+1
  enddo
  n=0
  do i=32768,0,-1
     n=n+hist(i)
     if(n.ge.nint(nz*fblank/ndropmax)) exit
  enddo
  thresh=thresh + 0.01*(i-thresh)
  if(ncall.eq.1) thresh=i
  nthresh=nint(thresh)
  ndrop=0
  ndropped=0
     
  do i=1,nz
     i0=iwave(i)
     if(ndrop.gt.0) then
        iwave(i)=0
        ndropped=ndropped+1
        ndrop=ndrop-1
        cycle
     endif

! Start to apply blanking
     if(abs(iwave(i)).gt.nthresh) then
        iwave(i)=0
        ndropped=ndropped+1
        ndrop=ndropmax
     endif
  enddo

  fblanked=fblanked + 0.1*(float(ndropped)/nz - fblanked)
  if(ncall.eq.1) fblanked=float(ndropped)/nz
  npct=nint(100.0*fblanked)
!  if(mod(ncall,4).eq.0) write(*,3001) thresh,dwell_time,fblank,fblanked,npct
!3001 format(f8.1,f8.4,f6.2,f7.3,i6)

  return
end subroutine blanker
