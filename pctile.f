	subroutine pctile(x,tmp,nmax,npct,xpct)
	real x(nmax),tmp(nmax)

	do i=1,nmax
	  tmp(i)=x(i)
	enddo
	call sort(nmax,tmp)
	j=nint(nmax*0.01*npct)
	if(j.lt.1) j=1
	xpct=tmp(j)

	return
	end
