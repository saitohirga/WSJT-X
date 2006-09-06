      subroutine gencwid(msg,wpm,freqcw,samfac,iwave,nwave)

      parameter (NMAX=10*11025)
      character msg*22,msg2*22
      integer*2 iwave(NMAX)

      integer*1 idat(460)
      real*8 dt,t,twopi,pha,dpha,tdit,samfac
      data twopi/6.283185307d0/

      do i=1,22
         if(msg(i:i).eq.' ') go to 10
       enddo
 10   iz=i-1
      msg2=msg(1:iz)//'                      '
      call morse(msg2,idat,ndits) !Encode part 1 of msg

      tdit=1.2d0/wpm                   !Key-down dit time, seconds
      dt=1.d0/(11025.d0*samfac)
      nwave=ndits*tdit/dt
      pha=0.
      dpha=twopi*freqcw*dt
      t=0.d0
      s=0.
      u=wpm/(11025*0.03)
      do i=1,nwave
         t=t+dt
         pha=pha+dpha
         j=t/tdit + 1
         s=s + u*(idat(j)-s)
         iwave(i)=nint(s*32767.d0*sin(pha))
      enddo

      return
      end

