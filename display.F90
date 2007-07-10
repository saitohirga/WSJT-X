subroutine display(nkeep)

#ifdef Win32
  use dfport
#endif

  parameter (MAXLINES=500,MX=500)
  integer indx(MAXLINES),indx2(MX)
  character*81 line(MAXLINES),line2(MX),line3(MAXLINES)
  character out*50,cfreq0*3
  character*6 callsign,callsign0
  character*12 freqcall(100)
  character*40 bm2
  real freqkHz(MAXLINES)
  integer utc(MAXLINES),utc2(MX),utcz
  real*8 f0

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
  nquad=nkeep/4
  do i=1,nz
     nage=utcz-utc(i)
     if(nage.lt.0) nage=nage+1440
     iage=(nage/nquad) + 1
     if(nage.le.1) iage=0
     write(line(i)(78:81),1021) iage
1021 format(i4)
  enddo

  nage=utcz-utc(1)
  if(nage.lt.0) nage=nage+1440
  if(nage.gt.nkeep) then
     do i=1,nz
        nage=utcz-utc(i)
        if(nage.lt.0) nage=nage+1440
        if(nage.le.nkeep) go to 20
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
  call flushqqq(26)

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
  rewind 20
  cfreq0='   '
  nc=0
  callsign0='          '
  do k=1,k3
     out=line3(k)(5:12)//line3(k)(28:31)//line3(k)(39:43)//       &
          line3(k)(35:38)//line3(k)(44:67)//line3(k)(77:81)
     if(out(1:3).ne.'   ') then
        if(out(1:3).eq.cfreq0) then
           out(1:3)='   '
        else
           cfreq0=out(1:3)
        endif
        write(19,1030) out
1030    format(a50)
        i1=index(out(24:),' ')
        callsign=out(i1+24:)
        i2=index(callsign,' ')
        if(i2.gt.1) callsign(i2:)='      '
        if(callsign.ne.'      ' .and. callsign.ne.callsign0) then
           nc=nc+1
           freqcall(nc)=cfreq0//' '//callsign//line3(k)(80:81)
           callsign0=callsign
        endif
        if(callsign.ne.'      ' .and. callsign.eq.callsign0) then
           freqcall(nc)=cfreq0//' '//callsign//line3(k)(80:81)
        endif
     endif
  enddo
  call flushqqq(19)
  nc=nc+1
  freqcall(nc)='            '
  nc=nc+1
  freqcall(nc)='            '
  freqcall(nc+1)='            '
  iz=(nc+2)/3
  do i=1,iz
     bm2=freqcall(i)//'  '//freqcall(i+iz)//'  '//freqcall(i+2*iz)
     write(20,1040) bm2
1040 format(a40)
  enddo
  call flushqqq(20)
  return
end subroutine display
