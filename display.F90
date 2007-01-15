subroutine display

  use dfport

  parameter (MAXLINES=500,MX=500)
  integer indx(MAXLINES),indx2(MX)
  character*80 line(MAXLINES),line2(MX),line3(MAXLINES)
  character out*41,cfreq0*3
  real freqkHz(MAXLINES)
  integer utc(MAXLINES),utc2(MX),utcz
  real*8 f0
  data nkeep/20/

  ftol=0.02
  rewind 26

  do i=1,MAXLINES
     read(26,1010,end=10) line(i)
1010 format(a80)
     read(line(i),1020) f0,ndf,nh,nm
1020 format(f7.3,i5,26x,i3,i2)
     utc(i)=60*nh + nm
     freqkHz(i)=1000.d0*(f0-144.d0) + 0.001d0*ndf
  enddo

10 nz=i-1
  utcz=utc(nz)
  ndiff=utcz-utc(1)
  if(ndiff.lt.0) ndiff=ndiff+1440
  if(ndiff.gt.nkeep) then
     do i=1,nz
        ndiff=utcz-utc(i)
        if(ndiff.lt.0) ndiff=ndiff+1440
        if(ndiff.le.nkeep) go to 20
     enddo
20   i0=i
     nz=nz-i0+1
     rewind 26
     do i=1,nz
        j=i+i0-1
        line(i)=line(j)
        utc(i)=utc(j)
        freqkHz(i)=freqkHz(j)
        write(26,1010) line(i)
     enddo
  endif

  call indexx(nz,freqkHz,indx)

  nstart=1
  k3=0
  k=1
  line2(1)=line(indx(1))
  utc2(1)=utc(indx(1))
  do i=2,nz
     j0=indx(i-1)
     j=indx(i)
     if(freqkHz(j)-freqkHz(j0).gt.ftol) then
        if(nstart.eq.0) then
           k=k+1
           line2(k)=""
           utc2(k)=-1
        endif
        kz=k
        if(nstart.eq.1) then
           call indexx(kz,utc2,indx2)
           k3=0
           do k=1,kz
              k3=k3+1
              line3(k3)=line2(indx2(k))
           enddo
           nstart=0
        else
           call indexx(kz,utc2,indx2)
           do k=1,kz
              k3=k3+1
              line3(k3)=line2(indx2(k))
           enddo
        endif
        k=0
     endif
     if(i.eq.nz) then
        k=k+1
        line2(k)=""
        utc2(k)=-1
     endif
     k=k+1
     line2(k)=line(j)
     utc2(k)=utc(j)
     j0=j
  enddo
  kz=k
  call indexx(kz,utc2,indx2)
  do k=1,kz
     k3=k3+1
     line3(k3)=line2(indx2(k))
  enddo

  rewind 19
  cfreq0='   '
  do k=1,k3
     out=line3(k)(5:12)//line3(k)(28:31)//line3(k)(39:67)
     if(out(1:3).ne.'   ') then
        if(out(1:3).eq.cfreq0) then
           out(1:3)='   '
        else
           cfreq0=out(1:3)
        endif
        write(19,1030) out
1030    format(a41)
     endif
  enddo

  return
end subroutine display
