subroutine get_ft4s_bitmetrics(cd,bitmetrics,badsync)

   include 'ft4s_params.f90'
   parameter (NSS=20)
   complex cd(0:NN*NSS-1)
   complex cs(0:3,NN)
   complex csymb(NSS)
   integer icos4a(0:3),icos4b(0:3)
   integer icos4c(0:3),icos4d(0:3)
   integer icos4e(0:3),icos4f(0:3)
   integer graymap(0:3)
   integer ip(1)
   logical one(0:65535,0:15)    ! 65536 8-symbol sequences, 16 bits
   logical first
   logical badsync
   real bitmetrics(2*NN,4)
   real s2(0:65535)
   real s4(0:3,NN)

   data icos4a/0,1,3,2/
   data icos4b/1,0,2,3/
   data icos4c/2,3,1,0/
   data icos4d/3,2,0,1/
   data icos4e/0,2,3,1/
   data icos4f/1,2,0,3/
   data graymap/0,1,3,2/
   data first/.true./
   save first,one

   if(first) then
      one=.false.
      do i=0,65535
         do j=0,15
            if(iand(i,2**j).ne.0) one(i,j)=.true.
         enddo
      enddo
      first=.false.
   endif

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
   is5=0
   is6=0
   badsync=.false.
   ibmax=0
   
   do k=1,4
      ip=maxloc(s4(:,k))
      if(icos4a(k-1).eq.(ip(1)-1)) is1=is1+1
      ip=maxloc(s4(:,k+28))
      if(icos4b(k-1).eq.(ip(1)-1)) is2=is2+1
      ip=maxloc(s4(:,k+56))
      if(icos4c(k-1).eq.(ip(1)-1)) is3=is3+1
      ip=maxloc(s4(:,k+84))
      if(icos4d(k-1).eq.(ip(1)-1)) is4=is4+1
      ip=maxloc(s4(:,k+112))
      if(icos4e(k-1).eq.(ip(1)-1)) is5=is5+1
      ip=maxloc(s4(:,k+140))
      if(icos4f(k-1).eq.(ip(1)-1)) is6=is6+1
   enddo
   nsync=is1+is2+is3+is4+is5+is6   !Number of correct hard sync symbols, 0-24

   badsync=.false.
!   if(nsync .lt. 8) then
!      badsync=.true.
!      return
!   endif

   do nseq=1,4             !Try coherent sequences of 1, 2, and 4 symbols
      if(nseq.eq.1) nsym=1
      if(nseq.eq.2) nsym=2
      if(nseq.eq.3) nsym=4
      if(nseq.eq.4) nsym=8
      nt=2**(2*nsym)
      do ks=1,NN-nsym+1,nsym  !87+16=103 symbols.
         amax=-1.0
         do i=0,nt-1
!            i1=i/64
!            i2=iand(i,63)/16
!            i3=iand(i,15)/4
!            i4=iand(i,3)
            i1=i/16384
            i2=iand(i,16383)/4096
            i3=iand(i,4095)/1024
            i4=iand(i,1023)/256
            i5=iand(i,255)/64
            i6=iand(i,63)/16
            i7=iand(i,15)/4
            i8=iand(i,3)
            if(nsym.eq.1) then
               s2(i)=abs(cs(graymap(i8),ks))
            elseif(nsym.eq.2) then
               s2(i)=abs(cs(graymap(i7),ks)+cs(graymap(i8),ks+1))
            elseif(nsym.eq.4) then
               s2(i)=abs(cs(graymap(i5),ks  ) + &
                  cs(graymap(i6),ks+1) + &
                  cs(graymap(i7),ks+2) + &
                  cs(graymap(i8),ks+3)   &
                  )
            elseif(nsym.eq.8) then
               s2(i)=abs(cs(graymap(i1),ks  ) + &
                  cs(graymap(i2),ks+1) + &
                  cs(graymap(i3),ks+2) + &
                  cs(graymap(i4),ks+3) + &
                  cs(graymap(i5),ks+4) + &
                  cs(graymap(i6),ks+5) + &
                  cs(graymap(i7),ks+6) + &
                  cs(graymap(i8),ks+7)   &
                  )
            else
               print*,"Error - nsym must be 1, 2, 4, or 8."
            endif
         enddo
         ipt=1+(ks-1)*2
         if(nsym.eq.1) ibmax=1
         if(nsym.eq.2) ibmax=3
         if(nsym.eq.4) ibmax=7
         if(nsym.eq.8) ibmax=15
         do ib=0,ibmax
            bm=maxval(s2(0:nt-1),one(0:nt-1,ibmax-ib)) - &
               maxval(s2(0:nt-1),.not.one(0:nt-1,ibmax-ib))
            if(ipt+ib.gt.2*NN) cycle
            bitmetrics(ipt+ib,nseq)=bm
         enddo
      enddo
   enddo

   call normalizebmet(bitmetrics(:,1),2*NN)
   call normalizebmet(bitmetrics(:,2),2*NN)
   call normalizebmet(bitmetrics(:,3),2*NN)
   call normalizebmet(bitmetrics(:,4),2*NN)
   return

end subroutine get_ft4s_bitmetrics
