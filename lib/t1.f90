program t1

  character*22 msg
  character*12 arg
  complex c3(0:4096-1)
  complex c5(0:4096-1)

  call getarg(1,arg)
  read(arg,*) nfile

  do ifile=1,999
     read(51,end=999) nutc,nsnr,xdt,nfreq,msg,c3,c5
     write(*,1010) ifile,nutc,nsnr,xdt,nfreq,msg
1010 format(3i6,f7.1,i6,2x,a22)

     if(ifile.eq.nfile) then
        c3=c5
        c3(1353:)=0
        call four2a(c3,2048,1,-1,1)

        df=12000.0/(128.0*2048.0)
        do i=0,2048
           freq=i*df
           if(i.ge.1024) freq=(i-2048)*df
           s=1.e-4*(real(c3(i))**2 + aimag(c3(i))**2)
           write(13,3001) i,freq,s
3001       format(i6,2f10.3)
        enddo
     endif
  enddo

999 end program t1
