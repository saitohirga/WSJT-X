subroutine plotsave(splot,ka,nbpp,irow,jz,swide)

  parameter (NSMAX=6827,NYMAX=64)
  real splot(NSMAX)
  real spsave(NSMAX,NYMAX)
  real swide(jz)
  real s(NSMAX),tmp(NSMAX)
  data ncall/0/
  save ncall,spsave

  df=12000.0/16384
  if(irow.lt.0) then
! Save a new row of data
     ncall=ncall+1
     k=mod(ncall-1,NYMAX) + 1
     spsave(1:NSMAX,k)=splot
     rewind 61
     do i=1,NSMAX
        write(61,3061) i,splot(i),ncall
3061    format(i8,f12.3,i8)
     enddo
  else
! Process and return the saved "irow" as swide(), for a waterfall replot.
     k=mod(NYMAX+ncall-1-irow,NYMAX) + 1
     if(nbpp.eq.1) then
        swide=spsave(1:jz,k)
     else
        s=spsave(1:NSMAX,k)
        call smo(s,NSMAX,tmp,nbpp)
        k=ka
        do j=1,jz
           smax=0.
           do i=1,nbpp
              k=k+1
              if(k.lt.1 .or. k.gt.NSMAX) exit
              smax=max(smax,s(k))
           enddo
           swide(j)=smax
        enddo
     endif
  endif

  return
end subroutine plotsave
