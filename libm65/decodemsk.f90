subroutine decodemsk(cdat,npts,cw,i1,nchar,s2,msg)

! DF snd sync have been established, now decode the message

  complex cdat(npts)
  complex cw(168,0:63)                  !Complex waveforms for codewords
  real s2(0:63,400)
  character msg*400
  complex z,zmax
  character cc*64
!                    1         2         3         4         5         6
!          0123456789012345678901234567890123456789012345678901234567890123
  data cc/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ./?-                 _     @'/

  msg=' '
  do j=1,nchar                         !Find best match for each character
     ia=i1 + (j-1)*168
     smax=0.
     do k=0,40
        kk=k
        if(k.eq.40) kk=44
        z=0.
        do i=1,168
           z=z + cdat(ia+i)*conjg(cw(i,kk))
        enddo
        ss=abs(z)
        s2(k,j)=ss
        if(ss.gt.smax) then
           smax=ss
           zmax=z
           kpk=kk
        endif
     enddo
     msg(j:j)=cc(kpk+1:kpk+1)
     if(kpk.eq.44) msg(j:j)=' '
  enddo

  return
end subroutine decodemsk
