subroutine extract(s3,nadd,nqd,ncount,nhist,decoded,ltext,nbmkv)

! Input:
!   s3       64-point spectra for each of 63 data symbols
!   nadd     number of spectra summed into s3
!   nqd      0/1 to indicate decode attempt at QSO frequency

! Output:
!   ncount   number of symbols requiring correction
!   nhist    maximum number of identical symbol values
!   decoded  decoded message (if ncount >=0)
!   ltext    true if decoded message is free text
!   nbmkv    0=no decode; 1=BM decode; 2=KV decode

  use prog_args                       !shm_key, exe_dir, data_dir

  real s3(64,63)
  character decoded*22
  integer dat4(12)
  integer mrsym(63),mr2sym(63),mrprob(63),mr2prob(63)
  logical nokv,ltext
  common/decstats/num65,numbm,numkv,num9,numfano
  data nokv/.false./,nsec1/0/
  save

  nbirdie=7
  npct=40
  afac1=10.1
  xlambda=7.999
  if(nqd.eq.1) xlambda=11.999               !Increase depth at QSO frequency
  nbmkv=0
  nfail=0
  decoded='                      '
  call pctile(s3,4032,npct,base)
  s3=s3/base

! Get most reliable and second-most-reliable symbol values, and their
! probabilities
1 call demod64a(s3,nadd,afac1,mrsym,mrprob,mr2sym,mr2prob,ntest,nlow)
  if(ntest.lt.100) then
     ncount=-999                      !Flag and reject bad data
     go to 900
  endif

  call chkhist(mrsym,nhist,ipk)       !Test for birdies and QRM
  if(nhist.ge.nbirdie) then
     nfail=nfail+1
     call pctile(s3,4032,npct,base)
     s3(ipk,1:63)=base
     if(nfail.gt.30) then
        decoded='                      '
        ncount=-1
        go to 900
     endif
     go to 1
  endif

  call graycode65(mrsym,63,-1)        !Remove gray code and interleaving
  call interleave63(mrsym,-1)         !from most reliable symbols
  call interleave63(mrprob,-1)
  num65=num65+1

! Decode using Berlekamp-Massey algorithm
  call timer('rs_decod',0)
  call rs_decode(mrsym,0,0,dat4,ncount)
  call timer('rs_decod',1)
  if(ncount.ge.0) then
     call unpackmsg(dat4,decoded)
     if(iand(dat4(10),8).ne.0) ltext=.true.
     nbmkv=1
     go to 900
  endif

! Berlekamp-Massey algorithm failed, try Koetter-Vardy
  if(nokv) go to 900

  maxe=8                             !Max KV errors in 12 most reliable symbols
  call graycode65(mr2sym,63,-1)      !Remove gray code and interleaving
  call interleave63(mr2sym,-1)       !from second-most-reliable symbols
  call interleave63(mr2prob,-1)

  nsec1=nsec1+1
  dat4=0
  write(22,rec=1) nsec1,xlambda,maxe,200,mrsym,mrprob,mr2sym,mr2prob
  write(22,rec=2) -1,-1,dat4
  call flush(22)
  call timer('kvasd   ',0)

#ifdef WIN32
  iret=system('""'//trim(exe_dir)//'/kvasd" "'//trim(temp_dir)//'/kvasd.dat" >"'//trim(temp_dir)//'/dev_null""')
#else
  iret=system('"'//trim(exe_dir)//'/kvasd" "'//trim(temp_dir)//'/kvasd.dat" >/dev/null')
#endif

  call timer('kvasd   ',1)
  if(iret.ne.0) then
     if(.not.nokv) write(*,1000) iret
1000 format('Error in KV decoder, or no KV decoder present.',i12)
!     nokv=.true.
     go to 900
  endif

  read(22,rec=2,err=900) nsec2,ncount,dat4
  j=nsec2                             !Silence compiler warning
  decoded='                      '
  ltext=.false.
  if(ncount.ge.0) then
     call unpackmsg(dat4,decoded)     !Unpack the user message
     if(index(decoded,'...... ').gt.0) then
        ncount=-1
        go to 900
     endif
     if(iand(dat4(10),8).ne.0) ltext=.true.
     nbmkv=2
  endif

900 continue
  if(nbmkv.eq.1) numbm=numbm+1
  if(nbmkv.eq.2) numkv=numkv+1

  return
end subroutine extract
