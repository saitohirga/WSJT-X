      FUNCTION igray(n,is)
      INTEGER igray,is,n
      INTEGER idiv,ish
      if (is.ge.0) then
        igray=ieor(n,n/2)
      else
        ish=-1
        igray=n
1       continue
          idiv=ishft(igray,ish)
          igray=ieor(igray,idiv)
          if(idiv.le.1.or.ish.eq.-16)return
          ish=ish+ish
        goto 1
      endif
      return
      END
C  (C) Copr. 1986-92 Numerical Recipes Software *(t9,12.
