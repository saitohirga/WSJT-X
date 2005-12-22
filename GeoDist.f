	subroutine geodist(Eplat, Eplon, Stlat, Stlon,
     +	  Az, Baz, Dist)
	implicit none
	real eplat, eplon, stlat, stlon, az, baz, dist, deg

C JHT: In actual fact, I use the first two arguments for "My Location",
C      the second two for "His location"; West longitude is positive.

c
c
c	Taken directly from:
c	Thomas, P.D., 1970, Spheroidal geodesics, reference systems,
c	& local geometry, U.S. Naval Oceanographic Office SP-138,
c	165 pp.
c
c	assumes North Latitude and East Longitude are positive
c
c	EpLat, EpLon = End point Lat/Long
c	Stlat, Stlon = Start point lat/long
c	Az, BAz = direct & reverse azimuith
c	Dist = Dist (km); Deg = central angle, discarded
c

	real BOA, F, P1R, P2R, L1R, L2R, DLR, T1R, T2R, TM,
     +    DTM, STM, CTM, SDTM,CDTM, KL, KK, SDLMR, L,
     +    CD, DL, SD, T, U, V, D, X, E, Y, A, FF64, TDLPM,
     +    HAPBR, HAMBR, A1M2, A2M1

	real AL,BL,D2R,Pi2

	data AL/6378206.4/		! Clarke 1866 ellipsoid
	data BL/6356583.8/
c	real pi /3.14159265359/
	data D2R/0.01745329251994/	! degrees to radians conversion factor
	data Pi2/6.28318530718/

        BOA = BL/AL
        F = 1.0 - BOA
c convert st/end pts to radians
        P1R = Eplat * D2R
        P2R = Stlat * D2R
        L1R = Eplon * D2R
        L2R = StLon * D2R
        DLR = L2R - L1R			! DLR = Delta Long in Rads
        T1R = ATan(BOA * Tan(P1R))
        T2R = ATan(BOA * Tan(P2R))
        TM = (T1R + T2R) / 2.0
        DTM = (T2R - T1R) / 2.0
        STM = Sin(TM)
        CTM = Cos(TM)
        SDTM = Sin(DTM)
        CDTM = Cos(DTM)
        KL = STM * CDTM
        KK = SDTM * CTM
        SDLMR = Sin(DLR/2.0)
        L = SDTM * SDTM + SDLMR * SDLMR * (CDTM * CDTM - STM * STM)
        CD = 1.0 - 2.0 * L
        DL = ACos(CD)
        SD = Sin(DL)
        T = DL/SD
        U = 2.0 * KL * KL / (1.0 - L)
        V = 2.0 * KK * KK / L
        D = 4.0 * T * T
        X = U + V
        E = -2.0 * CD
        Y = U - V
        A = -D * E
        FF64 = F * F / 64.0
        Dist = AL*SD*(T -(F/4.0)*(T*X-Y)+FF64*(X*(A+(T-(A+E)
     +    /2.0)*X)+Y*(-2.0*D+E*Y)+D*X*Y))/1000.0
        Deg = Dist/111.195
        TDLPM = Tan((DLR+(-((E*(4.0-X)+2.0*Y)*((F/2.0)*T+FF64*
     +    (32.0*T+(A-20.0*T)*X-2.0*(D+2.0)*Y))/4.0)*Tan(DLR)))/2.0)
        HAPBR = ATan2(SDTM,(CTM*TDLPM))
        HAMBR = Atan2(CDTM,(STM*TDLPM))
        A1M2 = Pi2 + HAMBR - HAPBR
        A2M1 = Pi2 - HAMBR - HAPBR

1	If ((A1M2 .ge. 0.0) .AND. (A1M2 .lt. Pi2)) GOTO 5
2	If (A1M2 .lt. Pi2) GOTO 4
3	A1M2 = A1M2 - Pi2
        GOTO 1
4	A1M2 = A1M2 + Pi2
        GOTO 1
c
c all of this gens the proper az, baz (forward and back azimuth)
c

5	If ((A2M1 .ge. 0.0) .AND. (A2M1 .lt. Pi2)) GOTO 9
6	If (A2M1 .lt. Pi2) GOTO 8
7	A2M1 = A2M1 - Pi2
        GOTO 5
8	A2M1 = A2M1 + Pi2
        GOTO 5

9	Az = A1M2 / D2R
	BAZ = A2M1 / D2R
c
c Fix the mirrored coords here.
c
	az = 360.0 - az
	baz = 360.0 - baz
	end
