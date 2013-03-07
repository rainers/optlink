!INCLUDE MAKEMACS

FLAGS = $(MASMFLAGS)
SRC = $(BASE)\COMMON
CFLAGS=-I..\common -r -N_ -o

HEADERS=..\common\all.h ..\common\optlink.h ..\common\errors.h ..\common\io_struc.h \
	..\common\exes.h ..\common\library.h ..\common\symbols.h ..\common\groups.h \
	..\common\segments.h ..\common\segmsyms.h ..\common\lnkdat.h ..\common\cvtypes.h \
	..\common\cvstuff.h ..\common\pe_struc.h


ALL : $(LIB)\COMMON.LIB

$(LIB)\COMMON.LIB : $(OBJ)\THEADR.OBJ $(OBJ)\LNAMES.OBJ $(OBJ)\SEGDEF.OBJ $(OBJ)\GRPDEF.OBJ $(OBJ)\PUBDEF.OBJ $(OBJ)\CEXTDEF.OBJ \
	$(OBJ)\RECORDS.OBJ $(OBJ)\ALIAS.OBJ $(OBJ)\STRTMAP.OBJ $(OBJ)\LNKINIT.OBJ $(OBJ)\LNKDAT.OBJ $(OBJ)\FIXUPP.OBJ \
	$(OBJ)\OPTLNK.OBJ $(OBJ)\CMDSUBS.OBJ $(OBJ)\SUBS.OBJ $(OBJ)\CFGPROC.OBJ $(OBJ)\MSCMDLIN.OBJ $(OBJ)\PERSONAL.OBJ \
	$(OBJ)\ERRORS.OBJ $(OBJ)\PASS1.OBJ $(OBJ)\OBJ_MOD.OBJ $(OBJ)\COMENT.OBJ $(OBJ)\EXTDEF.OBJ $(OBJ)\LEDATA.OBJ \
	$(OBJ)\LINNUM.OBJ $(OBJ)\MODEND.OBJ $(OBJ)\NEWLIB.OBJ $(OBJ)\MIDDLE.OBJ $(OBJ)\STACK.OBJ $(OBJ)\COMDEF.OBJ \
	$(OBJ)\COMDAT.OBJ $(OBJ)\INITMAP.OBJ $(OBJ)\COMDATS.OBJ $(OBJ)\COMMUNAL.OBJ $(OBJ)\ORDER.OBJ $(OBJ)\ALIGN.OBJ \
	$(OBJ)\PACKSEGS.OBJ $(OBJ)\SEGMAP.OBJ $(OBJ)\MAPSUBS.OBJ $(OBJ)\DEFPUBS.OBJ $(OBJ)\QUICK.OBJ $(OBJ)\SYMMAP.OBJ \
	$(OBJ)\FIXUPP2.OBJ $(OBJ)\EXE.OBJ $(OBJ)\LIDATA.OBJ $(OBJ)\LIBASE.OBJ $(OBJ)\XRFMAP.OBJ \
	$(OBJ)\LINMAP.OBJ $(OBJ)\LINSYM.OBJ $(OBJ)\PE_SECT.OBJ $(OBJ)\FORREF.OBJ $(OBJ)\NBKPAT.OBJ \
	$(OBJ)\FORREF2.OBJ $(OBJ)\REXEPACK.OBJ $(OBJ)\UNEXE2.OBJ $(OBJ)\EXEPACK.OBJ $(OBJ)\C32.OBJ $(OBJ)\CSUBS.OBJ \
	$(OBJ)\C32QUIK.OBJ $(OBJ)\QUIKRELO.OBJ $(OBJ)\C32MOVES.OBJ $(OBJ)\INIPROC.OBJ \
	$(OBJ)\cmdsubsc.obj $(OBJ)\optlnkc.obj $(OBJ)\lnkinitc.obj $(OBJ)\pass2c.obj \
	$(OBJ)\newlibc.obj $(OBJ)\macrosc.obj $(OBJ)\fixupp2c.obj $(OBJ)\recordsc.obj \
	$(OBJ)\mscmdlinc.obj
  del $(LIB)\common.lib
  $(BUILD_LIB)

$(OBJ)\LNKINIT.OBJ : LNKINIT.ASM MACROS INITCODE SECTS IO_STRUC SEGMENTS SECTIONS CLASSES EXES MODULES WINMACS TDBG SEGMSYMS PE_STRUC \
			RELEASE SYMBOLS WIN32DEF WINMACS
  ML $(FLAGS) $(SRC)\LNKINIT.ASM

$(OBJ)\LNKDAT.OBJ : LNKDAT.ASM MACROS IO_STRUC SEGMENTS MODULES FIXTEMPS EXES RELEASE SYMCMACS TDBG SEGMSYMS PE_STRUC WIN32DEF SLR32
  ML $(FLAGS) $(SRC)\LNKDAT.ASM

