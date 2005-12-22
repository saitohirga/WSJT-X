      subroutine lpf1(data,n,nz)

C  Half-band lowpass filter and decimate by 2.

      real data(n)

      nz=n/2 -10
      do i=1,nz
         j=2*i+8
         data(i)=0.047579*(data(j-9)+data(j+9)) 
     +         - 0.073227*(data(j-7)+data(j+7))
     +         + 0.113449*(data(j-5)+data(j+5))
     +         - 0.204613*(data(j-3)+data(j+3))
     +         + 0.633339*(data(j-1)+data(j+1))
     +         + data(j)
      enddo
      return
      end

