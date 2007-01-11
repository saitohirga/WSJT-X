      SUBROUTINE xfft2(DATA,NB)
c
c     the cooley-tukey fast fourier transform in usasi basic fortran
c
C     .. Scalar Arguments ..
      INTEGER NB
C     ..
C     .. Array Arguments ..
      REAL DATA(NB+2)
C     ..
C     .. Local Scalars ..
      REAL DIFI,DIFR,RTHLF,SUMI,SUMR,T2I,T2R,T3I,T3R,T4I,
     +     T4R,TEMPI,TEMPR,THETA,TWOPI,U1I,U1R,U2I,U2R,U3I,U3R,
     +     U4I,U4R,W2I,W2R,W3I,W3R,WI,WR,WSTPI,WSTPR
      INTEGER I,I2,IPAR,J,K1,K2,K3,K4,KDIF,KMIN,
     +        KSTEP,L,LMAX,M,MMAX,NH
C     ..
C     .. Intrinsic Functions ..
      INTRINSIC COS,MAX0,REAL,SIN
C     ..
C     .. Data statements ..
      DATA TWOPI/6.2831853071796/,RTHLF/0.70710678118655/
c
c        1. real transform for the 1st dimension, n even.  method--
c           transform a complex array of length n/2 whose real parts
c           are the even numbered real values and whose imaginary parts
c           are the odd numbered real values.  separate and supply
c           the second half by conjugate symmetry.
c

      NH = NB/2
c
c     shuffle data by bit reversal, since n=2**k.
c
      J = 1
      DO 131 I2 = 1,NB,2
          IF (J-I2) 124,127,127
  124     TEMPR = DATA(I2)
          TEMPI = DATA(I2+1)
          DATA(I2) = DATA(J)
          DATA(I2+1) = DATA(J+1)
          DATA(J) = TEMPR
          DATA(J+1) = TEMPI
  127     M = NH
  128     IF (J-M) 130,130,129
  129     J = J - M
          M = M/2
          IF (M-2) 130,128,128
  130     J = J + M
  131 CONTINUE

c
c     main loop for factors of two.  perform fourier transforms of
c     length four, with one of length two if needed.  the twiddle factor
c     w=exp(-2*pi*sqrt(-1)*m/(4*mmax)).  check for w=-sqrt(-1)
c     and repeat for w=w*(1-sqrt(-1))/sqrt(2).
c
      IF (NB-2) 174,174,143
  143 IPAR = NH
  144 IF (IPAR-2) 149,146,145
  145 IPAR = IPAR/4
      GO TO 144

  146 DO 147 K1 = 1,NB,4
          K2 = K1 + 2
          TEMPR = DATA(K2)
          TEMPI = DATA(K2+1)
          DATA(K2) = DATA(K1) - TEMPR
          DATA(K2+1) = DATA(K1+1) - TEMPI
          DATA(K1) = DATA(K1) + TEMPR
          DATA(K1+1) = DATA(K1+1) + TEMPI
  147 CONTINUE
  149 MMAX = 2
  150 IF (MMAX-NH) 151,174,174
  151 LMAX = MAX0(4,MMAX/2)
      DO 173 L = 2,LMAX,4
          M = L
          IF (MMAX-2) 156,156,152
  152     THETA = -TWOPI*REAL(L)/REAL(4*MMAX)
          WR = COS(THETA)
          WI = SIN(THETA)
  155     W2R = WR*WR - WI*WI
          W2I = 2.*WR*WI
          W3R = W2R*WR - W2I*WI
          W3I = W2R*WI + W2I*WR
  156     KMIN = 1 + IPAR*M
          IF (MMAX-2) 157,157,158
  157     KMIN = 1
  158     KDIF = IPAR*MMAX
  159     KSTEP = 4*KDIF
          IF (KSTEP-NB) 160,160,169
  160     DO 168 K1 = KMIN,NB,KSTEP
              K2 = K1 + KDIF
              K3 = K2 + KDIF
              K4 = K3 + KDIF
              IF (MMAX-2) 161,161,164
  161         U1R = DATA(K1) + DATA(K2)
              U1I = DATA(K1+1) + DATA(K2+1)
              U2R = DATA(K3) + DATA(K4)
              U2I = DATA(K3+1) + DATA(K4+1)
              U3R = DATA(K1) - DATA(K2)
              U3I = DATA(K1+1) - DATA(K2+1)
              U4R = DATA(K3+1) - DATA(K4+1)
              U4I = DATA(K4) - DATA(K3)
              GO TO 167

  164         T2R = W2R*DATA(K2) - W2I*DATA(K2+1)
              T2I = W2R*DATA(K2+1) + W2I*DATA(K2)
              T3R = WR*DATA(K3) - WI*DATA(K3+1)
              T3I = WR*DATA(K3+1) + WI*DATA(K3)
              T4R = W3R*DATA(K4) - W3I*DATA(K4+1)
              T4I = W3R*DATA(K4+1) + W3I*DATA(K4)
              U1R = DATA(K1) + T2R
              U1I = DATA(K1+1) + T2I
              U2R = T3R + T4R
              U2I = T3I + T4I
              U3R = DATA(K1) - T2R
              U3I = DATA(K1+1) - T2I
              U4R = T3I - T4I
              U4I = T4R - T3R

  167         DATA(K1) = U1R + U2R
              DATA(K1+1) = U1I + U2I
              DATA(K2) = U3R + U4R
              DATA(K2+1) = U3I + U4I
              DATA(K3) = U1R - U2R
              DATA(K3+1) = U1I - U2I
              DATA(K4) = U3R - U4R
              DATA(K4+1) = U3I - U4I
  168     CONTINUE
          KDIF = KSTEP
          KMIN = 4*KMIN - 3
          GO TO 159

  169     M = M + LMAX
          IF (M-MMAX) 170,170,173
  170     TEMPR = WR
          WR = (WR+WI)*RTHLF
          WI = (WI-TEMPR)*RTHLF
          GO TO 155

  173 CONTINUE
      IPAR = 3 - IPAR
      MMAX = MMAX + MMAX
      GO TO 150
c
c     complete a real transform in the 1st dimension, n even, by con-
c     jugate symmetries.
c
  174 THETA = -TWOPI/REAL(NB)
      WSTPR = COS(THETA)
      WSTPI = SIN(THETA)
      WR = WSTPR
      WI = WSTPI
      I = 3
      J = NB - 1
      GO TO 207

  205 SUMR = (DATA(I)+DATA(J))/2.
      SUMI = (DATA(I+1)+DATA(J+1))/2.
      DIFR = (DATA(I)-DATA(J))/2.
      DIFI = (DATA(I+1)-DATA(J+1))/2.
      TEMPR = WR*SUMI + WI*DIFR
      TEMPI = WI*SUMI - WR*DIFR
      DATA(I) = SUMR + TEMPR
      DATA(I+1) = DIFI + TEMPI
      DATA(J) = SUMR - TEMPR
      DATA(J+1) = -DIFI + TEMPI
      I = I + 2
      J = J - 2
      TEMPR = WR
      WR = WR*WSTPR - WI*WSTPI
      WI = TEMPR*WSTPI + WI*WSTPR
  207 IF (I-J) 205,208,211
  208 DATA(I+1) = -DATA(I+1)

  211 DATA(NB+1) = DATA(1) - DATA(2)
      DATA(NB+2) = 0.

      DATA(1) = DATA(1) + DATA(2)
      DATA(2) = 0.

      RETURN
      END
