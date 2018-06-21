program t1

  real x(13)
  real(KIND=16) :: dlong,dlong0
  character wd*13,w*13,error*5
  character c*44                        !NB: 44^13 = 2^(70.973)
  data c/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ+-./?@$'/

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: t1 "FreeText13"'
     print*,'       t1 <iters>'
     go to 999
  endif
  call getarg(1,w)
  iters=1
  read(w,*,err=10) iters
10 continue
  
  do iter=1,iters
     if(iters.gt.1) then
! Create a random free-text word        
        call random_number(x)
        do i=1,13
           j=44*x(i) + 1
           w(i:i)=c(j:j)
        enddo
     endif
! Encode a 13-character free-text message into a 71-bit integer.
     dlong=0.d0
     do i=1,13
        n=index(c,w(i:i))-1
        dlong=44.d0*dlong + n
     enddo
     dlong0=dlong
     
     ! Decode a a 71-bit integer into a 13-character free-text message.
     do i=13,1,-1
        j=mod(dlong,44.d0)+1.d0
        wd(i:i)=c(j:j)
        dlong=dlong/44.d0
     enddo

     
     error='     '
     if(wd.ne.w) then
        error='ERROR'
        write(*,1010) w,dlong0,wd,error
1010    format('"',a13,'"',f25.1,2x,'"',a13'"',2x,a5)
     endif
     if(mod(iter,1000).eq.0) print*,iter
  enddo

999 end program t1