$(OBJ)\OPTLNK.OBJ : OPTLNK.ASM MACROS INITCODE IO_STRUC WIN32DEF
  ML $(FLAGS) $(SRC)\OPTLNK.ASM

$(OBJ)\CMDSUBS.OBJ : CMDSUBS.ASM MACROS SECTS IO_STRUC SECTIONS
  ML $(FLAGS) $(SRC)\CMDSUBS.ASM

$(OBJ)\MSCMDLIN.OBJ : MSCMDLIN.ASM MACROS IO_STRUC MODULES EXES
  ML $(FLAGS) $(SRC)\MSCMDLIN.ASM

$(OBJ)\SUBS.OBJ : SUBS.ASM MACROS
  ML $(FLAGS) $(SRC)\SUBS.ASM

$(OBJ)\CFGPROC.OBJ : CFGPROC.ASM MACROS IO_STRUC
  ML $(FLAGS) $(SRC)\CFGPROC.ASM

$(OBJ)\INIPROC.OBJ : INIPROC.ASM MACROS IO_STRUC
  ML $(FLAGS) $(SRC)\INIPROC.ASM

$(OBJ)\PERSONAL.OBJ : PERSONAL.ASM MACROS
  ML $(FLAGS) $(SRC)\PERSONAL.ASM

$(OBJ)\ERRORS.OBJ : ERRORS.ASM MACROS SYMBOLS SEGMENTS MODULES GROUPS IO_STRUC RESSTRUC SYMCMACS
  ML $(FLAGS) /Dfg_japan=0 $(SRC)\ERRORS.ASM

$(OBJ)\PASS1.OBJ : PASS1.ASM MACROS IO_STRUC RELEASE WIN32DEF EXES
  ML $(FLAGS) $(SRC)\PASS1.ASM

$(OBJ)\OBJ_MOD.OBJ : OBJ_MOD.ASM MACROS IO_STRUC SECTS MODULES CDDATA FIXTEMPS TDBG
  ML $(FLAGS) $(SRC)\OBJ_MOD.ASM

$(OBJ)\THEADR.OBJ : THEADR.ASM MACROS
  ML $(FLAGS) $(SRC)\THEADR.ASM

$(OBJ)\COMENT.OBJ : COMENT.ASM MACROS SYMBOLS SEGMSYMS EXES MODULES IO_STRUC TDBG TDTYPES
  ML $(FLAGS) $(SRC)\COMENT.ASM

$(OBJ)\LNAMES.OBJ : LNAMES.ASM MACROS
  ML $(FLAGS) $(SRC)\LNAMES.ASM

$(OBJ)\SEGDEF.OBJ : SEGDEF.ASM MACROS SEGMENTS
  ML $(FLAGS) $(SRC)\SEGDEF.ASM

$(OBJ)\GRPDEF.OBJ : GRPDEF.ASM MACROS SEGMENTS GROUPS CDDATA
  ML $(FLAGS) $(SRC)\GRPDEF.ASM

$(OBJ)\EXTDEF.OBJ : EXTDEF.ASM MACROS SYMBOLS CDDATA
  ML $(FLAGS) $(SRC)\EXTDEF.ASM

$(OBJ)\PUBDEF.OBJ : PUBDEF.ASM MACROS SEGMENTS SYMBOLS CDDATA
  ML $(FLAGS) $(SRC)\PUBDEF.ASM

$(OBJ)\COMDEF.OBJ : COMDEF.ASM MACROS SEGMENTS SYMBOLS CDDATA
  ML $(FLAGS) $(SRC)\COMDEF.ASM

$(OBJ)\COMDAT.OBJ : COMDAT.ASM MACROS SEGMENTS SYMBOLS CDDATA
  ML $(FLAGS) $(SRC)\COMDAT.ASM

$(OBJ)\LEDATA.OBJ : LEDATA.ASM MACROS SEGMENTS SYMBOLS CDDATA IO_STRUC
  ML $(FLAGS) $(SRC)\LEDATA.ASM

$(OBJ)\FIXUPP.OBJ : FIXUPP.ASM MACROS SEGMENTS SYMBOLS GROUPS FIXTEMPS CDDATA
  ML $(FLAGS) $(SRC)\FIXUPP.ASM

$(OBJ)\LINNUM.OBJ : LINNUM.ASM MACROS SYMBOLS MODULES IO_STRUC
  ML $(FLAGS) $(SRC)\LINNUM.ASM

$(OBJ)\CEXTDEF.OBJ : CEXTDEF.ASM MACROS SYMBOLS CDDATA
  ML $(FLAGS) $(SRC)\CEXTDEF.ASM

