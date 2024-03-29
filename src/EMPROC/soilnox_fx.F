!=======================================================================
!     MODULE SOILNOX_FX
!
!     This module contain functions to assist soil NOx calculation.
!     
!
!     CONTAINS: 1)FERTLZ_ADJ
!               2)VEG_ADJ
!               3)GROWSEASON
!
!     Note:
!
!     Requirement:
!
!
!     Imported from SMOKE-BEIS v3.14 and modified
!          by Tan 07/21/11 for MEGAN v2.10
!
!     Function PRECADJ is moved to MET2MGN
!              PULSETYPE is moved to MET2MGN
!              PRECIPFAC is moved to MET2MGN
!
!     History:
!
!=======================================================================

      MODULE SOILNOX_FX

      IMPLICIT NONE

!...  Program I/O parameters

!...  External parameters

      CONTAINS




!=======================================================================
!=======================================================================
      REAL FUNCTION FERTLZ_ADJ( DATE, LAT )

C***********************************************************************
C  DESCRIPTION:
C    This internal function computes a fertilizer adjustment factor
C    for the given date in yyyyddd format. If it is not growing 
C    season, the adjustment factor is 0; otherwise, it ranges from
C    0.0 to 1.0.
C
C  CALL:
C    GROWSEASON
C
C  HISTORY:
C    07/21/11 : Imported from SMOKE-BEIS v3.14 and modified  (Tan)
C***********************************************************************

      IMPLICIT NONE
            
C.... Function arguments
      INTEGER, INTENT(IN) :: DATE
      REAL,    INTENT(IN) :: LAT

C.... Local variables
      INTEGER  GDAY, GLEN

      CHARACTER(256)  MESG         ! message buffer
C-----------------------------------------------------------------------------

      CALL GROWSEASON( DATE, LAT, GDAY, GLEN )

      IF( GDAY == 0 ) THEN
          FERTLZ_ADJ = 0.
      ELSE IF( GDAY >= 1 .AND. GDAY < 30 ) THEN
          ! first month of growing season
          FERTLZ_ADJ = 1.
      ELSE IF( GDAY >= 30 .AND. GDAY <= 366) THEN
          ! later month of growing season
          FERTLZ_ADJ = 1. + 30. / FLOAT(GLEN) - FLOAT(GDAY) / FLOAT(GLEN)
      ELSE
          WRITE( MESG,94010 ) 'Invalid date specified; date = ', 
     &                        DATE, 'growing season day = ',
     &                        GDAY
          CALL M3EXIT( 'FERTLZ_ADJ', 0, 0, MESG, 2 )
      ENDIF

C******************  FORMAT  STATEMENTS   ******************************
94010 FORMAT( A, F10.2, 1X, A, I3, ',', I3 )


      RETURN

      END FUNCTION FERTLZ_ADJ
!=======================================================================
!=======================================================================


!=======================================================================
!=======================================================================
      REAL FUNCTION VEG_ADJ( LAI )

C***********************************************************************
C  DESCRIPTION
C    This internal function computes a vegetation adjustment factor
C    based on LAIv.  See Yienger and Levy 1995
C    VEG_ADJ = (EXP(-0.24*LAIv)+EXP(-0.0525*LAIv))*0.5 
C
C  CALL
C    NONE
C
C  HISTORY:
C***********************************************************************

      IMPLICIT NONE
      
C...  Function arguments
      REAL,    INTENT(IN) :: LAI


C-----------------------------------------------------------------------------

      VEG_ADJ = (EXP(-0.24*LAI)+EXP(-0.0525*LAI))*0.5 

C******************  FORMAT  STATEMENTS   ******************************

      RETURN
      END FUNCTION VEG_ADJ
!=======================================================================
!=======================================================================
            


!=======================================================================
!=======================================================================
      SUBROUTINE GROWSEASON ( DATE, LAT, GDAY, GLEN )

C***********************************************************************
C  DESCRIPTION
C    This internal function computes the day of the growing season
C    corresponding to the given date in yyyyddd format.
C
C  CALL
C    JULIAN
C
C  HISTORY:
C    07/21/11 : Imported from SMOKE-BEIS v3.14 and modified  (Tan)
C               Variation of growing season depends on latitude
C               (Guenther)
C***********************************************************************

      IMPLICIT NONE

C.......  Function arguments
      INTEGER, INTENT(IN) :: DATE
      REAL,    INTENT(IN) :: LAT

C.......  External functions
      INTEGER, EXTERNAL :: JULIAN

C.......  Local parameters
      INTEGER            :: GSEASON_START
      INTEGER            :: GSEASON_END

