!> @file
!> @brief Contains module W3BULLMD.
!>
!> @author J. H. Alves
!> @author H. L. Tolman
!> @date   26-Dec-2012
!>

#include "w3macros.h"
!/ ------------------------------------------------------------------- /
!>
!> @brief Module W3BULLMD.
!>
!> @author J. H. Alves
!> @author H. L. Tolman
!> @date   26-Dec-2012
!>
!> @copyright Copyright 2009-2022 National Weather Service (NWS),
!>       National Oceanic and Atmospheric Administration.  All rights
!>       reserved.  WAVEWATCH III is a trademark of the NWS.
!>       No unauthorized use without permission.
!>
MODULE W3BULLMD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH-III           NOAA/NCEP |
  !/                  |           J. H. Alves             |
  !/                  |           H. L. Tolman            |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         26-Dec-2012 |
  !/                  +-----------------------------------+
  !/
  !/    01-APR-2010 : Origination.                        ( version 3.14 )
  !/    25-Jun-2011 : Temporary change of HSMIN           ( version 4.05 )
  !/    15-Aug-2011 : Changing HSMIN to BHSMIN bugfix     ( version 4.05 )
  !/    26-Dec-2012 : Modified obsolete declarations.     ( version 4.11 )
  !/
  !/ ------------------------------------------------------------------- /
  USE W3GDATMD, ONLY: GNAME, NK, NTH, NSPEC, FLAGLL
  USE W3ODATMD, ONLY: NOPTS, PTLOC, PTNME, DIMP
  USE CONSTANTS, ONLY: PI, TPI
  USE W3WDATMD, ONLY: TIME
  USE W3TIMEMD, ONLY: DSEC21
  PUBLIC
  INTEGER, PARAMETER   :: NPTAB = 6, NFLD = 50, NPMAX = 80
  !
  REAL, PARAMETER      :: BHSMIN = 0.15, BHSDROP = 0.05
  REAL                 :: HST(NPTAB,2), TPT(NPTAB,2),     &
       DMT(NPTAB,2)
  CHARACTER(LEN=129)   :: ASCBLINE
  CHARACTER(LEN=664)   :: CSVBLINE
#ifdef W3_NCO
  CHARACTER(LEN=67)    :: CASCBLINE
#endif
  LOGICAL              :: IYY(NPMAX)
  !/
  !/ Conventional declarations
  !/
  !/
  !/ Private parameter statements (ID strings)
  !/
  !/