$(OBJ)\MODEND.OBJ : MODEND.ASM MACROS SEGMENTS SYMBOLS MODULES FIXTEMPS
  ML $(FLAGS) $(SRC)\MODEND.ASM

$(OBJ)\RECORDS.OBJ : RECORDS.ASM MACROS IO_STRUC
  ML $(FLAGS) $(SRC)\RECORDS.ASM

$(OBJ)\NEWLIB.OBJ : NEWLIB.ASM MACROS IO_STRUC SYMBOLS LIBRARY WIN32DEF
  ML $(FLAGS) $(SRC)\NEWLIB.ASM

$(OBJ)\ALIAS.OBJ : ALIAS.ASM MACROS SYMBOLS
  ML $(FLAGS) $(SRC)\ALIAS.ASM

$(OBJ)\STRTMAP.OBJ : STRTMAP.ASM MACROS EXES
  ML $(FLAGS) $(SRC)\STRTMAP.ASM

$(OBJ)\MIDDLE.OBJ : MIDDLE.ASM MACROS RELEASE SYMBOLS SEGMENTS CDDATA MODULES EXES SEGMSYMS WIN32DEF WINMACS
  ML $(FLAGS) $(SRC)\MIDDLE.ASM

$(OBJ)\STACK.OBJ : STACK.ASM MACROS SYMBOLS SEGMENTS GROUPS MODULES CLASSES EXES
  ML $(FLAGS) $(SRC)\STACK.ASM

$(OBJ)\INITMAP.OBJ : INITMAP.ASM MACROS WIN32DEF
  ML $(FLAGS) $(SRC)\INITMAP.ASM

$(OBJ)\COMDATS.OBJ : COMDATS.ASM MACROS SEGMENTS SYMBOLS MODULES CDDATA SEGMSYMS
  ML $(FLAGS) $(SRC)\COMDATS.ASM

$(OBJ)\COMMUNAL.OBJ : COMMUNAL.ASM MACROS SEGMENTS SYMBOLS MODULES EXES
  ML $(FLAGS) $(SRC)\COMMUNAL.ASM

$(OBJ)\ORDER.OBJ : ORDER.ASM MACROS SEGMENTS GROUPS CLASSES
  ML $(FLAGS) $(SRC)\ORDER.ASM

$(OBJ)\ALIGN.OBJ : ALIGN.ASM MACROS SEGMENTS GROUPS SECTIONS MODULES PE_STRUC
  ML $(FLAGS) $(SRC)\ALIGN.ASM

$(OBJ)\PACKSEGS.OBJ : PACKSEGS.ASM MACROS SEGMENTS GROUPS SEGMSYMS
  ML $(FLAGS) $(SRC)\PACKSEGS.ASM

$(OBJ)\SEGMAP.OBJ : SEGMAP.ASM MACROS SECTIONS SEGMENTS GROUPS SYMBOLS MODULES CLASSES CDDATA PE_STRUC EXES
  ML $(FLAGS) $(SRC)\SEGMAP.ASM

$(OBJ)\MAPSUBS.OBJ : MAPSUBS.ASM MACROS SYMBOLS
  ML $(FLAGS) $(SRC)\MAPSUBS.ASM

$(OBJ)\DEFPUBS.OBJ : DEFPUBS.ASM MACROS SYMBOLS SEGMENTS GROUPS MODULES
  ML $(FLAGS) $(SRC)\DEFPUBS.ASM

$(OBJ)\QUICK.OBJ : QUICK.ASM MACROS SYMBOLS MODULES SEGMSYMS RESSTRUC
  ML $(FLAGS) $(SRC)\QUICK.ASM

$(OBJ)\SYMMAP.OBJ : SYMMAP.ASM MACROS SYMBOLS SEGMSYMS SECTIONS PE_STRUC EXES
  ML $(FLAGS) $(SRC)\SYMMAP.ASM

$(OBJ)\PASS2.OBJ : PASS2.ASM MACROS SEGMENTS GROUPS SYMBOLS EXES SEGMSYMS
  ML $(FLAGS) $(SRC)\PASS2.ASM

$(OBJ)\FIXUPP2.OBJ : FIXUPP2.ASM MACROS SYMBOLS SEGMENTS GROUPS SECTS SEGMSYMS SECTIONS EXES RELOCSS PE_STRUC RELEASE FIXTEMPS
  ML $(FLAGS) $(SRC)\FIXUPP2.ASM

$(OBJ)\EXE.OBJ : EXE.ASM MACROS SEGMENTS
  ML $(FLAGS) $(SRC)\EXE.ASM

$(OBJ)\LIDATA.OBJ : LIDATA.ASM MACROS SEGMENTS
  ML $(FLAGS) $(SRC)\LIDATA.ASM

$(OBJ)\LIBASE.OBJ : LIBASE.ASM MACROS SEGMENTS
  ML $(FLAGS) $(SRC)\LIBASE.ASM

