      subroutine extract(s3,nadd,ncount,nhist,decoded,ltext)

      real s3(64,63)
      real tmp(4032)
      character decoded*22
      integer era(51),dat4(12),indx(64)
      integer mrsym(63),mr2sym(63),mrprob(63),mr2prob(63)
      logical first,ltext
      data first/.true./,nsec1/0/
      save

      nfail=0
 1    call demod64a(s3,nadd,mrsym,mrprob,mr2sym,mr2prob,ntest,nlow)
      if(ntest.lt.50 .or. nlow.gt.20) then
         ncount=-999                         !Flag bad data
         go to 900
      endif
      call chkhist(mrsym,nhist,ipk)

      if(nhist.ge.20) then
         nfail=nfail+1
         call pctile(s3,tmp,4032,50,base)     ! ### or, use ave from demod64a
         do j=1,63
            s3(ipk,j)=base
         enddo
         go to 1
      endif

      call graycode(mrsym,63,-1)
      call interleave63(mrsym,-1)
      call interleave63(mrprob,-1)

      ndec=1
      nemax=30                              !Was 200 (30)
      maxe=8
      xlambda=13.0                          !Was 12

      if(ndec.eq.1) then
         call graycode(mr2sym,63,-1)
         call interleave63(mr2sym,-1)
         call interleave63(mr2prob,-1)

         nsec1=nsec1+1
         call cs_lock('extracta')
         write(22,rec=1) nsec1,xlambda,maxe,200,
     +        mrsym,mrprob,mr2sym,mr2prob
         call flushqqq(22)
         call cs_unlock
         call runqqq('kvasd.exe','-q',iret)
         if(iret.ne.0) then
            call cs_lock('extractb')
            if(first) write(*,1000) iret
 1000       format('Error in KV decoder, or no KV decoder present.'/
     +         'Return code:',i8,'.  Will use BM algorithm.')
            call cs_unlock
            ndec=0
            first=.false.
            go to 20
         endif
         read(22,rec=2) nsec2,ncount,dat4
         decoded='                      '
         ltext=.false.
         if(ncount.ge.0) then
            call unpackmsg(dat4,decoded) !Unpack the user message
            if(iand(dat4(10),8).ne.0) ltext=.true.
         endif
      endif
 20   if(ndec.eq.0) then
         call indexx(63,mrprob,indx)
         do i=1,nemax
            j=indx(i)
            if(mrprob(j).gt.120) then
               ne2=i-1
               go to 2
            endif
            era(i)=j-1
         enddo
         ne2=nemax
 2       decoded='                      '
         do nerase=0,ne2,2
            call rs_decode(mrsym,era,nerase,dat4,ncount)
            if(ncount.ge.0) then
               call unpackmsg(dat4,decoded)
               go to 900
            endif
         enddo
      endif

 900  return
      end
