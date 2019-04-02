module ft4_decode
  
  type :: ft4_decoder
     procedure(ft4_decode_callback), pointer :: callback
   contains
     procedure :: decode
  end type ft4_decoder

  abstract interface
     subroutine ft4_decode_callback (this,sync,snr,dt,freq,decoded,nap,qual)
       import ft4_decoder
       implicit none
       class(ft4_decoder), intent(inout) :: this
       real, intent(in) :: sync
       integer, intent(in) :: snr
       real, intent(in) :: dt
       real, intent(in) :: freq
       character(len=37), intent(in) :: decoded
       integer, intent(in) :: nap 
       real, intent(in) :: qual 
     end subroutine ft4_decode_callback
  end interface

contains

  subroutine decode(this,callback,iwave,nQSOProgress,nfqso,    &
       nutc,nfa,nfb,ndepth,ncontest,mycall,hiscall)
    use timer_module, only: timer
    use packjt77
    include 'ft4/ft4_params.f90'
    class(ft4_decoder), intent(inout) :: this
    procedure(ft4_decode_callback) :: callback
    parameter (NSS=NSPS/NDOWN)

   character message*37,msgsent*37,msg0*37
   character c77*77
   character*37 decodes(100)
   character*512 data_dir,fname
   character*17 cdatetime0
   character*12 mycall,hiscall
   character*12 mycall0,hiscall0
   character*6 hhmmss
   character*4 cqstr,cqstr0

   complex cd2(0:NMAX/NDOWN-1)                  !Complex waveform
   complex cb(0:NMAX/NDOWN-1)
   complex cd(0:NN*NSS-1)                       !Complex waveform
   complex ctwk(2*NSS),ctwk2(2*NSS,-16:16)
   complex csymb(NSS)
   complex cs(0:3,NN)
   real s4(0:3,NN)

   real bmeta(2*NN),bmetb(2*NN),bmetc(2*NN)
   real a(5)
   real llr(2*ND),llra(2*ND),llrb(2*ND),llrc(2*ND),llrd(2*ND)
   real s2(0:255)
   real candidate(3,100)
   real savg(NH1),sbase(NH1)

   integer apbits(2*ND)
   integer apmy_ru(28),aphis_fd(28)
   integer icos4a(0:3),icos4b(0:3),icos4c(0:3),icos4d(0:3)
   integer*2 iwave(NMAX)                 !Raw received data
   integer*1 message77(77),rvec(77),apmask(2*ND),cw(2*ND)
   integer*1 hbits(2*NN)
   integer graymap(0:3)
   integer ip(1)
   integer nappasses(0:5)    ! # of decoding passes for QSO States 0-5
   integer naptypes(0:5,4)   ! nQSOProgress, decoding pass
   integer mcq(29)
   integer mrrr(19),m73(19),mrr73(19)

   logical nohiscall,unpk77_success
   logical one(0:255,0:7)    ! 256 4-symbol sequences, 8 bits
   logical first, dobigfft

   data icos4a/0,1,3,2/
   data icos4b/1,0,2,3/
   data icos4c/2,3,1,0/
   data icos4d/3,2,0,1/
   data graymap/0,1,3,2/
   data msg0/' '/
   data first/.true./
   data     mcq/0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0/
   data    mrrr/0,1,1,1,1,1,1,0,1,0,0,1,0,0,1,0,0,0,1/
   data     m73/0,1,1,1,1,1,1,0,1,0,0,1,0,1,0,0,0,0,1/
   data   mrr73/0,1,1,1,1,1,1,0,0,1,1,1,0,1,0,1,0,0,1/
   data rvec/0,1,0,0,1,0,1,0,0,1,0,1,1,1,1,0,1,0,0,0,1,0,0,1,1,0,1,1,0, &
      1,0,0,1,0,1,1,0,0,0,0,1,0,0,0,1,0,1,0,0,1,1,1,1,0,0,1,0,1, &
      0,1,0,1,0,1,1,0,1,1,1,1,1,0,0,0,1,0,1/
   save fs,dt,tt,txt,twopi,h,one,first,apbits,nappasses,naptypes, &
      mycall0,hiscall0,msg0,cqstr0,ctwk2
    
    this%callback => callback

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

      do idf=-16,16
         a=0.
         a(1)=real(idf)
         ctwk=1.
         call twkfreq1(ctwk,2*NSS,fs/2.0,a,ctwk2(:,idf))
      enddo

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
      naptypes(0,1:4)=(/1,2,0,0/) ! Tx6 selected (CQ)
      naptypes(1,1:4)=(/2,3,0,0/) ! Tx1
      naptypes(2,1:4)=(/2,3,0,0/) ! Tx2
      naptypes(3,1:4)=(/3,6,0,0/) ! Tx3
      naptypes(4,1:4)=(/3,6,0,0/) ! Tx4
      naptypes(5,1:4)=(/3,1,2,0/) ! Tx5

      mycall0=''
      hiscall0=''
      cqstr0=''
      first=.false.
   endif

   if(cqstr.ne.cqstr0) then
      i0=index(cqstr,' ')
      if(i0.le.1) then 
         message='CQ A1AA AA01'
      else
         message='CQ '//cqstr(1:i0-1)//' A1AA AA01'
      endif
      i3=-1
      n3=-1
      call pack77(message,i3,n3,c77)
      call unpack77(c77,1,msgsent,unpk77_success)
      read(c77,'(29i1)') mcq
      mcq=2*mod(mcq+rvec(1:29),2)-1
      cqstr0=cqstr
   endif

   l1=index(mycall,char(0))
   if(l1.ne.0) mycall(l1:)=" "
   l1=index(hiscall,char(0))
   if(l1.ne.0) hiscall(l1:)=" "
   if(mycall.ne.mycall0 .or. hiscall.ne.hiscall0) then
      apbits=0
      apbits(1)=99
      apbits(30)=99
      apmy_ru=0
      aphis_fd=0

      if(len(trim(mycall)) .lt. 3) go to 10 

      nohiscall=.false.
      hiscall0=hiscall
      if(len(trim(hiscall0)).lt.3) then
         hiscall0=mycall  ! use mycall for dummy hiscall - mycall won't be hashed.
         nohiscall=.true.
      endif
      message=trim(mycall)//' '//trim(hiscall0)//' RR73'
      i3=-1
      n3=-1
      call pack77(message,i3,n3,c77)
      call unpack77(c77,1,msgsent,unpk77_success)
      if(i3.ne.1 .or. (message.ne.msgsent) .or. .not.unpk77_success) go to 10 
      read(c77,'(77i1)') message77
      apmy_ru=2*mod(message77(1:28)+rvec(2:29),2)-1
      aphis_fd=2*mod(message77(30:57)+rvec(29:56),2)-1
      message77=mod(message77+rvec,2)
      call encode174_91(message77,cw)
      apbits=2*cw-1
      if(nohiscall) apbits(30)=99

