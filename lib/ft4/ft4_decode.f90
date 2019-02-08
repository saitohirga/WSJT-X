subroutine ft4_decode(cdatetime0,tbuf,nfa,nfb,nQSOProgress,ncontest,nfqso,iwave,    &
   ndecodes,mycall,hiscall,nrx,line,data_dir)

   use packjt77
   include 'ft4_params.f90'
   parameter (NSS=NSPS/NDOWN)

   character message*37,msgsent*37
   character c77*77
   character*61 line,linex(100)
   character*37 decodes(100)
   character*512 data_dir,fname
   character*17 cdatetime0
   character*12 mycall,hiscall
   character*12 mycall0,hiscall0
   character*6 hhmmss

   complex cd2(0:NMAX/NDOWN-1)                  !Complex waveform
   complex cds(0:NMAX/NDOWN-1)                  !Complex waveform
   complex cb(0:NMAX/NDOWN-1)
   complex cd(0:NN*NSS-1)                       !Complex waveform
   complex ctwk(4*NSS),ctwk2(4*NSS)
   complex csymb(NSS)
   complex cs(0:3,NN)
   real s4(0:3,NN)

   real bmeta(2*NN),bmetb(2*NN),bmetc(2*NN)
   real a(5)
   real llr(2*ND),llra(2*ND),llrb(2*ND),llrc(2*ND),llrd(2*ND)
   real s2(0:255)
   real candidate(3,100)
   real savg(NH1),sbase(NH1)

   integer apbits(58)
   integer nrxx(100)
   integer icos4a(0:3),icos4b(0:3),icos4c(0:3),icos4d(0:3)
   integer*2 iwave(NMAX)                 !Generated full-length waveform
   integer*1 message77(77),rvec(77),apmask(2*ND),cw(2*ND)
   integer*1 hbits(2*NN)
   integer graymap(0:3)
   integer ip(1)
   integer nappasses(0:5)    ! # of decoding passes for QSO States 0-5
   integer naptypes(0:5,4)   ! nQSOProgress, decoding pass
   integer mcq(29),mcqru(29),mcqfd(29),mcqtest(29)
   integer mrrr(19),m73(19),mrr73(19)

   logical unpk77_success
   logical one(0:255,0:7)    ! 256 4-symbol sequences, 8 bits
   logical first

   data icos4a/0,1,3,2/
   data icos4b/1,0,2,3/
   data icos4c/2,3,1,0/
   data icos4d/3,2,0,1/
   data graymap/0,1,3,2/
   data first/.true./
   data     mcq/0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0/
   data   mcqru/0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,1,1,0,0,1,1,0,0/
   data   mcqfd/0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0/
   data mcqtest/0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,1,0,1,0,1,1,1,1,1,1,0,0,1,0/
   data    mrrr/0,1,1,1,1,1,1,0,1,0,0,1,0,0,1,0,0,0,1/
   data     m73/0,1,1,1,1,1,1,0,1,0,0,1,0,1,0,0,0,0,1/
   data   mrr73/0,1,1,1,1,1,1,0,0,1,1,1,0,1,0,1,0,0,1/
   data rvec/0,1,0,0,1,0,1,0,0,1,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,0,1,1,0, &
      1,0,0,1,0,1,1,0,0,0,0,1,0,0,0,1,0,1,0,0,1,1,1,1,0,0,1,0,1, &
      0,1,0,1,0,1,1,0,1,1,1,1,1,0,0,0,1,0,1/
   save fs,dt,tt,txt,twopi,h,one,first,nrxx,linex,apbits,nappasses,naptypes, &
      mycall0,hiscall0,ncontest0

   call clockit('ft4_deco',0)
   hhmmss=cdatetime0(8:13)

   if(first) then
      fs=12000.0/NDOWN                !Sample rate after downsampling
      dt=1/fs                         !Sample interval after downsample (s)
      tt=NSPS*dt                      !Duration of "itone" symbols (s)
      txt=NZ*dt                       !Transmission length (s) without ramp up/down
      twopi=8.0*atan(1.0)
      h=1.0
      one=.false.
      do i=0,255
         do j=0,7
            if(iand(i,2**j).ne.0) one(i,j)=.true.
         enddo
      enddo

      mcq=2*mod(mcq+rvec(1:29),2)-1
      mcqfd=2*mod(mcqfd+rvec(1:29),2)-1
      mcqru=2*mod(mcqru+rvec(1:29),2)-1
      mcqtest=2*mod(mcqtest+rvec(1:29),2)-1
      mrrr=2*mod(mrrr+rvec(59:77),2)-1
      m73=2*mod(m73+rvec(59:77),2)-1
      mrr73=2*mod(mrr73+rvec(59:77),2)-1
      nappasses(0)=2
      nappasses(1)=2
      nappasses(2)=2
      nappasses(3)=2
      nappasses(4)=2
      nappasses(5)=3

