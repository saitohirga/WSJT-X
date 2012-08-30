subroutine s3avg(nsave,mode65,nutc,ndf,xdt,npol,s3,nsum,nkv,decoded)

! Save the current synchronized spectra, s3(64,63), for possible
! decoding of average.

  real s3(64,63)                        !Synchronized spectra for 63 symbols
  real s3a(64,63,32)                    !Saved spectra
  real s3b(64,63)                       !Average
  integer iutc(32),idf(32),ipol(32)
  real dt(32)
  character*22 decoded
  logical ltext
  save
  
  iutc(nsave)=nutc                          !Save UTC
  idf(nsave)=ndf                            !Save DF
  ipol(nsave)=npol                          !Save pol
  dt(nsave)=xdt                             !Save DT
  s3a(1:64,1:63,nsave)=s3                   !Save the spectra

  write(71,3001) nsave,nutc,ndf,npol,xdt
3001 format(4i5,f8.1)
  flush(71)

  s3b=0.
  nsum=0
  idfdiff=100
  dtdiff=0.2
  do i=1,nsave                              !Accumulate avg spectra
     if(mod(iutc(i),2).ne.mod(nutc,2)) cycle !Use only 1st or 2nd sequence
     if(abs(ndf-idf(i)).gt.idfdiff) cycle   !DF must match
     if(abs(xdt-dt(i)).gt.dtdiff) cycle     !DT must match
     s3b=s3b + s3a(1:64,1:63,i)
     nsum=nsum+1
  enddo

  decoded='                      '
  if(nsum.ge.2) then                        !Try decoding the sverage
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