C.......  Local variables
      INTEGER  YEAR, MONTH, DAY
      INTEGER  JDAY, GDAY, GLEN
      INTEGER  GSJULIAN_START
      INTEGER  GSJULIAN_END
      CHARACTER(256)  MESG         ! message buffer

C-----------------------------------------------------------------------------

      YEAR = INT( FLOAT( DATE ) / 1000. )
      JDAY = DATE - YEAR * 1000

      IF( JDAY .LT. 1 .OR. JDAY .GT. 366 ) THEN
         WRITE( MESG,94010 ) 'Invalid date specified; date = ',
     &                       DATE, 'jday = ', JDAY
         CALL M3EXIT( 'GROWSEASON', 0, 0, MESG, 2 )
      ENDIF

      IF ( LAT .LE. 23.0 .AND. LAT .GE. -23.0 ) THEN
      ! tropical regions, year round
         GSEASON_START = 0101
         GSEASON_END   = 1231

         GSJULIAN_START = G2J(YEAR, GSEASON_START)
         GSJULIAN_END   = G2J(YEAR, GSEASON_END)
         GDAY = JDAY - GSJULIAN_START + 1
         GLEN = GSJULIAN_END - GSJULIAN_START + 1
      ELSE IF ( LAT .LT. -23.0 ) THEN
      ! southern hemisphere
         IF ( LAT .LT. -60.0 ) THEN
         ! antarctic start = 0 end = 0, no growing
            GDAY = 0
            GLEN = 0
         ELSE
         ! southern hemisphere temperate, NOV, DEC, JAN-MAY
            IF (JDAY .GE. 1101 .AND. JDAY .LE. 1231 ) THEN
              GSEASON_START = 1101
              GSEASON_END   = 1231

              GSJULIAN_START = G2J(YEAR, GSEASON_START)
              GSJULIAN_END   = G2J(YEAR, GSEASON_END)
              GDAY = JDAY - GSJULIAN_START + 1
            ELSE IF (JDAY .GE. 0101 .AND. JDAY .LE. 0531) THEN
              GSEASON_START = 0101
              GSEASON_END   = 0531

              GSJULIAN_START = G2J(YEAR, GSEASON_START)
              GSJULIAN_END   = G2J(YEAR, GSEASON_END)
              GDAY = JDAY - GSJULIAN_START + 1 + 61
            ELSE
              GDAY = 0
            ENDIF
            GLEN = 30 + 31 + G2J(YEAR,0531) - G2J(YEAR,0101) + 1

         ENDIF
      ELSE IF ( LAT .GT. 23.0 ) THEN
      ! northern hemisphere
         IF ( LAT .GT. 65.0 ) THEN
         ! arctic start = 0 end = 0, no growing season
            GDAY = 0
            GLEN = 0
         ELSE
         ! northern hemisphere temperate
         ! start= (lat-23)*4.5            189
         ! end = 365 -((lat-23)*3.3)      226
            GSEASON_START = 0
            GSEASON_END   = 1231

            GSJULIAN_START = 0
            GSJULIAN_END   = G2J(YEAR, GSEASON_END)

            GSJULIAN_START = INT( (LAT-23.0)*4.5 )
            GSJULIAN_END   = GSJULIAN_END -
     &                       INT( (LAT-23.0)*3.3 )
            IF (JDAY .GE. GSJULIAN_START .AND. JDAY .LE. GSJULIAN_END) THEN
               GDAY = JDAY - GSJULIAN_START + 1
            ELSE
               GDAY = 0
            ENDIF
            GLEN = GSJULIAN_END - GSJULIAN_START + 1
         ENDIF
      ELSE
         MESG = 'Invalid LAT'
         CALL M3EXIT( 'GROWSEASON', 0, 0, MESG, 2 )
      ENDIF



C******************  FORMAT  STATEMENTS   ******************************
94010 FORMAT( A, F10.2, 1X, A, I3, ',', I3 )

      RETURN

      END SUBROUTINE GROWSEASON
!=======================================================================
!=======================================================================


!=======================================================================
!=======================================================================
      INTEGER FUNCTION G2J( YYYY, MMDD )
      IMPLICIT NONE

C.......  Function arguments
      INTEGER, INTENT(IN) :: YYYY
      INTEGER, INTENT(IN) :: MMDD

C.......  External functions
      INTEGER, EXTERNAL :: JULIAN

C.......  Local parameters
      INTEGER :: MM
      INTEGER :: DD

      MM = INT( FLOAT( MMDD ) / 100. )
      DD = MMDD - MM * 100
      G2J = JULIAN( YYYY, MM , DD )

      END FUNCTION G2J
!=======================================================================
!=======================================================================
      END MODULE SOILNOX_FX