! iaptype
!------------------------
!   1        CQ     ???    ???           (29 ap bits)
!   2        MyCall ???    ???           (29 ap bits)
!   3        MyCall DxCall ???           (58 ap bits)
!   4        MyCall DxCall RRR           (77 ap bits)
!   5        MyCall DxCall 73            (77 ap bits)
!   6        MyCall DxCall RR73          (77 ap bits)
!********
! For this contest-oriented mode, OK to only look for RR73??
! Currently, 2 AP passes in all Txn states except for Tx5.
!********
      naptypes(0,1:4)=(/1,2,0,0/) ! Tx6 selected (CQ)
      naptypes(1,1:4)=(/2,3,0,0/) ! Tx1
      naptypes(2,1:4)=(/2,3,0,0/) ! Tx2
      naptypes(3,1:4)=(/3,6,0,0/) ! Tx3
      naptypes(4,1:4)=(/3,6,0,0/) ! Tx4
      naptypes(5,1:4)=(/3,1,2,0/) ! Tx5
      first=.false.
   endif

   if(mycall.ne.mycall0 .or. hiscall.ne.hiscall0) then
      call ft8apset(mycall,hiscall,apbits)
      if(apbits( 1).ne.99) then
         apbits( 1:29)=(apbits(1:29)+1)/2
         apbits( 1:29)=2*mod(apbits( 1:29)+rvec( 1:29),2)-1
      endif
      if(apbits(30).ne.99) then
         apbits(30:58)=(apbits(30:58)+1)/2
         apbits(30:58)=2*mod(apbits(30:58)+rvec(30:58),2)-1
      endif
      mycall0=mycall
      hiscall0=hiscall
   endif

   candidate=0.0
   ncand=0
   syncmin=1.2
   maxcand=100

   fa=nfa
   fb=nfb
   call clockit('getcand4',0)
   call getcandidates4(iwave,fa,fb,syncmin,nfqso,maxcand,savg,candidate,   &
      ncand,sbase)
   call clockit('getcand4',1)

   ndecodes=0
   do icand=1,ncand
      f0=candidate(1,icand)
      snr=candidate(3,icand)-1.0
      if( f0.le.375.0 .or. f0.ge.(5000.0-375.0) ) cycle
      call clockit('ft4_down',0)
      call ft4_downsample(iwave,f0,cd2)  !Downsample from 512 to 32 Sa/Symbol
      call clockit('ft4_down',1)

      sum2=sum(cd2*conjg(cd2))/(real(NMAX)/real(NDOWN))
      if(sum2.gt.0.0) cd2=cd2/sqrt(sum2)
! Sample rate is now 12000/16 = 750 samples/second
      do isync=1,2
         if(isync.eq.1) then
            idfmin=-12
            idfmax=12
            idfstp=3
            ibmin=0
            ibmax=374
            ibstp=4
         else
            idfmin=idfbest-4
            idfmax=idfbest+4
            idfstp=1
            ibmin=max(0,ibest-5)
            ibmax=min(ibest+5,NMAX/NDOWN-1)
            ibstp=1
         endif
         ibest=-1
         smax=-99.
         idfbest=0
         do idf=idfmin,idfmax,idfstp
            a=0.
            a(1)=real(idf)
            ctwk=1.
            call clockit('twkfreq1',0)
            call twkfreq1(ctwk,4*NSS,fs,a,ctwk2)
            call clockit('twkfreq1',1)

            call clockit('sync4d  ',0)
            do istart=ibmin,ibmax,ibstp
               call sync4d(cd2,istart,ctwk2,1,sync,sync2)  !Find sync power
               if(sync.gt.smax) then
                  smax=sync
                  ibest=istart
                  idfbest=idf
               endif
            enddo
            call clockit('sync4d  ',1)

         enddo
      enddo
      f0=f0+real(idfbest)

!f0=1500
!ibest=219
      call clockit('ft4down ',0)
      call ft4_downsample(iwave,f0,cb) !Final downsample with corrected f0
      call clockit('ft4down ',1)
      sum2=sum(abs(cb)**2)/(real(NSS)*NN)
      if(sum2.gt.0.0) cb=cb/sqrt(sum2)
      cd=cb(ibest:ibest+NN*NSS-1)
      call clockit('four2a  ',0)
      do k=1,NN
         i1=(k-1)*NSS
         csymb=cd(i1:i1+NSS-1)
         call four2a(csymb,NSS,1,-1,1)
         cs(0:3,k)=csymb(1:4)
         s4(0:3,k)=abs(csymb(1:4))
      enddo
      call clockit('four2a  ',1)