10    continue
      mycall0=mycall
      hiscall0=hiscall
   endif
   candidate=0.0
   ncand=0
   syncmin=1.2
   maxcand=100

   fa=nfa
   fb=nfb
   call getcandidates4(iwave,fa,fb,syncmin,nfqso,maxcand,savg,candidate,   &
      ncand,sbase)

   ndecodes=0
   dobigfft=.true.
   do icand=1,ncand
      f0=candidate(1,icand)
      snr=candidate(3,icand)-1.0
      call ft4_downsample(iwave,dobigfft,f0,cd2)  !Downsample to 32 Sam/Sym
      if(dobigfft) dobigfft=.false.
      sum2=sum(cd2*conjg(cd2))/(real(NMAX)/real(NDOWN))
      if(sum2.gt.0.0) cd2=cd2/sqrt(sum2)
! Sample rate is now 12000/16 = 750 samples/second
      do isync=1,2
         if(isync.eq.1) then
            idfmin=-12
            idfmax=12
            idfstp=3
            ibmin=0
!            ibmax=216                     !Max DT = 216/750 = 0.288 s
            ibmax=432
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
            do istart=ibmin,ibmax,ibstp
               call sync4d(cd2,istart,ctwk2(:,idf),1,sync)  !Find sync power
               if(sync.gt.smax) then
                  smax=sync
                  ibest=istart
                  idfbest=idf
               endif
            enddo
         enddo
      enddo
      f0=f0+real(idfbest)
      if( f0.le.10.0 .or. f0.ge.4990.0 ) cycle
