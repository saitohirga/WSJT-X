program ms3

! Starting code for a JTMS3 decoder.

  character*80 infile
  parameter (NSMAX=30*48000)
  parameter (NFFT=8192,NH=NFFT/2)
  integer hdr(11)
  integer*2 id(NSMAX)
  real x(NFFT)
  complex cx(NFFT),cx2(NFFT)
  real s(NH)

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage: ms3 file1 [file2 ...]'
     print*,'       Reads data from *.wav files.'
     go to 999
  endif

  npts=NSMAX
  kstep=1024
  nsteps=npts/kstep
  do ifile=1,nargs
     call getarg(ifile,infile)
     open(10,file=infile,access='stream',status='old',err=998)
     read(10) hdr
     read(10) id
     close(10)

     k=hdr(1)
     k=0
     do j=1,nsteps
        sq=0.
        do i=1,kstep
           k=k+1
           sq=sq + (0.001*id(k))**2
        enddo
        t=j*kstep/48000.0
        pdb=db(sq)
        write(13,1010) t,sq,pdb
1010    format(3f12.3)
     enddo
  enddo

  iz=29.5*48000.0
  df=48000.0/nfft
  ja=nint(2600.0)/df
  jb=nint(3400.0)/df
  do i=1,iz,nh
     x(1:nfft)=0.001*id(i:i+nfft-1)
     call analytic(x,nfft,nfft,s,cx)
     t=i/48000.0
     sq=dot_product(x,x) 
     write(14,1010) t,sq,db(sq)
     cx2=cx*cx
     call four2a(cx2,nfft,1,-1,1)               !Forward c2c FFT
     smax=0.
     do j=ja,jb
        sq=1.e-6*(real(cx2(j))**2 + aimag(cx2(j))**2)
        f=(j-1)*df
        if(sq.gt.smax) then
           smax=sq
           xdf=0.5*(f-3000.0)
        endif
        write(15,1020) (j-1)*df,sq
1020    format(f10.3,f12.3)
     enddo
     write(16,1030) t,smax,xdf
1030 format(3f12.3)
  enddo

  go to 999

998 print*,'Cannot open file:'
  print*,infile

999 end program ms3
