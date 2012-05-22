subroutine s3avg(nsave,mode65,nutc,ndf,xdt,npol,s3,nkv,decoded)

  real s3(64,63),s3b(64,63)
  real s3a(64,63,32)
  integer iutc(32),idf(32),ipol(32)
  real dt(32)
  character*22 decoded
  logical ltext
  save
  
  n=nsave
  iutc(n)=nutc
  idf(n)=ndf
  ipol(n)=npol
  dt(n)=xdt
  s3a(1:64,1:63,n)=s3

  s3b=0.
  nsum=0
  idfdiff=100
  dtdiff=0.2
  do i=1,n
     if(mod(iutc(i),2).ne.mod(nutc,2)) cycle
     if(abs(ndf-idf(i)).gt.idfdiff) cycle
     if(abs(xdt-dt(i)).gt.dtdiff) cycle
     s3b=s3b + s3a(1:64,1:63,i)
     nsum=nsum+1
  enddo

  decoded='                      '
  if(nsum.ge.2) then
     nadd=mode65*nsum
     call extract(s3b,nadd,ncount,nhist,decoded,ltext)     !Extract the message
     nkv=nsum
     if(ncount.lt.0) then 
        nkv=0
        decoded='                      '
     endif
  endif

  return
end subroutine s3avg
