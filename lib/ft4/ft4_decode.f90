subroutine ft4_decode(cdatetime0,nfqso,iwave,ndecodes,mycall,hiscall,nrx,line)

   use packjt77
   include 'ft4_params.f90'
   character message*37
   character c77*77
   character*61 line
   character*37 decodes(100)
   character*120 data_dir
   character*17 cdatetime0
   character*6 mycall,hiscall,hhmmss

   complex cd2(0:NMAX/16-1)                  !Complex waveform
   complex cb(0:NMAX/16-1)
   complex cd(0:76*20-1)                  !Complex waveform
   complex ctwk(80),ctwk2(80)
   complex csymb(20)
   complex cs(0:3,NN)
   real s4(0:3,NN)

   real bmeta(152),bmetb(152),bmetc(152)
   real s(NH1,NHSYM)
   real a(5)
   real llr(128),llr2(128),llra(128),llrb(128),llrc(128)
   real s2(0:255)
   real candidate(3,100)
   real savg(NH1),sbase(NH1)
   integer icos4(0:3)
   integer*2 iwave(NMAX)                 !Generated full-length waveform
   integer*1 message77(77),apmask(128),cw(128)
   integer*1 hbits(152)
   integer graymap(0:3)
   integer ip(1)
   logical unpk77_success
   logical one(0:511,0:7)    ! 256 4-symbol sequences, 8 bits
   logical first
   data icos4/0,1,3,2/
   data graymap/0,1,3,2/
   data first/.true./
   save one

   hhmmss=cdatetime0(12:17)
   fs=12000.0/NDOWN                       !Sample rate
   dt=1/fs                                !Sample interval after downsample (s)
   tt=NSPS*dt                             !Duration of "itone" symbols (s)
   baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
   txt=NZ*dt                              !Transmission length (s)
   twopi=8.0*atan(1.0)
   h=1.0                                  !h=0.8 seems to be optimum for AWGN sensitivity (not for fading)

   if(first) then
      one=.false.
      do i=0,255
         do j=0,7
            if(iand(i,2**j).ne.0) one(i,j)=.true.
         enddo
      enddo
      first=.false.
   endif

   data_dir="."
   fMHz=7.074

   candidate=0.0
   ncand=0

   nfa=375
   nfb=3000
   syncmin=1.0
   maxcand=100
!      call syncft4(iwave,nfa,nfb,syncmin,nfqso,maxcand,s,candidate,ncand,sbase)

   call getcandidates4(iwave,375.0,3000.0,0.2,2200.0,100,savg,candidate,ncand,sbase)
   ndecodes=0
   do icand=1,ncand
      f0=candidate(1,icand)-1.5*37.5
      xsnr=10*log10(candidate(3,icand))
      if( f0.le.375.0 .or. f0.ge.(5000.0-375.0) ) cycle
      call ft4_downsample(iwave,f0,cd2) ! downsample from 320 Sa/Symbol to 20 Sa/Symbol
      sum2=sum(cd2*conjg(cd2))/(20.0*76)
      if(sum2.gt.0.0) cd2=cd2/sqrt(sum2)

! 750 samples/second here
      ibest=-1
      smax=-99.
      dfbest=-1.
      do idf=-90,+90,5
         df=idf
         a=0.
         a(1)=df
         ctwk=1.
         call twkfreq1(ctwk,80,fs,a,ctwk2)
         do istart=0,315
            call sync4d(cd2,istart,ctwk2,1,sync)
            if(sync.gt.smax) then
               smax=sync
               ibest=istart
               dfbest=df
            endif
         enddo
      enddo

      f0=f0+dfbest
!f0=1443.75
      call ft4_downsample(iwave,f0,cb) ! downsample from 320s/Symbol to 20s/Symbol
      sum2=sum(abs(cb)**2)/(20.0*76)
      if(sum2.gt.0.0) cb=cb/sqrt(sum2)
!ibest=208
      cd=cb(ibest:ibest+76*20-1)
      do k=1,NN
         i1=(k-1)*20
         csymb=cd(i1:i1+19)
         call four2a(csymb,20,1,-1,1)
         cs(0:3,k)=csymb(1:4)/1e2
         s4(0:3,k)=abs(csymb(1:4))
      enddo

! sync quality check
      is1=0
      is2=0
      is3=0
      do k=1,4
         ip=maxloc(s4(:,k))
         if(icos4(k-1).eq.(ip(1)-1)) is1=is1+1
         ip=maxloc(s4(:,k+36))
         if(icos4(k-1).eq.(ip(1)-1)) is2=is2+1
         ip=maxloc(s4(:,k+72))
         if(icos4(k-1).eq.(ip(1)-1)) is3=is3+1
      enddo