! Sync quality check
      is1=0
      is2=0
      is3=0
      is4=0
      do k=1,4
         ip=maxloc(s4(:,k))
         if(icos4a(k-1).eq.(ip(1)-1)) is1=is1+1
         ip=maxloc(s4(:,k+33))
         if(icos4b(k-1).eq.(ip(1)-1)) is2=is2+1
         ip=maxloc(s4(:,k+66))
         if(icos4c(k-1).eq.(ip(1)-1)) is3=is3+1
         ip=maxloc(s4(:,k+99))
         if(icos4d(k-1).eq.(ip(1)-1)) is4=is4+1
      enddo
      nsync=is1+is2+is3+is4   !Number of hard sync errors, 0-16
      if(smax .lt. 0.7 .or. nsync .lt. 8) cycle

      do nseq=1,3             !Try coherent sequences of 1, 2, and 4 symbols
         if(nseq.eq.1) nsym=1
         if(nseq.eq.2) nsym=2
         if(nseq.eq.3) nsym=4
         nt=2**(2*nsym)
         do ks=1,NN-nsym+1,nsym  !87+16=103 symbols.
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
               if(ipt+ib.gt.2*NN) cycle
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

      call clockit('normaliz',0)
      call normalizebmet(bmeta,2*NN)
      call normalizebmet(bmetb,2*NN)
      call normalizebmet(bmetc,2*NN)
      call clockit('normaliz',1)

      hbits=0
      where(bmeta.ge.0) hbits=1
      ns1=count(hbits(  1:  8).eq.(/0,0,0,1,1,0,1,1/))
      ns2=count(hbits( 67: 74).eq.(/0,1,0,0,1,1,1,0/))
      ns3=count(hbits(133:140).eq.(/1,1,1,0,0,1,0,0/))
      ns4=count(hbits(199:206).eq.(/1,0,1,1,0,0,0,1/))
      nsync_qual=ns1+ns2+ns3+ns4
      if(nsync_qual.lt. 20) cycle

      scalefac=2.83
      llra(  1: 58)=bmeta(  9: 66)
      llra( 59:116)=bmeta( 75:132)
      llra(117:174)=bmeta(141:198)
      llra=scalefac*llra
      llrb(  1: 58)=bmetb(  9: 66)
      llrb( 59:116)=bmetb( 75:132)
      llrb(117:174)=bmetb(141:198)
      llrb=scalefac*llrb
      llrc(  1: 58)=bmetc(  9: 66)
      llrc( 59:116)=bmetc( 75:132)
      llrc(117:174)=bmetc(141:198)
      llrc=scalefac*llrc

      apmag=maxval(abs(llra))*1.1
      npasses=3+nappasses(nQSOProgress)
      if(ncontest.ge.5) npasses=3  ! Don't support Fox and Hound

      do ipass=1,npasses
         if(ipass.eq.1) llr=llra
         if(ipass.eq.2) llr=llrb
         if(ipass.eq.3) llr=llrc
         if(ipass.le.3) then
            apmask=0
            iaptype=0
         endif

         if(ipass .gt. 3) then
            llrd=llrc
            iaptype=naptypes(nQSOProgress,ipass-3)
            if(iaptype.eq.1) then  ! CQ or CQ TEST
               apmask=0
               apmask(1:29)=1
               if(ncontest.eq.0) llrd(1:29)=apmag*mcq(1:29)
               if(ncontest.eq.1) llrd(1:29)=apmag*mcqtest(1:29)
               if(ncontest.eq.2) llrd(1:29)=apmag*mcqtest(1:29)
               if(ncontest.eq.3) llrd(1:29)=apmag*mcqfd(1:29)
               if(ncontest.eq.4) llrd(1:29)=apmag*mcqru(1:29)
               if(ncontest.eq.6) llrd(1:29)=apmag*mcq(1:29)
            endif

            if(iaptype.eq.2) then ! MyCall,???,???
               apmask=0
               if(ncontest.eq.0.or.ncontest.eq.1) then
                  apmask(1:29)=1
                  llrd(1:29)=apmag*apbits(1:29)
               else if(ncontest.eq.2) then
                  apmask(1:28)=1
                  llrd(1:28)=apmag*apbits(1:28)
               else if(ncontest.eq.3) then
                  apmask(1:28)=1
                  llrd(1:28)=apmag*apbits(1:28)
               else if(ncontest.eq.4) then
                  apmask(2:29)=1
                  llrd(2:29)=apmag*apbits(1:28)
               else if(ncontest.eq.6) then ! ??? RR73; MyCall <???> ???
                  apmask(29:56)=1
                  llrd(29:56)=apmag*apbits(1:28)
               endif
            endif

            if(iaptype.eq.3) then ! MyCall,DxCall,???
               apmask=0
               if(ncontest.eq.0.or.ncontest.eq.1.or.ncontest.eq.2.or.ncontest.eq.6) then
                  apmask(1:58)=1
                  llrd(1:58)=apmag*apbits
               else if(ncontest.eq.3) then ! Field Day
                  apmask(1:56)=1
                  llrd(1:28)=apmag*apbits(1:28)
                  llrd(29:56)=apmag*apbits(30:57)
               else if(ncontest.eq.4) then ! RTTY RU
                  apmask(2:57)=1
                  llrd(2:29)=apmag*apbits(1:28)
                  llrd(30:57)=apmag*apbits(30:57)
               endif
            endif

            if(iaptype.eq.5.and.ncontest.eq.6) cycle !Hound
            if(iaptype.eq.4 .or. iaptype.eq.5 .or. iaptype.eq.6) then
               apmask=0
               if(ncontest.le.4 .or. (ncontest.eq.6.and.iaptype.eq.6)) then
                  apmask(1:77)=1   ! mycall, hiscall, RRR|73|RR73
                  llrd(1:58)=apmag*apbits
                  if(iaptype.eq.4) llrd(59:77)=apmag*mrrr
                  if(iaptype.eq.5) llrd(59:77)=apmag*m73
                  if(iaptype.eq.6) llrd(59:77)=apmag*mrr73
               else if(ncontest.eq.6.and.iaptype.eq.4) then ! Hound listens for MyCall RR73;...
                  apmask(1:28)=1
                  llrd(1:28)=apmag*apbits(1:28)
               endif
            endif

            llr=llrd
         endif
         max_iterations=40
         call clockit('bpdecode',0)
         call bpdecode174_91(llr,apmask,max_iterations,message77,     &
            cw,nharderror,niterations)
         call clockit('bpdecode',1)
         if(sum(message77).eq.0) cycle
         if( nharderror.ge.0 ) then
            message77=mod(message77+rvec,2)
            write(c77,'(77i1)') message77(1:77)
            call unpack77(c77,1,message,unpk77_success)
            idupe=0
            do i=1,ndecodes
               if(decodes(i).eq.message) idupe=1
            enddo
            if(idupe.eq.1) exit
            ndecodes=ndecodes+1
            decodes(ndecodes)=message
            if(snr.gt.0.0) then
               xsnr=10*log10(snr)-14.0
            else
               xsnr=-20.0
            endif
            nsnr=nint(max(-20.0,xsnr))
            freq=f0
            tsig=mod(tbuf + ibest/750.0,100.0)

            write(line,1000) hhmmss,nsnr,tsig,nint(freq),message