CONTAINS
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Read a WAVEWATCH-III version 1.17 point output data file and
  !>     produces a table of mean parameters for all individual wave
  !>     systems.
  !>
  !> @details Partitioning is made using the built-in module w3partmd.
  !>     Partitions are ranked and organized into coherent sequences that
  !>     are then written as tables to output files. Input options for generating
  !>     tables are defined in ww3_outp.inp. This module sorts the table
  !>     data, output to file is controlled by WW3_OUTP.
  !>
  !> @param[in]    NPART
  !> @param[in]    XPART
  !> @param[in]    DIMXP
  !> @param[in]    UABS
  !> @param[in]    UD
  !> @param        IPNT
  !> @param[in]    IOUT
  !> @param[inout] TIMEV
  !>
  !> @author J. H. Alves
  !> @author H. L. Tolman
  !> @date   11-Mar-2013
  !>
  SUBROUTINE W3BULL                                                &
       ( NPART, XPART, DIMXP, UABS, UD, IPNT, IOUT, TIMEV )
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH-III           NOAA/NCEP |
    !/                  |           J. H. Alves             |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         11-Mar-2013 !
    !/                  +-----------------------------------+
    !/
    !/    01-Apr-2010 : Origination.                        ( version 3.14 )
    !/    26-Dec-2012 : Modified obsolete declarations.     ( version 4.11 )
    !/    15-Aug-2011 : Adjustments to version 4.05         ( version 4.05 )
    !/    11-Mar-2013 : Minor cleanup                       ( version 4.09 )
    !/
    !  1. Purpose :
    !
    !     Read a WAVEWATCH-III version 1.17 point output data file and
    !     produces a table of mean parameters for all individual wave
    !     systems.
    !
    !  2. Method :
    !
    !     Partitioning is made using the built-in module w3partmd. Partitions
    !     are ranked and organized into coherent sequences that are then
    !     written as tables to output files. Input options for generating
    !     tables are defined in ww3_outp.inp. This module sorts the table
    !     data, output to file is controlled by WW3_OUTP.
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       DHSMAX  Real   Max. change in Hs for system to be considered
    !                      related to previous time.
    !       DTPMAX  Real   Id. Tp.
    !       DDMMAX  Real   Id. Dm.
    !       DDWMAX  Real   Maximum differences in wind and wave direction
    !                      for marking of system as under the influence
    !                      of the local wind,
    !       AGEMIN  Real   Id. wave age.
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Sur.  W3SERVMD Subroutine tracing.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !     WW3_OUTP
    !
    !  6. Error messages :
    !
    !     Error control made in WW3_OUTP.
    !
    !  7. Remarks :
    !
    !     Current version does not allow generating tables for multiple
    !     points.
    !
    !  8. Structure :
    !
    !  9. Switches :
    !
    !     !/S    Enable subroutine tracing.
    !     !/T    Enable test output
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    !     USE CONSTANTS
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    !/
    !
    ! -------------------------------------------------------------------- /
    ! 1.  Initializations
    !
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    REAL                    :: DHSMAX, DTPMAX,        &
         DDMMAX, DDWMAX, AGEMIN
    PARAMETER     ( DHSMAX =   1.50 )
    PARAMETER     ( DTPMAX =   1.50 )
    PARAMETER     ( DDMMAX =  15.   )
    PARAMETER     ( DDWMAX =  30.   )
    PARAMETER     ( AGEMIN =   0.8  )
    INTEGER, INTENT(IN)     :: NPART, DIMXP, IOUT
    INTEGER, INTENT(INOUT)  :: TIMEV(2)
    REAL, INTENT(IN)        :: UABS,    &
         UD, XPART(DIMP,0:DIMXP)
    INTEGER                 :: IPG1,IPI(NPMAX), ILEN(NPMAX), IP,     &
         IPNOW, IFLD, INOTAB, IPNT, ITAB,      &
         DOUTP, FCSTI, NZERO
    REAL                    :: AFR, AGE, DDMMAXR, DELDM, DELDMR,     &
         DELDW, DELHS, DELTP, DHSMAXR,  &
         DTPMAXR, HMAX, HSTOT, TP, UDIR, FACT
    REAL                    :: HSP(NPMAX), TPP(NPMAX), &
         DMP(NPMAX), WNP(NPMAX), HSD(NPMAX),   &
         TPD(NPMAX), WDD(NPMAX)
    LOGICAL                 :: FLAG(NPMAX)
    CHARACTER(LEN=129)      :: BLANK, TAIL !, ASCBLINE
#ifdef W3_NCO
    CHARACTER(LEN=67)       :: CBLANK, CTAIL !, CASCBLINE
#endif
    CHARACTER(LEN=15)       :: PART
#ifdef W3_NCO
    CHARACTER(LEN=9)        :: CPART
#endif
    CHARACTER(LEN=664)      :: BLANK2 !,CSVBLINE
    CHARACTER               :: STIME*8,FORM*20,FORM1*2
    CHARACTER(LEN=16)       :: PART2
    !/
    !/ ------------------------------------------------------------------- /
    !
#ifdef W3_S
    CALL STRACE (IENT, 'XXXXXX')
#endif
    !
    ! 1.a Constants etc.
    !
    ! Set FACT to proper scaling according to spherical or cartesian
    IF ( FLAGLL ) THEN
      FACT = 1.
    ELSE
      FACT = 1.E-3
    ENDIF
    !
    ! Convert wind direction to azimuthal reference
    UDIR   = MOD( UD+180., 360. )
    !
    TAIL (  1: 40) = '+-------+-----------+-----------------+-'
    TAIL ( 41: 80) = '----------------+-----------------+-----'
    TAIL ( 81:120) = '------------+-----------------+---------'
    TAIL (120:129) = '---------+'
    BLANK(  1: 40) = '| nn nn |      nn   |                 | '
    BLANK( 41: 80) = '                |                 |     '
    BLANK( 81:120) = '            |                 |         '
    BLANK(120:129) = '         |'
    ASCBLINE       = BLANK
#ifdef W3_NCO
    CTAIL( 1:40) = '----------------------------------------'
    CTAIL(41:67) = '---------------------------'
    CBLANK( 1:40) = '                                        '
    CBLANK(41:67) = '                           '
    CASCBLINE       = CBLANK
