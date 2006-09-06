      subroutine extract(s3,nadd,ncount,decoded)

      real s3(64,63)
      character decoded*22
      integer era(51),dat4(12),indx(63)
      integer mrsym(63),mr2sym(63),mrprob(63),mr2prob(63)
      logical first
      data first/.true./,nsec1/0/
      save

      call demod64a(s3,nadd,mrsym,mrprob,mr2sym,mr2prob,ntest,nlow)

      if(ntest.lt.50 .or. nlow.gt.20) then
         ncount=-999                         !Flag bad data
         go to 900
      endif

      call graycode(mrsym,63,-1)
      call interleave63(mrsym,-1)
      call interleave63(mrprob,-1)

      ndec=1
      nemax=30
      maxe=8
      xlambda=15.0

      if(ndec.eq.1) then
         call graycode(mr2sym,63,-1)
         call interleave63(mr2sym,-1)
         call interleave63(mr2prob,-1)

         nsec1=nsec1+1
         write(22,rec=1) nsec1,xlambda,maxe,200,
     +        mrsym,mrprob,mr2sym,mr2prob
         call flushqqq(22)
         call runqqq('kvasd.exe','-q',iret)
         if(iret.ne.0) then
            if(first) write(*,1000)
 1000       format('Error in KV decoder, or no KV decoder present.'/
     +         'Using BM algorithm.')
            ndec=0
            first=.false.
            go to 20
         endif
         read(22,rec=2) nsec2,ncount,dat4
         decoded='                      '
         if(ncount.ge.0) then
            call unpackmsg(dat4,decoded) !Unpack the user message
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