!      write(*,3002) smax,ibest/750.0,f0
!3002  format('b',3f8.2)
      call ft4_downsample(iwave,dobigfft,f0,cb) !Final downsample with corrected f0
      sum2=sum(abs(cb)**2)/(real(NSS)*NN)
      if(sum2.gt.0.0) cb=cb/sqrt(sum2)
      cd=cb(ibest:ibest+NN*NSS-1)
      do k=1,NN
         i1=(k-1)*NSS
         csymb=cd(i1:i1+NSS-1)
         call four2a(csymb,NSS,1,-1,1)
         cs(0:3,k)=csymb(1:4)
         s4(0:3,k)=abs(csymb(1:4))
      enddo

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
      nsync=is1+is2+is3+is4   !Number of correct hard sync symbols, 0-16
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

      bmetb(205:206)=bmeta(205:206)
      bmetc(201:204)=bmetb(201:204)
      bmetc(205:206)=bmeta(205:206)

      call normalizebmet(bmeta,2*NN)
      call normalizebmet(bmetb,2*NN)
      call normalizebmet(bmetc,2*NN)

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

! ncontest=0 : NONE
!          1 : NA_VHF
!          2 : EU_VHF
!          3 : FIELD DAY
!          4 : RTTY
!          5 : FOX
!          6 : HOUND
!
! Conditions that cause us to bail out of AP decoding
            napwid=50
            if(ncontest.le.4 .and. iaptype.ge.3 .and. (abs(f0-nfqso).gt.napwid) ) cycle
            if(iaptype.ge.2 .and. apbits(1).gt.1) cycle  ! No, or nonstandard, mycall
            if(iaptype.ge.3 .and. apbits(30).gt.1) cycle ! No, or nonstandard, dxcall

            if(iaptype.eq.1) then  ! CQ or CQ TEST or CQ FD or CQ RU or CQ SCC
               apmask=0
               apmask(1:29)=1
               llrd(1:29)=apmag*mcq(1:29)
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
                  llrd(2:29)=apmag*apmy_ru(1:28)
               endif
            endif

            if(iaptype.eq.3) then ! MyCall,DxCall,???
               apmask=0
               if(ncontest.eq.0.or.ncontest.eq.1.or.ncontest.eq.2) then
                  apmask(1:58)=1
                  llrd(1:58)=apmag*apbits(1:58)
               else if(ncontest.eq.3) then ! Field Day
                  apmask(1:56)=1
                  llrd(1:28)=apmag*apbits(1:28)
                  llrd(29:56)=apmag*aphis_fd(1:28)
               else if(ncontest.eq.4) then ! RTTY RU
                  apmask(2:57)=1
                  llrd(2:29)=apmag*apmy_ru(1:28)
                  llrd(30:57)=apmag*apbits(30:57)
               endif
            endif

            if(iaptype.eq.4 .or. iaptype.eq.5 .or. iaptype.eq.6) then
               apmask=0
               if(ncontest.le.4) then
                  apmask(1:91)=1   ! mycall, hiscall, RRR|73|RR73
                  if(iaptype.eq.6) llrd(1:91)=apmag*apbits(1:91)
               endif
            endif

            llr=llrd
         endif
         max_iterations=40
         message77=0
         call bpdecode174_91(llr,apmask,max_iterations,message77,     &
            cw,nharderror,niterations)
         if(sum(message77).eq.0) cycle
         if( nharderror.ge.0 ) then
            message77=mod(message77+rvec,2) ! remove rvec scrambling
            write(c77,'(77i1)') message77(1:77)
            call unpack77(c77,1,message,unpk77_success)
            idupe=0
            do i=1,ndecodes
               if(decodes(i).eq.message) idupe=1
            enddo
            if(ibest.le.10 .and. message.eq.msg0) idupe=1   !Already decoded
            if(idupe.eq.1) exit
            ndecodes=ndecodes+1
            decodes(ndecodes)=message
            if(snr.gt.0.0) then
               xsnr=10*log10(snr)-14.0
            else
               xsnr=-20.0
            endif
            nsnr=nint(max(-20.0,xsnr))
            xdt=ibest/750.0 - 0.45
            call this%callback(sync,nsnr,xdt,f0,message,iaptype,qual)
            if(ibest.ge.ibmax-15) msg0=message         !Possible dupe candidate
            exit
         endif
      enddo !Sequence estimation
   enddo    !Candidate list
    
  return
  end subroutine decode

end module ft4_decode
