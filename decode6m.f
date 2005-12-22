      subroutine decode6m(data,jz,cfile6,MinSigdB,istart,
     +  NFixLen,lcum,f0,lumsg,npkept,yellow)

C  Decode a JT6M message.  Data must start at the beginning of a 
C  sync symbol; sync frequency is assumed to be f0.

      parameter (NMAX=30*11025)
      real data(jz)              !Raw data
      real s2db(0:43,646)        !Spectra of symbols
c      real s2(128,646)
      real syncsig(646)
      real yellow(216)
      real ref(0:43)
      logical lcum
      character*43 pua
      character*48 msg
      character*6 cfile6
      real*8 dpha,twopi
      complex*16 z,dz
      complex zz
      complex ct(0:511)
      complex c
      common/hcom/c(NMAX)
      data pua/'0123456789., /#?$ABCDEFGHIJKLMNOPQRSTUVWXYZ'/
      data offset/20.6/

      ps(zz)=real(zz)**2 + imag(zz)**2          !Power spectrum function

C  Convert data to baseband (complex result) using quadrature LO.
      twopi=8*atan(1.d0)
      dpha=twopi*f0/11025.d0
      dz=cmplx(cos(dpha),-sin(dpha))
      z=1.d0/dz
      do i=1,jz
         z=z*dz
         c(i)=data(i)*z
      enddo

C  Get spectrum for each symbol.
C  NB: for decoding pings, could do FFTs first for sync intervals only, 
C  and then for data symbols only where the sync amplitude is above 
C  threshold.  However, for the average message we want all FFTs computed.

      call zero(ref,44)

      nh=256
      nz=jz/512 - 1
      fac=1.0/512.0
      do j=1,nz        
         i0=512*(j-1) + 1
          do i=0,511
c            fac=1.0/512.0 * abs(i-nh)/float(nh)       !Window OK?
            ct(i)=fac*c(i0+i)
         enddo
         call four2a(ct,512,1,-1,1)

C  Save PS for each symbol
         do i=0,127
            xps=ps(ct(i))
            if(i.le.43) s2db(i,j)=xps
c            s2(i+1,j)=xps
         enddo
         if(mod(j,3).eq.1) call add(ref,s2db(0,j),ref,44) !Accumulate ref spec
      enddo

C  Return sync-tone amplitudes for plotting.
      iz=nz/3 -1
      do i=1,iz
         j=3*i-2
         yellow(i)=s2db(0,j)-0.5*(s2db(0,j+1)+s2db(0,j+2))
      enddo
      yellow(216)=iz

      fac=3.0/nz
      do i=0,43                               !Normalize the ref spectrum
         ref(i)=fac*ref(i)
      enddo
      ref(0)=ref(2)                           !Sync bin uses bin 2 as ref

      do j=1,nz                               !Compute strength of sync
         m=mod(j-1,3)                         !signal at each j.
         ja=j-m-3
         jb=ja+3
         if(ja.lt.1) ja=ja+3
         if(jb.gt.nz) jb=jb-3
         syncsig(j)=0.5*(s2db(0,ja)+s2db(0,jb))/ref(0)
         syncsig(j)=db(syncsig(j)) - offset
         do i=0,43                            !Normalize s2db
            s2db(i,j)=s2db(i,j)/ref(i)
         enddo
      enddo

C  Decode any message of 2 or more consecutive characters bracketed by
C  sync-tones above a threshold.
C  Use hard-decoding (i.e., pick max bin).

      nslim=MinSigdB                       !Signal limit for decoding
      ndf0=nint(f0-1076.77)                !Freq offset DF, in Hz
      n=0                                  !Number of decoded characters
      j0=0
      sbest=-1.e9
      do j=2,nz-1,3
         if(syncsig(j).ge.float(nslim)) then

C  Is it time to write out the results?
            if((n.eq.48) .or. (j.ne.j0+3 .and. j0.ne.0)) then
               nsig=nint(sbest)
               width=(512./11025.)*(1.5*n+1.0)
               if(nsig.ge.nslim) then
                  npkept=npkept+1
                  write(lumsg,1010) cfile6,tping,width,
     +            nsig,ndf0,(msg(k:k),k=1,n)
                  if(lcum) write(21,1010) cfile6,tping,width,
     +              nsig,ndf0,(msg(k:k),k=1,n)
 1010             format(a6,2f5.1,i4,i5,6x,48a1)       !### 6x was 7x ###
               endif
               n=0
               sbest=-1.e9
            endif
            j0=j
            smax1=-1.e9
            do i=1,43                         !Pick max bin for 1st char
               if(s2db(i,j).gt.smax1) then
                  smax1=s2db(i,j)
                  ipk=i
               endif
            enddo
            n=n+1
            if(n.eq.1) tping=j*512./11025. + (istart-1)/11025.0 !Start of ping
            msg(n:n)=pua(ipk:ipk)                        !Decoded character

            smax2=-1.e9
            do i=1,43
               if(s2db(i,j+1).gt.smax2) then
                  smax2=s2db(i,j+1)
                  ipk=i
               endif
            enddo
            n=n+1
            msg(n:n)=pua(ipk:ipk)
            sig0=10.0**(0.1*(syncsig(j)+offset))
            sig=db(0.5*sig0 + 0.25*(smax1+smax2))-offset
            sbest=max(sbest,sig)
         endif
      enddo

      nsig=nint(sbest)
      width=(512./11025.)*(1.5*n+1.0)
      if(n.ne.0 .and. nsig.ge.nslim) then
         npkept=npkept+1
         write(lumsg,1010) cfile6,tping,
     +     width,nsig,ndf0,(msg(k:k),k=1,n)
         if(lcum) write(21,1010) cfile6,tping,
     +     width,nsig,ndf0,(msg(k:k),k=1,n)
      endif

C  Decode average message for the whole record.
      call avemsg6m(s2db,nz,nslim,NFixLen,cfile6,lcum,f0,lumsg,npkept)

      return
      end
