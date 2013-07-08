subroutine decode65b(s2,nflip,mode65,nbmkv,nhist,decoded)

  real s2(66,126)
  real s3(64,63)
  logical first,ltext
  character decoded*22
  common/prcom/pr(126),mdat(126),mref(126,2),mdat2(126),mref2(126,2)
  data first/.true./
  save

  if(first) call setup65
  first=.false.

  do j=1,63
     k=mdat(j)                       !Points to data symbol
     if(nflip.lt.0) k=mdat2(j)
     do i=1,64
        s3(i,j)=s2(i+2,k)
     enddo
     k=mdat2(j)                       !Points to data symbol
     if(nflip.lt.0) k=mdat(j)
  enddo

  nadd=mode65
  call extract(s3,nadd,ncount,nhist,decoded,ltext,nbmkv)   !Extract the message
! Suppress "birdie messages" and other garbage decodes:
  if(decoded(1:7).eq.'000AAA ') ncount=-1
  if(decoded(1:7).eq.'0L6MWK ') ncount=-1
  if(nflip.lt.0 .and. ltext) ncount=-1
  if(ncount.lt.0) then 
     nbmkv=0
     decoded='                      '
  endif

  return
end subroutine decode65b