$(OBJ)\XRFMAP.OBJ : XRFMAP.ASM MACROS SYMBOLS MODULES
  ML $(FLAGS) $(SRC)\XRFMAP.ASM

$(OBJ)\LINMAP.OBJ : LINMAP.ASM MACROS SEGMENTS MODULES
  ML $(FLAGS) $(SRC)\LINMAP.ASM

$(OBJ)\LINSYM.OBJ : LINSYM.ASM MACROS CDDATA SEGMENTS MODULES SYMBOLS IO_STRUC
  ML $(FLAGS) $(SRC)\LINSYM.ASM

$(OBJ)\PE_SECT.OBJ : PE_SECT.ASM MACROS SEGMENTS SECTIONS PE_STRUC EXES SYMBOLS IO_STRUC SEGMSYMS
  ML $(FLAGS) $(SRC)\PE_SECT.ASM

$(OBJ)\FORREF.OBJ : FORREF.ASM MACROS SEGMENTS IO_STRUC
  ML $(FLAGS) $(SRC)\FORREF.ASM

$(OBJ)\NBKPAT.OBJ : NBKPAT.ASM MACROS CDDATA
  ML $(FLAGS) $(SRC)\NBKPAT.ASM

$(OBJ)\FORREF2.OBJ : FORREF2.ASM MACROS SEGMENTS
  ML $(FLAGS) $(SRC)\FORREF2.ASM

$(OBJ)\REXEPACK.OBJ : REXEPACK.ASM MACROS SEGMENTS
  ML $(FLAGS) $(SRC)\REXEPACK.ASM

$(OBJ)\EXEPACK.OBJ : EXEPACK.ASM MACROS SEGMENTS SEGMSYMS
  ML $(FLAGS) $(SRC)\EXEPACK.ASM

$(OBJ)\UNEXE2.OBJ : UNEXE2.ASM MACROS
  ML $(FLAGS) $(SRC)\UNEXE2.ASM

$(OBJ)\C32.OBJ : C32.ASM MACROS SLR32 SEGMENTS SEGMSYMS
  ML $(FLAGS) $(SRC)\C32.ASM

$(OBJ)\CSUBS.OBJ : CSUBS.ASM MACROS SLR32
  ML $(FLAGS) $(SRC)\CSUBS.ASM

$(OBJ)\C32QUIK.OBJ : C32QUIK.ASM MACROS SLR32
  ML $(FLAGS) $(SRC)\C32QUIK.ASM

$(OBJ)\QUIKRELO.OBJ : QUIKRELO.ASM MACROS RELOCSS SEGMSYMS
  ML $(FLAGS) $(SRC)\QUIKRELO.ASM

$(OBJ)\C32MOVES.OBJ : C32MOVES.ASM MACROS SECTS SLR32
  ML $(FLAGS) $(SRC)\C32MOVES.ASM

$(OBJ)\cmdsubsc.obj : cmdsubsc.c $(HEADERS)
	dmc -c cmdsubsc -NTFILEPARSE_TEXT $(CFLAGS) -o$(OBJ)\cmdsubsc.obj

$(OBJ)\fixupp2c.obj : fixupp2c.c $(HEADERS)
	dmc -c fixupp2c -NTPASS2_TEXT $(CFLAGS) -o$(OBJ)\fixupp2c.obj

$(OBJ)\lnkinitc.obj : lnkinitc.c $(HEADERS)
	dmc -c lnkinitc -NTSTARTUP_TEXT $(CFLAGS) -o$(OBJ)\lnkinitc.obj

$(OBJ)\macrosc.obj : macrosc.c $(HEADERS)
	dmc -c macrosc -NTPASS1_TEXT $(CFLAGS) -o$(OBJ)\macrosc.obj

$(OBJ)\mscmdlinc.obj : mscmdlinc.c $(HEADERS)
	dmc -c mscmdlinc -NTFILEPARSE_TEXT $(CFLAGS) -o$(OBJ)\mscmdlinc.obj

$(OBJ)\newlibc.obj : newlibc.c $(HEADERS)
	dmc -c newlibc -NTPASS1_TEXT $(CFLAGS) -o$(OBJ)\newlibc.obj

$(OBJ)\optlnkc.obj : optlnkc.c $(HEADERS)
	dmc -c optlnkc -NTROOT_TEXT $(CFLAGS) -o$(OBJ)\optlnkc.obj

$(OBJ)\pass2c.obj : pass2c.c $(HEADERS)
	dmc -c pass2c -NTPASS2_TEXT $(CFLAGS) -o$(OBJ)\pass2c.obj

$(OBJ)\recordsc.obj : recordsc.c $(HEADERS)
	dmc -c recordsc -NTPASS1_TEXT $(CFLAGS) -o$(OBJ)\recordsc.obj


