      subroutine avemsg6m(s2db,nz,nslim,NFixLen,cfile6,lcum,
     +  f0,lumsg,npkept)

C  Attempts to find message length and then decodes an average message.

      real s2db(0:43,nz)
      real s2dc(0:43,22)
      real wgt(22)
      real acf(0:430)
      logical lcum
      character*43 pua
      character*6 cfile6
      character*22 avemsg,blanks
      data pua/'0123456789., /#?$ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
      data blanks/'                      '/
      data twopi/6.283185307/
      data offset/20.6/

C  Adjustable sig limit, depending on length of data to average.
      nslim2=nslim - 9 + 4.0*log10(624.0/nz)       !### +10 was here

      k=0
      sum=0.
      nsum=0
      do j=1,nz
         if(mod(j,3).eq.1) then
            sum=sum+s2db(0,j)        !Measure avg sig strength for sync tone
            nsum=nsum+1
         else
            k=k+1
            call move(s2db(0,j),s2db(0,k),44)  !Save data spectra
         endif
      enddo
      sig=sum/nsum                                 !Signal strength estimate
      nsig=nint(db(sig)-offset)

C  Most of the time in this routine is in this loop.
      kz=k
      do lag=0,kz-1
         sum=0.
         do j=1,kz-lag
            do i=0,43
               sum=sum+s2db(i,j)*s2db(i,j+lag)
            enddo
         enddo
         acf(lag)=sum
      enddo
      acf0=acf(0)
      do lag=0,kz-1
         acf(lag)=acf(lag)/acf0
      enddo

      lmsg1=NFixLen/256
      lmsg2=NFixLen-256*lmsg1
      if(mod(lmsg1,2).eq.1) lmsg1=lmsg1+1
      if(mod(lmsg2,2).eq.1) lmsg2=lmsg2+1
      smax=-1.e9
      do ip=4,22,2               !Compute periodogram for allowed msg periods
         if(NFixLen.ne.0 .and. ip.ne.4 .and. ip.ne.lmsg1 
     +     .and. ip.ne.lmsg2) go to 5
         f=1.0/ip
         s=0.
         do lag=0,kz-1
            s=s+acf(lag)*cos(twopi*f*lag)
         enddo
         if(s.gt.smax) then
            smax=s
            msglen=ip                            !Save best message length
         endif
 5    enddo

C  Average the symbols from s2db into s2dc.

      call zero(s2dc,44*22)
      call zero(wgt,22)
      do j=1,kz
         k=mod(j-1,msglen)+1
         call add(s2db(0,j),s2dc(0,k),s2dc(0,k),44)
         wgt(k)=wgt(k)+1.0
      enddo

      do j=1,msglen                            !Hard-decode the avg msg,
         smax=-1.e9                            !picking max bin for each char
         do i=1,43
            s2dc(i,j)=s2dc(i,j)/wgt(j)
            if(s2dc(i,j).gt.smax) then
               smax=s2dc(i,j)
               ipk=i
            endif
         enddo
         k=mod(ipk,3)
         i=ipk
         avemsg(j:j)=pua(i:i)
      enddo
      ndf0=nint(f0-1076.66)
      do i=1,msglen
         if(avemsg(i:i).eq.' ') goto 10
      enddo
      go to 20
 10   avemsg=avemsg(i+1:msglen)//avemsg(1:i)
 20   if(nsig.gt.nslim2) then
         npkept=npkept+1
         avemsg=avemsg(1:msglen)//blanks
         write(lumsg,1020) cfile6,nsig,ndf0,avemsg,msglen
         if(lcum) write(21,1020) cfile6,nsig,ndf0,avemsg,msglen
 1020    format(a6,8x,i6,i5,7x,a22,19x,'*',i4)
      endif

      return
      end