1000        format(a6,i4,f5.1,i5,' + ',1x,a37)
            l1=index(data_dir,char(0))-1
            data_dir(l1+1:l1+1)="/"
            fname=data_dir(1:l1+1)//'all_ft4.txt'
            open(24,file=trim(fname),status='unknown',position='append')
            write(24,1002) cdatetime0,nsnr,tsig,nint(freq),message,    &
               nharderror,nsync_qual,ipass,niterations,iaptype
            if(hhmmss.eq.'      ') write(*,1002) cdatetime0,nsnr,             &
               tsig,nint(freq),message,nharderror,nsync_qual,ipass,    &
               niterations,iaptype
1002        format(a17,i4,f5.1,i5,' Rx  ',a37,5i5)
            close(24)
            linex(ndecodes)=line

!### Temporary: assume most recent decoded message conveys "hiscall". ###
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
               if(index(message,' 559 ').gt.8) nrx=2        !### Not right !
               if(index(message,' R 559 ').gt.8) nrx=3      !### Not right !
               if(index(message,' RR73 ').gt.8) nrx=4
            endif
            nrxx(ndecodes)=nrx
!###
            exit

         endif
      enddo !Sequence estimation
   enddo    !Candidate list
   call clockit('ft4_deco',1)
   call clockit2(data_dir)
   call clockit('ft4_deco',101)
   return

 entry get_ft4msg(idecode,nrx,line)
   line=linex(idecode)
   nrx=nrxx(idecode)
   return

end subroutine ft4_decode
