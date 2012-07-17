subroutine syncmsk(cdat,npts,cwb,r,i1)

! Establish character sync within a JTMS ping.

  complex cdat(npts)                    !Analytic signal
  complex cwb(168)                      !Complex waveform for 'space'
  real r(60000)
  real tmp(60000)
  integer hist(168),hmax(1)
  complex z

  r=0.
  jz=npts-168+1
  do j=1,jz
     z=0.
     ss=0.
     do i=1,168
        ss=ss + abs(cdat(i+j-1))          !Total power
        z=z + cdat(i+j-1)*conjg(cwb(i))   !Signal matching <space>
     enddo
     r(j)=abs(z)/ss                       !Goodness-of-fit to <space>
!     write(52,3001) j/168.0,r(j),cdat(j)
!3001 format(4f12.3)
  enddo

  ncut=99.0*float(jz-10)/float(jz)
  call pctile(r,tmp,jz,ncut,rlim)
  hist=0
  do j=1,jz
     k=mod(j-1,168)+1
     if(r(j).gt.rlim) hist(k)=hist(k)+1
  enddo

  hmax=maxloc(hist)
  i1=hmax(1)

  return
end subroutine syncmsk
