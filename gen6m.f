      subroutine gen6m(msg,samfac,iwave,nwave)

C  Encodes a message into a wavefile for transmitting JT6M signals.

      parameter (NMAX=21504)     !NMAX=28*512*3/2: number of waveform samples
      character*28 msg           !Message to be generated
      real*8 samfac
      real*4 x(NMAX)             !Data for wavefile
      integer*2 iwave(NMAX)      !Generated wave file
      integer*4 imsg(28)

      do i=27,1,-1                           !Get message length
         if(msg(i:i).ne.' ') go to 10
      enddo
      i=1
 10   nmsg=i+1
      if(mod(nmsg,2).eq.1) nmsg=nmsg+1       !Make it even

      nwave=nmsg*512*3/2
      do m=1,nmsg                            !Get character code numbers
         ic=m
         n=ichar(msg(ic:ic))
C  Calculate i in range 0-42:
         if(n.ge.ichar('0') .and. n.le.ichar('9')) i=n-ichar('0')
         if(msg(ic:ic).eq.'.') i=10
         if(msg(ic:ic).eq.',') i=11
         if(msg(ic:ic).eq.' ') i=12
         if(msg(ic:ic).eq.'/') i=13
         if(msg(ic:ic).eq.'#') i=14
         if(msg(ic:ic).eq.'?') i=15
         if(msg(ic:ic).eq.'$') i=16
         if(n.ge.ichar('a') .and. n.le.ichar('z')) i=n-ichar('a')+17
         if(n.ge.ichar('A') .and. n.le.ichar('Z')) i=n-ichar('A')+17
         imsg(m)=i
      enddo

      k=1
      do i=1,nmsg,2
         call gentone(x(k),-1,k)               !Generate a sync tone
         call gentone(x(k),imsg(i),k)          !First character
         call gentone(x(k),imsg(i+1),k)        !Second character
      enddo

      do i=1,nwave
         iwave(i)=nint(32767.0*x(i))
      enddo

      return
      end
