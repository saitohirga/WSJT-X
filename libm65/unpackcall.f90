subroutine unpackcall(ncall,word,iv2,psfx)

  parameter (NBASE=37*36*10*27*27*27)
  character word*12,c*37,psfx*4

  data c/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ '/

  n=ncall
  iv2=0
  if(n.ge.262177560) go to 20
  word='......'
  if(n.ge.262177560) go to 999            !Plain text message ...
  i=mod(n,27)+11
  word(6:6)=c(i:i)
  n=n/27
  i=mod(n,27)+11
  word(5:5)=c(i:i)
  n=n/27
  i=mod(n,27)+11
  word(4:4)=c(i:i)
  n=n/27
  i=mod(n,10)+1
  word(3:3)=c(i:i)
  n=n/10
  i=mod(n,36)+1
  word(2:2)=c(i:i)
  n=n/36
  i=n+1
  word(1:1)=c(i:i)
  do i=1,4
     if(word(i:i).ne.' ') go to 10
  enddo
  go to 999
10 word=word(i:)
  go to 999

20 if(n.ge.267796946) go to 999

! We have a JT65v2 message
  if((n.ge.262178563) .and. (n.le.264002071)) Then
! CQ with prefix
     iv2=1
     n=n-262178563
     i=mod(n,37)+1
     psfx(4:4)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(3:3)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(2:2)=c(i:i)
     n=n/37
     i=n+1
     psfx(1:1)=c(i:i)
  endif

  if((n.ge.264002072) .and. (n.le.265825580)) Then
! QRZ with prefix
     iv2=2
     n=n-264002072
     i=mod(n,37)+1
     psfx(4:4)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(3:3)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(2:2)=c(i:i)
     n=n/37
     i=n+1
     psfx(1:1)=c(i:i)
  endif

  if((n.ge.265825581) .and. (n.le.267649089)) Then
! DE with prefix
     iv2=3
     n=n-265825581
     i=mod(n,37)+1
     psfx(4:4)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(3:3)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(2:2)=c(i:i)
     n=n/37
     i=n+1
     psfx(1:1)=c(i:i)
  endif

  if((n.ge.267649090) .and. (n.le.267698374)) Then
! CQ with suffix
     iv2=4
     n=n-267649090
     i=mod(n,37)+1
     psfx(3:3)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(2:2)=c(i:i)
     n=n/37
     i=n+1
     psfx(1:1)=c(i:i)
  endif

  if((n.ge.267698375) .and. (n.le.267747659)) Then
! QRZ with suffix
     iv2=5
     n=n-267698375
     i=mod(n,37)+1
     psfx(3:3)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(2:2)=c(i:i)
     n=n/37
     i=n+1
     psfx(1:1)=c(i:i)
  endif

  if((n.ge.267747660) .and. (n.le.267796944)) Then
! DE with suffix
     iv2=6
     n=n-267747660
     i=mod(n,37)+1
     psfx(3:3)=c(i:i)
     n=n/37
     i=mod(n,37)+1
     psfx(2:2)=c(i:i)
     n=n/37
     i=n+1
     psfx(1:1)=c(i:i)
  endif

  if(n.eq.267796945) Then
! DE with no prefix or suffix
     iv2=7
     psfx = '    '
  endif

999 if(word(1:3).eq.'3D0') word='3DA0'//word(4:)

  return
end subroutine unpackcall