! hard sync sum - max is 12
      nsync=is1+is2+is3

      do nseq=1,3
         if(nseq.eq.1) nsym=1
         if(nseq.eq.2) nsym=2
         if(nseq.eq.3) nsym=4
         nt=2**(2*nsym)
         do ks=1,76,nsym
            amax=-1.0
            do i=0,nt-1
               i1=i/64
               i2=iand(i,63)/16
               i3=iand(i,15)/4
               i4=iand(i,3)
               if(nsym.eq.1) then
                  s2(i)=abs(cs(graymap(i4),ks))
               elseif(nsym.eq.2) then
                  s2(i)=abs(cs(graymap(i3),ks)+cs(graymap(i4),ks+1))
               elseif(nsym.eq.4) then
                  s2(i)=abs(cs(graymap(i1),ks  ) + &
                     cs(graymap(i2),ks+1) + &
                     cs(graymap(i3),ks+2) + &
                     cs(graymap(i4),ks+3)   &
                     )
               else
                  print*,"Error - nsym must be 1, 2, or 4."
               endif
            enddo
            ipt=1+(ks-1)*2
            if(nsym.eq.1) ibmax=1
            if(nsym.eq.2) ibmax=3
            if(nsym.eq.4) ibmax=7
            do ib=0,ibmax
               bm=maxval(s2(0:nt-1),one(0:nt-1,ibmax-ib)) - &
                  maxval(s2(0:nt-1),.not.one(0:nt-1,ibmax-ib))
               if(ipt+ib .gt.152) cycle
               if(nsym.eq.1) then
                  bmeta(ipt+ib)=bm
               elseif(nsym.eq.2) then
                  bmetb(ipt+ib)=bm
               elseif(nsym.eq.4) then
                  bmetc(ipt+ib)=bm
               endif
            enddo
         enddo
      enddo

      call normalizebmet(bmeta,152)
      call normalizebmet(bmetb,152)
      call normalizebmet(bmetc,152)

      hbits=0
      where(bmeta.ge.0) hbits=1
      ns1=count(hbits(  1:  8).eq.(/0,0,0,1,1,0,1,1/))
      ns2=count(hbits( 73: 80).eq.(/0,0,0,1,1,0,1,1/))
      ns3=count(hbits(145:152).eq.(/0,0,0,1,1,0,1,1/))
      nsync_qual=ns1+ns2+ns3

      sigma=0.7
      llra(1:64)=bmeta(9:72)
      llra(65:128)=bmeta(81:144)
      llra=2*llra/sigma**2
      llrb(1:64)=bmetb(9:72)
      llrb(65:128)=bmetb(81:144)
      llrb=2*llrb/sigma**2
      llrc(1:64)=bmetc(9:72)
      llrc(65:128)=bmetc(81:144)
      llrc=2*llrc/sigma**2

      do isd=1,3
         if(isd.eq.1) llr=llra
         if(isd.eq.2) llr=llrb
         if(isd.eq.3) llr=llrc
         apmask=0
         max_iterations=40
         do ibias=0,0
            llr2=llr
            if(ibias.eq.1) llr2=llr+0.4
            if(ibias.eq.2) llr2=llr-0.4
            call bpdecode128_90(llr2,apmask,max_iterations,message77,cw,nharderror,niterations)
            if(nharderror.ge.0) exit
         enddo
         if(sum(message77).eq.0) cycle
         if( nharderror.ge.0 ) then
            write(c77,'(77i1)') message77(1:77)
            call unpack77(c77,1,message,unpk77_success)
            idupe=0
            do i=1,ndecodes
               if(decodes(i).eq.message) idupe=1
            enddo
            if(idupe.eq.1) exit
            ndecodes=ndecodes+1
            decodes(ndecodes)=message
            nsnr=nint(xsnr)-15
            freq=f0

            write(line,1000) hhmmss,nsnr,ibest/750.0,nint(freq),message
1000        format(a6,i4,f5.2,i5,' + ',1x,a37)
            open(24,file='all_ft2.txt',status='unknown',position='append')
            write(24,1002) cdatetime0,nsnr,ibest/750.0,nint(freq),message,    &
               nharderror,nsync_qual,isd,niterations
            if(hhmmss.eq.'      ') write(*,1002) cdatetime0,nsnr,             &
               ibest/750.0,nint(freq),message,nharderror,nsync_qual,isd,niterations
1002        format(a17,i4,f6.2,i5,' Rx  ',a37,4i5)
            close(24)

!### Temporary: assume most recent decoded message conveys "hiscall".
            i0=index(message,' ')
            if(i0.ge.3 .and. i0.le.7) then
               hiscall=message(i0+1:i0+6)
               i1=index(hiscall,' ')
               if(i1.gt.0) hiscall=hiscall(1:i1)
            endif
            nrx=-1
            if(index(message,'CQ ').eq.1) nrx=1
            if((index(message,trim(mycall)//' ').eq.1) .and.                 &
               (index(message,' '//trim(hiscall)//' ').ge.4)) then
               if(index(message,' 559 ').gt.8) nrx=2
               if(index(message,' R 559 ').gt.8) nrx=3
               if(index(message,' RR73 ').gt.8) nrx=4
            endif
!###
            exit

         endif
      enddo ! sequence estimation
   enddo !candidate list

   return
end subroutine ft4_decode

subroutine ft4_downsample(iwave,f0,c)

! Input: i*2 data in iwave() at sample rate 12000 Hz
! Output: Complex data in c(), sampled at 1200 Hz

   include 'ft4_params.f90'
   parameter (NFFT2=NMAX/16)
   integer*2 iwave(NMAX)
   complex c(0:NMAX/16-1)
   complex c1(0:NFFT2-1)
   complex cx(0:NMAX/2)
   real x(NMAX)
   equivalence (x,cx)

   BW=6.0*75
   df=12000.0/NMAX
   x=iwave
   call four2a(x,NMAX,1,-1,0)             !r2c FFT to freq domain
   ibw=nint(BW/df)
   i0=nint(f0/df)
   c1=0.
   c1(0)=cx(i0)
   do i=1,NFFT2/2
      arg=(i-1)*df/bw
      win=exp(-arg*arg)
      c1(i)=cx(i0+i)*win
      c1(NFFT2-i)=cx(i0-i)*win
   enddo
   c1=c1/NFFT2
   call four2a(c1,NFFT2,1,1,1)            !c2c FFT back to time domain
   c=c1(0:NMAX/16-1)
   return
end subroutine ft4_downsample

