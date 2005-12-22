      subroutine gencw(msg,wpm,freqcw,samfac,TRPeriod,iwave,nwave)

      parameter (NMAX=150*11025)
      character msg*22,word12*22,word3*22
      integer*2 iwave(NMAX)
      integer TRPeriod

      integer*1 idat(5000),idat1(460),idat2(200),i1
      real*8 dt,t,twopi,pha,dpha,tdit,samfac
      data twopi/6.283185307d0/

      nwords=0
      do i=2,22
         if(msg(i-1:i).eq.'  ') go to 10
         if(msg(i:i).eq.' ') then
            nwords=nwords+1
            j=j0
            j0=i+1
         endif
      enddo
 10   ntype=1                          !Call1+Call2, CQ+Call
      word12=msg
      if(nwords.eq.3) then
         word3=msg(j:j0-1)
         word12(j-1:)='                      '
         ntype=3                       !BC+RO, BC+RRR, BC+73
         if(word3.eq.'OOO') ntype=2    !BC+OOO
      endif

      tdit=1.2d0/wpm                   !Key-down dit time, seconds
      call morse(word12,idat1,nmax1) !Encode part 1 of msg
      t1=tdit*nmax1                    !Time for part1, once
      nrpt1=TRPeriod/t1                !Repetitions of part 1
      if(ntype.eq.2) nrpt1=0.75*TRPeriod/t1
      if(ntype.eq.3) nrpt1=1
      t1=nrpt1*t1                      !Total time for part 1
      nrpt2=0
      t2=0.
      if(ntype.ge.2) then
         call morse(word3,idat2,nmax2) !Encode part 2
         t2=tdit*nmax2                 !Time for part 2, once
         nrpt2=(TRPeriod-t1)/t2        !Repetitions of part 2
         t2=nrpt2*t2                   !Total time for part 2
      endif

      j=0
      do n=1,nrpt1
         do i=1,nmax1
            j=j+1
            idat(j)=idat1(i)
         enddo
      enddo
      do n=1,nrpt2
         do i=1,nmax2
            j=j+1
            idat(j)=idat2(i)
         enddo
      enddo

      dt=1.d0/(11025.d0*samfac)
      nwave=j*tdit/dt
      pha=0.
      dpha=twopi*freqcw*dt
      t=0.
      s=0.
      u=wpm/(11025*0.03)
      do i=1,nwave
         t=t+dt
         pha=pha+dpha
         j=t/tdit + 1
!         iwave(i)=0
!         if(idat(j).ne.0) iwave(i)=nint(32767.d0*sin(pha))
         s=s + u*(idat(j)-s)
         iwave(i)=nint(s*32767.d0*sin(pha))
      enddo

      return
      end

      include 'gencwid.f'