#endif
    !
    BLANK2(  1: 40)='    ,    ,  ,  ,  ,     ,   ,     ,     '
    BLANK2( 41: 88)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2( 89:136)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(137:184)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(185:232)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(233:280)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(281:328)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(329:376)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(377:424)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(425:472)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(473:520)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(521:568)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(569:616)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    BLANK2(617:664)=',     ,     ,   ,     ,     ,   ,     ,     ,   '
    !
    CSVBLINE      = BLANK2
    !
    IPG1 = 0
    IF (IOUT .EQ. 1) THEN
      DO IP=1, NPTAB
        HST(IP,1) = -99.9
        TPT(IP,1) = -99.9
        DMT(IP,1) = -99.9
      ENDDO
      DO IP=1, NPMAX
        IYY(IP) = .FALSE.
        IPI(IP)=1
        ILEN(IP)=0
      ENDDO
    ENDIF
    !
    ! 3.  Get overall wave height ---------------------------------------- *
    !
    HSTOT  = XPART(1,0)
    TP     = XPART(2,0)
    DO IP=1, NPART
      HSP(IP) = XPART(1,IP)
      TPP(IP) = XPART(2,IP)
      WNP(IP) = TPI / XPART(3,IP)
      DMP(IP) = MOD( XPART(4,IP) + 180., 360.)
    ENDDO

    NZERO = 0
    NZERO = COUNT( HSP <= BHSMIN .AND. HSP /= 0.  )
    !
    ! 4.  Process all partial fields ------------------------------------- *
    !
    DO IP=NPART+1, NPMAX
      HSP(IP) =    0.00
      TPP(IP) = -999.99
      DMP(IP) = -999.99
    ENDDO

    DO IP=1, NPTAB
      HST(IP,2) = HST(IP,1)
      TPT(IP,2) = TPT(IP,1)
      DMT(IP,2) = DMT(IP,1)
      HST(IP,1) = -1.
      TPT(IP,1) = -1.
      DMT(IP,1) = -1.
    ENDDO
    !
    ! 5.  Generate output table ------------------------------------------ *
    ! 5.a Time and overall wave height to string
    !
    ASCBLINE = BLANK
    CSVBLINE = BLANK2
#ifdef W3_NCO
    CASCBLINE = CBLANK
#endif
    !
    ! Fill the variable forecast time with hrs relative to reference time
    IF ( TIMEV(1) .LE. 0 ) TIMEV = TIME
    FCSTI = DSEC21 (TIMEV, TIME) / 3600
    WRITE(CSVBLINE(1:4),'(I4)')FCSTI
    !
    DO IFLD=1,NPTAB
      IYY(IFLD)=.FALSE.
    ENDDO
    !
    ! ... write the time labels for current table line
    WRITE (CSVBLINE(6:9),'(I4)') INT(TIME(1)/10000)
    WRITE (CSVBLINE(11:12),'(I2)')                                  &
         INT(TIME(1)/100)-100*INT(TIME(1)/10000)
    WRITE (CSVBLINE(14:15),'(I2)') MOD(TIME(1),100)
    WRITE (CSVBLINE(17:18),'(I2)') TIME(2)/10000
    WRITE (CSVBLINE(20:24),'(F5.2)') UABS
    WRITE (CSVBLINE(26:28),'(I3)') INT(UDIR)
    IF ( HSTOT .GT. 0. ) WRITE (CSVBLINE(30:34),'(F5.2)') HSTOT
    IF ( HSTOT .GT. 0. ) WRITE (CSVBLINE(36:40),'(F5.2)') TP
    !
    WRITE (ASCBLINE(3:4),'(I2)') MOD(TIME(1),100)
    WRITE (ASCBLINE(6:7),'(I2)') TIME(2)/10000
    !
    IF ( HSTOT .GT. 0. ) WRITE (ASCBLINE(10:14),'(F5.2)') HSTOT
    WRITE (ASCBLINE(16:17),'(I2)') NPART - NZERO
    !
#ifdef W3_NCO
    WRITE (CASCBLINE(1:2),'(I2.2)') MOD(TIME(1),100)
    WRITE (CASCBLINE(3:4),'(I2.2)') TIME(2)/10000
    IF ( HSTOT .GT. 0. ) WRITE (CASCBLINE(6:7),'(I2)') NINT(HSTOT/0.3048)
#endif
    !
    IF ( NPART.EQ.0 .OR. HSTOT.LT.0.1 ) GOTO 699
    !
    ! 5.b Switch off peak with too low wave height
    !
    DO IP=1, NPART
      FLAG(IP) = HSP(IP) .GT. BHSMIN
    ENDDO
    !
    ! 5.c Find next highest wave height
    !
    INOTAB   = 0
    !
