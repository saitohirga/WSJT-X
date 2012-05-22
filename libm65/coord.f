        SUBROUTINE COORD(A0,B0,AP,BP,A1,B1,A2,B2)

C  Examples:
C  1. From ha,dec to az,el:
C       call coord(pi,pio2-lat,0.,lat,ha,dec,az,el)
C  2. From az,el to ha,dec:
C       call coord(pi,pio2-lat,0.,lat,az,el,ha,dec)
C  3. From ra,dec to l,b
C       call coord(4.635594495,-0.504691042,3.355395488,0.478220215,
C         ra,dec,l,b)
C  4. From l,b to ra,dec
C       call coord(1.705981071d0,-1.050357016d0,2.146800277d0,
C         0.478220215d0,l,b,ra,dec)
C  5. From ra,dec to ecliptic latitude (eb) and longitude (el):
C       call coord(0.d0,0.d0,-pio2,pio2-23.443*pi/180,ra,dec,el,eb)
C  6. From ecliptic latitude (eb) and longitude (el) to ra,dec:
C       call coord(0.d0,0.d0,-pio2,pio2-23.443*pi/180,el,eb,ra,dec)


      SB0=sin(B0)
      CB0=cos(B0)
      SBP=sin(BP)
      CBP=cos(BP)
      SB1=sin(B1)
      CB1=cos(B1)
      SB2=SBP*SB1 + CBP*CB1*cos(AP-A1)
      CB2=SQRT(1.e0-SB2**2)
      B2=atan(SB2/CB2)
      SAA=sin(AP-A1)*CB1/CB2
      CAA=(SB1-SB2*SBP)/(CB2*CBP)
      CBB=SB0/CBP
      SBB=sin(AP-A0)*CB0
      SA2=SAA*CBB-CAA*SBB
      CA2=CAA*CBB+SAA*SBB
      TA2O2=0.0 !Shut up compiler warnings. -db
      IF(CA2.LE.0.e0) TA2O2=(1.e0-CA2)/SA2 
      IF(CA2.GT.0.e0) TA2O2=SA2/(1.e0+CA2)
      A2=2.e0*atan(TA2O2)
      IF(A2.LT.0.e0) A2=A2+6.2831853
      RETURN
      END
