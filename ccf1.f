      subroutine ccf1(cx,cy,n5,nflip,a,ccfmax,dtmax)

      parameter (NMAX=60*96000)          !Approx samples per half symbol
      complex cx(n5)
      complex cy(n5)
      real a(5)
      complex w,wstep,za,zb,z
      real ss(2600)
      complex csx(0:NMAX/64),csy(0:NMAX/64)
      data twopi/6.283185307/a1,a2,a3/99.,99.,99./
      save

      if(a(1).ne.a1 .or. a(2).ne.a2 .or. a(3).ne.a3) then
         a1=a(1)
         a2=a(2)
         a3=a(3)

C  Mix and integrate the complex X and Y signals
         csx(0)=0.
         csy(0)=0.
         w=1.0
         x0=0.5*(n5+1)
         s=2.0/n5
         do i=1,n5
            x=s*(i-x0)
            if(mod(i,1000).eq.1) then
               p2=1.5*x*x - 0.5
!               p3=2.5*(x**3) - 1.5*x
!               p4=4.375*(x**4) - 3.75*(x**2) + 0.375
               dphi=(a(1) + x*a(2) + p2*a(3)) * (twopi/1378.125)
               wstep=cmplx(cos(dphi),sin(dphi))
            endif
            w=w*wstep
            csx(i)=csx(i-1) + w*cx(i)
            csy(i)=csy(i-1) + w*cy(i)
         enddo
      endif

C  Compute 1/2-symbol powers at 1/16-symbol steps.
      n6=n5/32
      fac=1.e-4
      pol=a(4)/57.2957795
      aa=cos(pol)
      bb=sin(pol)
      fsample=1378.125
      baud=11025.0/4096.0
      nsph=nint(0.5*fsample/baud)                !Samples per half symbol
      do i=1,n6
         j=32*i
         k=j-nsph
         ss(i)=0.
         if(k.ge.1) then
            za=csx(j)-csx(k)
            zb=csy(j)-csy(k)
            z=aa*za + bb*zb
            ss(i)=fac*(real(z)**2 + aimag(z)**2)
         endif
      enddo

      ccfmax=0.
      call ccf2(ss,n6,nflip,ccf,lagpk)
      if(ccf.gt.ccfmax) then
         ccfmax=ccf
         dtmax=0.5*lagpk*(512.0/11025.0)
      endif

      return
      end