601 CONTINUE
    !
    HMAX   = 0.
    IPNOW  = 0
    DO IP=1, NPART
      IF ( HSP(IP).GT.HMAX .AND. FLAG(IP) ) THEN
        IPNOW  = IP
        HMAX   = HSP(IP)
      ENDIF
    ENDDO
    !
    ! 5.d No more peaks, skip to output
    !
    IF ( IPNOW .EQ. 0 ) GOTO 699
    !
    ! 5.e Find matching field
    !
    ITAB   = 0
    !
    DO IP=1, NPTAB
      IF ( TPT(IP,2) .GT. 0. ) THEN
        !
        DELHS  = ABS ( HST(IP,2) - HSP(IPNOW) )
        DELTP  = ABS ( TPT(IP,2) - TPP(IPNOW) )
        DELDM  = ABS ( DMT(IP,2) - DMP(IPNOW) )
        IF ( DELDM .GT. 180. ) DELDM = 360. - DELDM
        IF ( DELHS.LT.DHSMAX .AND. &
             DELTP.LT.DTPMAX .AND. &
             DELDM.LT.DDMMAX ) ITAB = IP
        !
      ENDIF
    ENDDO
    !
    ! 5.f No matching field, find empty fields
    !
    IF ( ITAB .EQ. 0 ) THEN
      DO IP=NPTAB, 1, -1
        IF ( TPT(IP,1).LT.0. .AND. TPT(IP,2).LT.0. )    &
             ITAB = IP
      ENDDO
    ENDIF
    !
    ! 5.g Slot in table found, write
    !
    ! Remove clear windseas
    !
    IF ( ITAB .NE. 0 ) THEN
      !
      WRITE (PART,'(1X,F5.2,F5.1,I4)')                             &
           HSP(IPNOW), TPP(IPNOW), NINT(DMP(IPNOW))
#ifdef W3_NCO
      WRITE (CPART,'(I2,1X,I2.2,1X,I3.3)')                         &
           NINT(HSP(IPNOW)/0.3048),                              &
           NINT(TPP(IPNOW)),                                     &
           NINT(MOD(DMP(IPNOW)+180.,360.))
#endif
      DELDW  = MOD ( ABS ( UDIR - DMP(IPNOW) ) , 360. )
      IF ( DELDW .GT. 180. ) DELDW = 360. - DELDW
      AFR    = 2.*PI/TPP(IPNOW)
      AGE    = UABS * WNP(IPNOW) / AFR
      IF ( DELDW.LT.DDWMAX .AND. AGE.GT.AGEMIN ) PART(1:1) = '*'
      !
      ASCBLINE(5+ITAB*18:19+ITAB*18) = PART
#ifdef W3_NCO
      CASCBLINE(ITAB*10-1:ITAB*10+7) = CPART
#endif
      !
      DO IFLD=1,NPTAB
        IF(ITAB.EQ.IFLD)THEN
          IYY(IFLD)=.TRUE.
          HSD(IFLD)=HSP(IPNOW)
          TPD(IFLD)=TPP(IPNOW)
          WDD(IFLD)=NINT(DMP(IPNOW))
        ENDIF
      ENDDO
      !
      HST(ITAB,1) = HSP(IPNOW)
      TPT(ITAB,1) = TPP(IPNOW)
      DMT(ITAB,1) = DMP(IPNOW)

      !
      ! 5.h No slot in table found, write
      !
    ELSE
      !
      INOTAB   = INOTAB + 1
      WRITE (ASCBLINE(19:19),'(I1)') INOTAB
      !
    ENDIF
    !
    FLAG(IPNOW) = .FALSE.
    GOTO 601
    !
    ! 5.i End of processing, write line in table
    !
699 CONTINUE
    !
    DO IFLD=1,NPTAB
      IF(IYY(IFLD))THEN
        ILEN(IFLD)=ILEN(IFLD)+1
        IF (ILEN(IFLD).EQ.1)THEN
          IPI(IFLD)=IPG1+1
          IPG1=IPG1+1
        ENDIF
        WRITE (PART2,'(",",F5.2,",",F5.2,",",I3)')                   &
             HSD(IFLD), TPD(IFLD), NINT(WDD(IFLD))
        CSVBLINE(25+IPI(IFLD)*16:40+IPI(IFLD)*16) = PART2
      ELSE
        ILEN(IFLD)=0
      ENDIF
    ENDDO
    !
    RETURN
    !/
    !/ End of W3BULL ----------------------------------------------------- /
    !/
  END SUBROUTINE W3BULL
  !/
  !/ End of module W3BULLMD -------------------------------------------- /
  !/
END MODULE W3BULLMD
