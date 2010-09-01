		TITLE	CVSYMBOL - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS

if	fg_cvpack

		INCLUDE	CVTYPES

		PUBLIC	PROCESS_CV_SYMBOLS,GET_NAME_HASH32,SKIP_LEAF_SICXAX,OPTI_HASH32,OPTI_HASH32_CASE,GET_NAME_HASH32_CASE


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE

		EXTERNDEF	EXETABLE:DWORD,SYMBOL_LENGTH:DWORD,CV_REFSYM_CNT:DWORD,CURNMOD_GINDEX:DWORD,SSYM_HASH:DWORD
		EXTERNDEF	SSYM_HASH_LOG:DWORD,FIX2_SM_LEN:DWORD,BYTES_SO_FAR:DWORD,LAST_PEOBJECT_NUMBER:DWORD
		EXTERNDEF	CURNMOD_NUMBER:DWORD,FIRST_GSYM_GINDEX:DWORD,LAST_SSYM_GINDEX:DWORD,FIRST_SSYM_GINDEX:DWORD
		EXTERNDEF	LAST_GSYM_GINDEX:DWORD,CV_SEGMENT_COUNT:DWORD

		EXTERNDEF	CV_LTYPE_GARRAY:STD_PTR_S,SEGMENT_GARRAY:STD_PTR_S,CV_SSEARCH_GARRAY:STD_PTR_S
		EXTERNDEF	CV_SSYM_GARRAY:STD_PTR_S,CV_GSYM_GARRAY:STD_PTR_S,CV_ASYM_STRUCTURE:SEQ_STRUCT


		.CODE	CVPACK_TEXT

		externdef	_install_gsym:proc
		externdef	_install_gsym_ref:proc
		externdef	_install_globalsym:proc
		externdef	_get_name_hash32:proc
		externdef	_opti_hash32:proc
		EXTERNDEF	ALLOC_LOCAL:PROC,RELEASE_EXETABLE_ALL:PROC,RELEASE_BLOCK:PROC,ERR_RET:PROC,WARN_RET:PROC
		EXTERNDEF	_err_abort:proc,RELEASE_BLOCK:PROC,GET_NEW_LOG_BLK:PROC,INSTALL_GLOBALSYM:PROC
		EXTERNDEF	STORE_EAXECX_EDX_SEQ:PROC,INSTALL_STATICSYM:PROC,STORE_EAXECX_EDXEBX_RANDOM:PROC
		EXTERNDEF	READ_EAXECX_EDXEBX_RANDOM:PROC,FLUSH_EAX_TO_FINAL:PROC,WRITE_CV_INDEX:PROC
		EXTERNDEF	CONVERT_CV_LTYPE_GTYPE_A:PROC,CV_SSYM_POOL_GET:PROC

		EXTERNDEF	CVP_CORRUPT_ERR:ABS,CVP_SYMDEL_ERR:ABS,CVP_BAD_LEAF_ERR:ABS,CVP_SCOPE_ERR:ABS,CVP_NEST_SEG_ERR:ABS
		EXTERNDEF	CVP_BLOCK_WO_PARENT_ERR:ABS,CVP_SSEARCH_ERR:ABS,CVP_SYMBOLS_64K_ERR:ABS


CVSYMBOLS_VARS		STRUC

CV_SCOPE_NEST_TABLE_BP	DB	256 DUP(?)	;SCOPES CAN NEST 256 LEVELS

CV_IREF_BP		CV_IREF_STRUCT	<>

CV_DELETE_FLAG_BP	DB	?
			DB	?
			DW	?

CV_SYM_RELEASE_BP	DB	?
			DB	?
			DW	?

CV_SCOPE_LEVEL_BP	DD	?
CV_BYTES_LEFT_BP	DD	?
CV_THIS_BLOCK_BP	DD	?
CV_THIS_BLOCK_LIMIT_BP	DD	?
CV_NEXT_BLOCK_BP	DD	?
CV_BYTES_PTR_BP		DD	?
CV_ID_LB_BP		DD	?
CV_ID_LIMIT_BP		DD	?
CV_SSEARCH_TBL_BP	DD	?
CV_SSEARCH_BLOCK_BP	DD	?
CV_SSEARCH_CNT_BP	DD	?
CV_PPARENT_BP		DD	?
CV_PPARENT_SEGMENT_BP	DD	?
CV_NEXT_SSEARCH_BP	DD	?
CV_TEMP_DWORD_BP	DD	?
CV_GSYM_START_BP	DD	?

CVSYMBOLS_VARS		ENDS


FIX	MACRO	X

X	EQU	([EBP-SIZE CVSYMBOLS_VARS].(X&_BP))

	ENDM


FIX	CV_SCOPE_NEST_TABLE
FIX	CV_SCOPE_LEVEL
FIX	CV_DELETE_FLAG
FIX	CV_SYM_RELEASE
FIX	CV_BYTES_LEFT
FIX	CV_THIS_BLOCK
FIX	CV_THIS_BLOCK_LIMIT
FIX	CV_NEXT_BLOCK
FIX	CV_BYTES_PTR
FIX	CV_ID_LB
FIX	CV_ID_LIMIT
FIX	CV_SSEARCH_TBL
FIX	CV_SSEARCH_BLOCK
FIX	CV_SSEARCH_CNT
FIX	CV_PPARENT
FIX	CV_PPARENT_SEGMENT
FIX	CV_NEXT_SSEARCH
FIX	CV_TEMP_DWORD
FIX	CV_IREF
FIX	CV_GSYM_START


CV_SSEARCH_PTRS	EQU	DWORD PTR CV_SCOPE_NEST_TABLE


GET_CV_ASYM_OFFSET	MACRO
		;
		;
		;
		MOV	EAX,CV_ASYM_STRUCTURE._SEQ_PTR

		ENDM


PROCESS_CV_SYMBOLS	PROC
		;
		;CONVERT CV4 SYMBOLS SEGMENT INTO ALIGNSYM AND GLOBALSYM
		;
		PUSHM	EBP,EDI,ESI,EBX

		MOV	EBP,ESP
		SUB	ESP,SIZE CVSYMBOLS_VARS
		ASSUME	EBP:PTR CVSYMBOLS_VARS

		XOR	EAX,EAX

		MOV	CV_SCOPE_LEVEL,EAX
		MOV	CV_BYTES_PTR,EAX

		MOV	DPTR CV_DELETE_FLAG,EAX
		MOV	DPTR CV_SYM_RELEASE,EAX

		MOV	CV_SSEARCH_CNT,EAX
		MOV	CV_SSEARCH_TBL,EAX

		MOV	EAX,LAST_GSYM_GINDEX

		MOV	CV_GSYM_START,EAX
		CALL	INIT_CV_READER			;ESI IS POINTER
		;
		;FIRST PASS
		;
		;	1.  CHANGE SYMBOL IDs TO INTERNAL FORMAT
		;	2.  DETERMINE SYMBOLS TO DELETE BASED ON UNUSED COMDATS
		;	3.  COUNT NUMBER OF S_SSEARCH SYMBOLS WE WILL NEED
		;	4.  MOVE GDATAxx, AND UNSCOPED UDT AND CONSTANT SYMBOLS TO GLOBALSYM TABLE
		;
		CALL	GET_CV_DWORD

		DEC	EAX
		JNZ	L9$

		CALL	GET_NEW_LOG_BLK

		MOV	CV_SSEARCH_TBL,EAX
		MOV	EDI,EAX

		XOR	EAX,EAX
		MOV	ECX,CV_SEGMENT_COUNT
if	fg_pe
		BITT	OUTPUT_PE
		JZ	L05$

		MOV	ECX,LAST_PEOBJECT_NUMBER
L05$:
endif
		SHRI	ECX,5			;1 BIT PER SEGMENT

		INC	ECX

		REP	STOSD

		LEA	EDI,CV_ASYM_STRUCTURE
		MOV	ECX,SIZE SEQ_STRUCT/4+ 1K*1K/PAGE_SIZE/4

		REP	STOSD

		JMP	L2$

L1$:
		CALL	GET_CV_SYMBOL		;GET PTR TO NEXT SYMBOL, SYMBOL ID ADJUSTED

		CALL	PROCSYM_PASS1[EBX*4]	;PROCESS BASED ON SYMBOL ID

		CALL	PUT_CV_SYMBOL		;STORE RESULT IF NOT DELETED

L2$:
		MOV	EAX,CV_BYTES_LEFT

		OR	EAX,EAX
		JNZ	L1$
		;
		;MIDDLE
		;
		;	0.  OUTPUT 00000001
		;	1.  OUTPUT S_SEARCH SYMBOLS
		;
		MOV	EAX,CV_SSEARCH_TBL
		CALL	RELEASE_BLOCK

		MOV	EAX,OFF ZERO_ONE
		MOV	ECX,4

		LEA	EDX,CV_ASYM_STRUCTURE
		CALL	STORE_EAXECX_EDX_SEQ

		CALL	DO_SSEARCH_SYMS

		;
		;SECOND PASS
		;
		;	1.  IGNORE DELETED SYMBOLS
		;       2.  CONVERT TYPES TO GLOBAL INDEXES -
		;	3.  LINK SCOPES PER LOGICAL SEGMENT
		;	4.  CREATE STATICSYM ENTRIES FOR LPROCs AND LDATAs
		;	5.  CREATE GLOBALSYM PROCREF ENTRIES FOR GPROCs
		;	6.  CHANGE SYMBOL IDs TO EXTERNAL FORMAT
		;	7.  COPY SYMBOLS TO REAL OUTPUT
		;	8.  ADD S_ALIGN SYMBOLS AS NECESSARY	*** NO! ***
		;

		MOV	CV_SYM_RELEASE,-1

		CALL	INIT_CV_READER

		CALL	GET_CV_DWORD		;SKIP SIGNATURE

		XOR	EAX,EAX
		MOV	CV_BYTES_PTR,ESI

		MOV	CV_PPARENT,EAX
		JMP	L7$

L9$:
		CALL	RELEASE_EXETABLE_ALL
		JMP	L99$

L5$:
		CALL	GET_CV_SYMBOL2		;GET SYMBOL, PASS2

		CALL	PROCSYM_PASS2[EBX*4]	;PROCESS BASED ON SYMBOL ID

		CALL	PUT_CV_SYMBOL2		;OUTPUT IF NOT DELETED

L7$:
		MOV	EAX,CV_BYTES_LEFT

		OR	EAX,EAX
		JNZ	L5$

		CALL	ADJUST_CV_PTR		;RELEASE CURRENT (LAST) BLOCK
		;
		;CLEAN-UP
		;
		;	1.  OUTPUT ALIGNSYM SECTION AND CV_INDEX IF NOT ZERO LENGTH
		;	2.  FIX TYPES ON ANY GLOBALSYM ENTRIES WE MADE
		;
		CALL	CV_SYMBOL_CLEANUP
L99$:
		MOV	ESP,EBP

		POPM	EBX,ESI,EDI,EBP

		RET

PROCESS_CV_SYMBOLS	ENDP


PP1_PASS_THRU	PROC	NEAR
		;
		;KEEP SYMBOL NO MATTER WHAT
		;
		RET

PP1_PASS_THRU	ENDP


PP1_LDATA16	PROC	NEAR
		;
		;
		;
		ASSUME	ESI:PTR CV_LDATA16_STRUCT

		MOV	CL,CV_DELETE_FLAG
		MOV	AL,BPTR [ESI]._SEGMENT+1	;SEGMENT IS HIGH WORD

		OR	CL,CL
		JNZ	PP1_DELETE

		AND	AL,7FH

		MOV	BPTR [ESI]._SEGMENT+1,AL

		RET

		ASSUME	ESI:NOTHING

PP1_LDATA16	ENDP


PP1_PASS_ND	PROC	NEAR
		;
		;KEEP SYMBOL IF NOT DELETING CURRENT SCOPE
		;
		MOV	AL,CV_DELETE_FLAG
PP1_PASS_ND_AL::
		OR	AL,AL
		JNZ	PP1_DELETE

		RET

PP1_PASS_ND	ENDP


PP1_CONSTANT	PROC	NEAR
		;
		;DELETE IF DELETING CURRENT SCOPE
		;GLOBALIZE IF NEST LEVEL == 0
		;
		ASSUME	ESI:PTR CV_CONST_STRUCT

		MOV	ECX,CV_SCOPE_LEVEL
		MOV	AL,CV_DELETE_FLAG

		OR	ECX,ECX
		JNZ	PP1_PASS_ND_AL
		;
		;STORE IN COMPACTED GLOBAL TABLE
		;
		LEA	ECX,[ESI]._VALUE
		CALL	SKIP_LEAF_ECX

		JMP	INSTALL_GSYM		;PUT IN GLOBAL SYMBOL TABLE, ESI IS SYMBOL, ECX IS NAME PORTION

		ASSUME	ESI:NOTHING

PP1_CONSTANT	ENDP


PP1_UDT		PROC	NEAR
		;
		;DELETE IF DELETING CURRENT SCOPE
		;GLOBALIZE IF NEST LEVEL == 0
		;
		ASSUME	ESI:PTR CV_UDT_STRUCT

		MOV	ECX,CV_SCOPE_LEVEL
		MOV	AL,CV_DELETE_FLAG

		OR	ECX,ECX
		JNZ	PP1_PASS_ND_AL
		;
		;STORE IN COMPACTED GLOBAL TABLE
		;
		LEA	ECX,[ESI]._NAME
		JMP	INSTALL_GSYM		;PUT IN GLOBAL SYMBOL TABLE, ESI IS SYMBOL, ECX IS NAME PORTION

		ASSUME	ESI:NOTHING

PP1_UDT		ENDP


PP1_S_END	PROC	NEAR
		;
		;END OF A CODE BLOCK
		;
		ASSUME	ESI:PTR CV_SYMBOL_STRUCT

		MOV	ECX,CV_SCOPE_LEVEL
		MOV	AL,CV_DELETE_FLAG

		SUB	ECX,1
		JC	PP1_W_DELETE

		MOV	CV_SCOPE_LEVEL,ECX
		OR	AL,AL			;THIS LEVEL BEING DELETED?

		MOV	AL,CV_SCOPE_NEST_TABLE[ECX]
		JZ	L2$

		MOV	BL,I_S_DELETE		;MARK SYMBOL DELETED

		MOV	BPTR [ESI]._ID,BL
L2$:
		;
		;DEFINE DELETE FLAG BASED ON PARENT
		;
		MOV	CV_DELETE_FLAG,AL

		RET

PP1_S_END	ENDP


PP1_W_DELETE	PROC	NEAR
		;
		;
		;
		MOV	AL,CVP_SYMDEL_ERR
		CALL	WARN_RET

PP1_W_DELETE	ENDP


PP1_DELETE	PROC	NEAR

		MOV	BL,I_S_DELETE	;MARK SYMBOL DELETED

		MOV	BPTR [ESI]._ID,BL

		RET

PP1_DELETE	ENDP


PP1_S_GDATA16	PROC	NEAR
		;
		;DELETE IF NEEDED
		;
		ASSUME	ESI:PTR CV_GDATA16_STRUCT

		MOV	CL,CV_DELETE_FLAG
		MOV	AL,BPTR [ESI]._SEGMENT+1

		OR	CL,CL
		JNZ	PP1_DELETE

		AND	AL,7FH
		LEA	ECX,[ESI]._NAME

		;
		;STORE IN COMPACTED GLOBAL TABLE
		;
		MOV	BPTR [ESI]._SEGMENT+1,AL
		JMP	INSTALL_GSYM		;PUT IN GLOBAL SYMBOL TABLE, ESI IS SYMBOL, ECX IS NAME PORTION
						;MARK DELETE IF INSTALL WORKS...
		ASSUME	ESI:NOTHING

PP1_S_GDATA16	ENDP


PP1_PROC16	PROC	NEAR
		;
		;PROCEDURE START...  FIRST DETERMINE IF THIS CODESEG IS MINE
		;
		ASSUME	ESI:PTR CV_LPROC16_STRUCT

		MOV	CL,BPTR [ESI]._SEGMENT

		MOV	CH,BPTR [ESI]._SEGMENT+1
PP1_PROC16_1::
		CALL	IS_MY_CODESEG		;IS THIS IN MY MODULE HEADER?  ALSO, COUNT SEG REFS

		JZ	NEST_SCOPE_ON

		CALL	NEST_SCOPE_OFF

		JMP	PP1_DELETE

		ASSUME	ESI:NOTHING

PP1_PROC16	ENDP


NEST_SCOPE_OFF:
		MOV	AL,-1
		JMP	NEST_SCOPE_1


NEST_SCOPE_ON	PROC	NEAR
		;
		;
		;
		MOV	AL,0
NEST_SCOPE_1::
		MOV	ECX,CV_SCOPE_LEVEL
		MOV	AH,CV_DELETE_FLAG

		MOV	CV_DELETE_FLAG,AL

		MOV	CV_SCOPE_NEST_TABLE[ECX],AH
		INC	CL			;TO DETECT 256 OVEFLOW...

		MOV	CV_SCOPE_LEVEL,ECX
		JZ	L9$

		RET

L9$:
		MOV	AL,CVP_SCOPE_ERR
		push	EAX
		call	_err_abort

NEST_SCOPE_ON	ENDP


PP1_THUNK16	PROC	NEAR
		;
		;THUNK...  FIRST DETERMINE IF THIS CODESEG IS MINE
		;
		ASSUME	ESI:PTR CV_THUNK16_STRUCT

		MOV	CL,BPTR [ESI]._SEGMENT

		MOV	CH,BPTR [ESI]._SEGMENT+1
		JMP	PP1_PROC16_1

		ASSUME	ESI:NOTHING

PP1_THUNK16	ENDP


PP1_BLOCK16	PROC	NEAR
		;
		;
		;
		ASSUME	ESI:PTR CV_BLOCK16_STRUCT

		MOV	CL,BPTR [ESI]._SEGMENT

		MOV	CH,BPTR [ESI]._SEGMENT+1
		JMP	PP1_PROC16_1

		ASSUME	ESI:NOTHING

PP1_BLOCK16	ENDP


PP1_LABEL16	PROC	NEAR
		;
		;
		;
		ASSUME	ESI:PTR CV_LABEL16_STRUCT

		MOV	AL,BPTR [ESI]._SEGMENT+1

		TEST	AL,80H
		JNZ	PP1_DELETE

		RET

		ASSUME	ESI:NOTHING

PP1_LABEL16	ENDP


PP1_CEXMODEL16	PROC	NEAR
		;
		;
		;
		AND	BPTR [ESI].CV_CEXMODEL16_STRUCT._SEGMENT+1,7FH

		RET

PP1_CEXMODEL16	ENDP


PP1_VFTPATH16	PROC	NEAR
		;
		;
		;
		AND	BPTR [ESI].CV_VFTPATH16_STRUCT._SEGMENT+1,7FH

		RET

PP1_VFTPATH16	ENDP


PP1_LDATA32	PROC	NEAR
		;
		;
		;
		ASSUME	ESI:PTR CV_LDATA32_STRUCT

		MOV	CL,CV_DELETE_FLAG
		MOV	AL,BPTR [ESI]._SEGMENT+1

		OR	CL,CL
		JNZ	PP1_DELETE

		AND	AL,7FH

		MOV	BPTR [ESI]._SEGMENT+1,AL

		RET

		ASSUME	ESI:NOTHING

PP1_LDATA32	ENDP


PP1_S_GDATA32	PROC	NEAR
		;
		;DELETE IF NEEDED
		;
		ASSUME	ESI:PTR CV_GDATA32_STRUCT

		MOV	CL,CV_DELETE_FLAG
		MOV	AL,BPTR [ESI]._SEGMENT+1

		OR	CL,CL
		JNZ	PP1_DELETE

		AND	AL,7FH
		LEA	ECX,[ESI]._NAME

		;
		;STORE IN COMPACTED GLOBAL TABLE
		;
		MOV	BPTR [ESI]._SEGMENT+1,AL
		JMP	INSTALL_GSYM		;PUT IN GLOBAL SYMBOL TABLE, ESI IS SYMBOL, ECX IS NAME PORTION
						;MARK DELETE IF INSTALL WORKS...
		ASSUME	ESI:NOTHING

PP1_S_GDATA32	ENDP


PP1_PROC32	PROC	NEAR
		;
		;PROCEDURE START...  FIRST DETERMINE IF THIS CODESEG IS MINE
		;
		ASSUME	ESI:PTR CV_GPROC32_STRUCT

		MOV	CL,BPTR [ESI]._SEGMENT

		MOV	CH,BPTR [ESI]._SEGMENT+1
PP1_PROC32_1::
		CALL	IS_MY_CODESEG		;IS THIS IN MY MODULE HEADER?  ALSO, COUNT SEG REFS
		JZ	NEST_SCOPE_ON

		CALL	NEST_SCOPE_OFF

		JMP	PP1_DELETE

		ASSUME	ESI:NOTHING

PP1_PROC32	ENDP


PP1_THUNK32	PROC	NEAR
		;
		;THUNK...  FIRST DETERMINE IF THIS CODESEG IS MINE
		;
		ASSUME	ESI:PTR CV_THUNK32_STRUCT

		MOV	CL,BPTR [ESI]._SEGMENT

		MOV	CH,BPTR [ESI]._SEGMENT+1
		JMP	PP1_PROC32_1

PP1_THUNK32	ENDP


PP1_BLOCK32	PROC	NEAR
		;
		;
		;
		ASSUME	ESI:PTR CV_BLOCK32_STRUCT

		MOV	CL,BPTR [ESI]._SEGMENT

		MOV	CH,BPTR [ESI]._SEGMENT+1
		JMP	PP1_PROC32_1

PP1_BLOCK32	ENDP

		ASSUME	ESI:NOTHING

PP1_LABEL32	PROC	NEAR
		;
		;
		;
		MOV	AL,BPTR [ESI].CV_LABEL32_STRUCT._SEGMENT+1

		TEST	AL,80H
		JNZ	PP1_DELETE

		RET

PP1_LABEL32	ENDP


PP1_CEXMODEL32	PROC	NEAR
		;
		;
		;
		AND	BPTR [ESI].CV_CEXMODEL32_STRUCT._SEGMENT+1,7FH

		RET

PP1_CEXMODEL32	ENDP


PP1_VFTPATH32	PROC	NEAR
		;
		;
		;
		AND	BPTR [ESI].CV_VFTPATH32_STRUCT._SEGMENT+1,7FH

		RET

PP1_VFTPATH32	ENDP


INIT_CV_READER	PROC	NEAR	PRIVATE
		;
		;SET UP STUFF FOR SCANNING THROUGH A CODEVIEW SEGMENT
		;
		MOV	EAX,FIX2_SM_LEN
		XOR	ECX,ECX

		MOV	CV_BYTES_LEFT,EAX
		MOV	EAX,OFF EXETABLE

		MOV	CV_THIS_BLOCK,ECX
		MOV	CV_NEXT_BLOCK,EAX

;		CALL	ADJUST_CV_PTR
;		RET

INIT_CV_READER	ENDP


ADJUST_CV_PTR	PROC	NEAR	PRIVATE
		;
		;
		;
		MOV	EDX,CV_NEXT_BLOCK		;EXETABLE
		MOV	AL,CV_SYM_RELEASE

		MOV	ECX,CV_THIS_BLOCK
		OR	AL,AL

		MOV	EAX,[EDX]			;HAVE NEXT BLOCK LOADED
		JZ	L2$

		TEST	ECX,ECX					;DOES THIS BLOCK EXIST?
		JZ	L1$

		MOV	EAX,ECX
		CALL	RELEASE_BLOCK
L1$:
		XOR	ECX,ECX
		MOV	EAX,[EDX]

		MOV	[EDX],ECX
L2$:
		ADD	EDX,4
		MOV	CV_THIS_BLOCK,EAX

		OR	EAX,EAX
		JZ	L9$

		MOV	ESI,EAX
		ADD	EAX,PAGE_SIZE

		MOV	CV_NEXT_BLOCK,EDX
		MOV	CV_THIS_BLOCK_LIMIT,EAX

		RET

L9$:
		STC

		RET

ADJUST_CV_PTR	ENDP


GET_CV_DWORD	PROC	NEAR	PRIVATE
		;
		;
		;
		ADD	ESI,4
		MOV	ECX,CV_BYTES_LEFT

		MOV	EAX,CV_THIS_BLOCK_LIMIT
		SUB	ECX,4

		CMP	EAX,ESI
		JB	L5$

		MOV	CV_BYTES_LEFT,ECX
		MOV	EAX,[ESI-4]

		RET

L5$:
		SUB	ESI,4
		CALL	GET_CV_WORD

		JC	L9$

		PUSH	EAX
		CALL	GET_CV_WORD

		POP	EDX
		JC	L9$

		SHL	EAX,16
		AND	EDX,0FFFFH

		OR	EAX,EDX

		RET

L9$:
		MOV	AL,-1

		RET

GET_CV_DWORD	ENDP


GET_CV_WORD	PROC	NEAR	PRIVATE
		;
		;
		;
		ADD	ESI,2
		MOV	EAX,CV_THIS_BLOCK_LIMIT

		CMP	EAX,ESI
		JB	L5$

		XOR	EAX,EAX
		MOV	ECX,CV_BYTES_LEFT

		MOV	AL,[ESI-2]
		SUB	ECX,2

		MOV	AH,[ESI-1]
		MOV	CV_BYTES_LEFT,ECX
L9$:
		RET

L5$:
		SUB	ESI,2
		CALL	GET_CV_BYTE

		JC	L9$

		PUSH	EAX
		CALL	GET_CV_BYTE

		MOV	AH,AL
		JC	L99$

		AND	EAX,0FFFFH
L99$:
		POP	EDX

		MOV	AL,DL

		RET

GET_CV_WORD	ENDP


GET_CV_BYTE	PROC	NEAR	PRIVATE
		;
		;
		;
L1$:
		INC	ESI
		MOV	ECX,CV_BYTES_LEFT

		MOV	EAX,CV_THIS_BLOCK_LIMIT
		DEC	ECX

		CMP	EAX,ESI
		JB	L5$

		MOV	CV_BYTES_LEFT,ECX
		MOV	AL,[ESI-1]

		RET

L5$:
		DEC	ESI
		CALL	ADJUST_CV_PTR

		JNC	L1$

		RET

GET_CV_BYTE	ENDP


MOVE_EAX_CV_BYTES	PROC	NEAR	PRIVATE
		;
		;NEED TO MOVE SMALLER OF EAX AND PAGE_SIZE-SI
		;
		MOV	ECX,CV_THIS_BLOCK_LIMIT
		MOV	EDX,CV_BYTES_LEFT

		SUB	ECX,ESI
		SUB	EDX,EAX

		MOV	CV_BYTES_LEFT,EDX
		JC	L9$
L1$:
		SUB	EAX,ECX
		JA	L5$

		ADD	ECX,EAX
		XOR	EAX,EAX
L5$:
		OPTI_MOVSB

		OR	EAX,EAX
		JNZ	L3$
L9$:
		RET

L3$:
		;
		;GET NEXT BLOCK
		;
		PUSH	EAX
		CALL	ADJUST_CV_PTR

		POP	EAX
		MOV	ECX,PAGE_SIZE

		JNC	L1$

		RET

MOVE_EAX_CV_BYTES	ENDP


GET_CV_SYMBOL	PROC	NEAR
		;
		;RETURN ESI PTR TO SYMBOL, EBX IS TYPE
		;
		XOR	EBX,EBX
		CALL	GET_CV_WORD		;LENGTH OF SYMBOL RECORD

		MOV	ECX,CV_THIS_BLOCK
		JC	L99$			;WORD WASN'T THERE

		CMP	EAX,2
		JB	L99$			;MUST HAVE ID

		ADD	ECX,2
		CMP	EAX,MAX_RECORD_LEN

		MOV	EDX,ESI
		JA	L99$			;TOO BIG

		CMP	EDX,ECX			;DOES THIS SYMBOL CROSS BLOCK BOUNDS?
		JB	L51$			;YES, IF ESI IS SMALLER THAN THIS_BLOCK + 2

		LEA	EDX,[ESI+EAX]
		MOV	ECX,CV_THIS_BLOCK_LIMIT

		CMP	EDX,ECX			;YES, IF ESI + LENGTH IS > THIS_BLOCK_LIMIT
		JA	L51$

		MOV	ECX,CV_BYTES_LEFT
		SUB	ESI,2

		ASSUME	ESI:PTR CV_SYMBOL_STRUCT

		SUB	ECX,EAX
		JC	L99$

		MOV	BH,BPTR [ESI]._ID+1
		MOV	CV_BYTES_LEFT,ECX
L2$:
		CMP	BH,1
		JB	L27$

		MOV	BL,BPTR [ESI]._ID
		JA	L25$
		;
		;BX IS 100 - 1FF
		;
		SUB	EBX,100H-10H

		MOV	BPTR [ESI]._ID,BL
		CMP	BL,1CH

		MOV	BPTR [ESI]._ID+1,BH
		JA	L28$
L23$:
		RET

L25$:
		SUB	EBX,200H-1DH

		MOV	BPTR [ESI]._ID,BL
		CMP	EBX,2BH

		MOV	BPTR [ESI]._ID+1,BH
		JAE	L28$

		RET

L27$:
		;
		;BX < 100H
		;
		MOV	BL,BPTR [ESI]._ID

		CMP	BL,0EH
		JA	L28$

		RET

L28$:
		XOR	EBX,EBX

		MOV	[ESI]._ID,BX

		RET

L99$:
		MOV	AL,CVP_CORRUPT_ERR
		CALL	ERR_RET

		STC

		RET

L51$:
		;
		;SYMBOL CROSSES BLOCK BOUNDS
		;
		PUSH	EDI
		MOV	EDI,OFF TEMP_RECORD+4

		PUSH	EAX
		CALL	GET_CV_BYTE

		MOV	DL,AL
		MOV	EAX,CV_THIS_BLOCK_LIMIT

		MOV	CV_ID_LB,ESI		;ESI POINTS 1 PAST ID LOW BYTE
		MOV	CV_ID_LIMIT,EAX

		PUSH	EDX
		CALL	GET_CV_BYTE

		POP	EDX

		MOV	DH,AL
		POP	EAX

		SHL	EDX,16

		OR	EDX,EAX
		SUB	EAX,2

		MOV	[EDI-4],EDX
		JBE	L6$

		CALL	MOVE_EAX_CV_BYTES
L6$:
		MOV	CV_BYTES_PTR,ESI
		MOV	ESI,OFF TEMP_RECORD

		MOV	BH,BPTR TEMP_RECORD.CV_SYMBOL_STRUCT._ID+1
		POP	EDI

		JMP	L2$

		ASSUME	ESI:NOTHING

GET_CV_SYMBOL	ENDP


PUT_CV_SYMBOL	PROC	NEAR
		;
		;UPDATE PTRS
		;
		ASSUME	ESI:PTR CV_SYMBOL_STRUCT

		XOR	ECX,ECX
		MOV	EAX,CV_BYTES_PTR

		MOV	CL,BPTR [ESI]._LENGTH
		TEST	EAX,EAX

		MOV	CH,BPTR [ESI]._LENGTH+1
		JNZ	L1$

		LEA	ESI,[ESI+ECX+2]

		RET

L1$:
		;
		;TRICKY TO HANDLE MODIFICATION...
		;
		MOV	EDI,CV_ID_LB			;ONE PAST ID LOW BYTE
		MOV	EAX,ECX

		DEC	EDI
		MOV	ECX,CV_ID_LIMIT

		LEA	ESI,[ESI]._ID
		SUB	ECX,EDI			;EAX IS BYTES TO MOVE, ECX IS MAX LEFT THIS BLOCK

		CMP	ECX,EAX
		JAE	L5$

		SUB	EAX,ECX

		OPTI_MOVSB

		MOV	EDI,CV_BYTES_PTR

		SUB	EDI,EAX
L5$:
		MOV	ECX,EAX

		OPTI_MOVSB

		MOV	ESI,CV_BYTES_PTR
		MOV	CV_BYTES_PTR,ECX

		RET

		ASSUME	ESI:NOTHING

PUT_CV_SYMBOL	ENDP


SKIP_LEAF_ECX	PROC	NEAR
		;
		;
		;
		MOV	AX,[ECX]
		ADD	ECX,2
SKIP_LEAF_AX:
		OR	AH,AH
		JS	L1$

		RET

L1$:
		AND	EAX,07FFFH

		CMP	EAX,10H
		JZ	L8$

		MOV	AL,LEAF_SIZE[EAX]
		JA	L9$

		ADD	ECX,EAX

		RET

L8$:
		MOV	AX,[ECX]
		ADD	ECX,2

		ADD	ECX,EAX

		RET

L9$:
		MOV	AL,CVP_BAD_LEAF_ERR
		push	EAX
		call	_err_abort

SKIP_LEAF_ECX	ENDP


SKIP_LEAF_SICXAX	PROC	NEAR
		;
		;CARRY CLEAR IF NO ERROR
		;
		AND	EAX,7FFFH

		CMP	EAX,10H
		JZ	L8$

		MOV	AL,LEAF_SIZE[EAX]
		JA	L9$

		ADD	ECX,EAX

		RET

L8$:
		MOV	AX,[ESI+ECX]
		ADD	ECX,2

		ADD	ECX,EAX

		RET

L9$:
		MOV	AL,CVP_BAD_LEAF_ERR
		push	EAX
		call	_err_abort

SKIP_LEAF_SICXAX	ENDP


IS_MY_CODESEG	PROC	NEAR
		;
		;CX IS SEGMENT
		;
		OR	CH,CH
		JS	L9$

		AND	ECX,0FFFFH
		JZ	L8$
		;
		;WE ARE KEEPING, HAVE WE REFERENCED THIS SEGMENT BEFORE?
		;
		MOV	EDX,CV_SEGMENT_COUNT
		MOV	EAX,ECX

		CMP	EDX,ECX
		JB	L8$

		SHR	EAX,3			;THAT BYTE
		MOV	CH,1

		MOV	EDX,CV_SSEARCH_TBL
		AND	CL,7

		SHL	CH,CL

		MOV	CL,[EDX+EAX]
		PUSH	EBX

		TEST	CL,CH
		JNZ	L5$

		MOV	EBX,CV_SSEARCH_CNT
		OR	CL,CH

		INC	EBX
		MOV	[EDX+EAX],CL

		MOV	CV_SSEARCH_CNT,EBX
L5$:
		POP	EBX
		CMP	AL,AL

		RET

L8$:
		OR	AL,-1
L9$:
		RET

IS_MY_CODESEG	ENDP


INSTALL_GSYM	PROC	NEAR
		push	ESI
		push	ECX
		call	_install_gsym
		add	ESP,8
		ret

		;
		;INSTALL GDATA16, GDATA32, CONSTANT, AND UDT IN GLOBALSYM
		;
		MOV	EAX,ECX
		PUSH	ECX

		push	EAX
		call	_get_name_hash32
		add	ESP,4

		POP	ECX

		push	ESI
		push	ECX
		push	EAX
		call	_install_globalsym
		add	ESP,12
		ret
		;JMP	INSTALL_GLOBALSYM	;STICK IN GLOBALSYM TABLE

INSTALL_GSYM	ENDP


INSTALL_GSYM_REF	PROC	NEAR
		push	ESI
		push	EDX
		push	ECX
		push	EAX
		lea	EAX,CV_SCOPE_NEST_TABLE
		push	EAX
		call	_install_gsym_ref
		add	ESP,5*4
		ret

		;
		;INSTALL A REFERENCE IN GLOBALSYM
		;
		;ESI IS NAME
		;EDX IS INTERNAL REFERENCE TYPE
		;ECX IS SEGMENT
		;EAX IS OFFSET
		;
		SHL	EDX,16
		MOV	CV_IREF._OFFSET,EAX

		OR	EDX,SIZE CV_IREF_STRUCT-2

		mov	EAX,dword ptr CV_ASYM_STRUCTURE

		MOV	DPTR CV_IREF._LENGTH,EDX
		MOV	CV_IREF._ALIGN_OFF,EAX

		SHL	ECX,16
		MOV	EAX,CURNMOD_NUMBER

		OR	ECX,EAX
		MOV	EAX,ESI

		MOV	DPTR CV_IREF._MODULE,ECX

		push	EAX
		call	_get_name_hash32		;HASH IS IN EAX
		add	ESP,4

		PUSH	ESI
		XOR	ECX,ECX			;NO TEXT

		LEA	ESI,CV_IREF

		push	ESI
		push	ECX
		push	EAX
		call	_install_globalsym	;STICK IN GLOBALSYM TABLE
		add	ESP,12

		POP	ESI

		RET

INSTALL_GSYM_REF	ENDP


GET_NAME_HASH32	PROC	NEAR
		push	EAX
		call	_get_name_hash32
		add	ESP,4
		ret

		GET_OMF_NAME_LENGTH_EAX

		MOV	SYMBOL_LENGTH,EAX

		lea	EDX,[EAX][ECX]
		push	EDX
		push	ECX
		push	EAX
		call	_opti_hash32
		add	ESP,8
		pop	ECX
		ret

;		CALL	OPTI_HASH32
;		RET

GET_NAME_HASH32	ENDP


OPTI_HASH32	PROC	NEAR
		;
		;ECX IS INPUT POINTER, EAX IS BYTE COUNT
		;
		TEST	EAX,EAX
		JZ	L95$

		PUSH	ESI
		MOV	ESI,ECX

		PUSH	EAX
		XOR	EDX,EDX

		SHR	EAX,2
		JZ	L4$			;3		;6
L2$:
		MOV	ECX,[ESI]

		ROL	EDX,4
		AND	ECX,0DFDFDFDFH

		ADD	ESI,4
		XOR	EDX,ECX

		DEC	EAX
		JNZ	L2$			;4		;7
L4$:
		ROL	EDX,4
		POP	EAX

		AND	EAX,3
		JZ	L9$			;2

		XOR	ECX,ECX
		DEC	EAX

		MOV	CH,[ESI]
		JZ	L7$

		SHL	ECX,16

		MOV	CL,[ESI+1]
		INC	ESI

		DEC	EAX
		JZ	L8$

		MOV	CH,[ESI+1]
		INC	ESI
L8$:
		ROR	ECX,16

L7$:
		AND	ECX,0DFDFDFDFH
		INC	ESI

		XOR	EDX,ECX
L9$:
		MOV	EAX,EDX		;4 PER 4 BYTES + 6 OVERHEAD + 4 FOR FIRST ODD BYTE + 4 FOR NEXT + 1 FOR NEXT

		MOV	ECX,ESI
		POP	ESI
L95$:
		RET

OPTI_HASH32	ENDP


GET_NAME_HASH32_CASE	PROC	NEAR
		;
		;
		;
		GET_OMF_NAME_LENGTH_EAX

		MOV	SYMBOL_LENGTH,EAX
;		CALL	OPTI_HASH32_CASE
;		RET

GET_NAME_HASH32_CASE	ENDP


OPTI_HASH32_CASE	PROC	NEAR
		;
		;
		;
		TEST	EAX,EAX
		JZ	L95$

		PUSH	ESI
		MOV	ESI,ECX

		PUSH	EAX
		XOR	EDX,EDX

		SHR	EAX,2
		JZ	L4$			;3		;6
L2$:
		ROL	EDX,4
		MOV	ECX,[ESI]

		ADD	ESI,4
		XOR	EDX,ECX

		DEC	EAX
		JNZ	L2$			;3		;6
L4$:
		ROL	EDX,4
		POP	EAX

		AND	EAX,3
		JZ	L9$			;2

		XOR	ECX,ECX
		DEC	EAX

		MOV	CH,[ESI]
		JZ	L7$

		SHL	ECX,16

		MOV	CL,[ESI+1]
		INC	ESI

		DEC	EAX
		JZ	L8$

		MOV	CH,[ESI+1]
		INC	ESI
L8$:
		ROR	ECX,16
L7$:
		INC	ESI

		XOR	EDX,ECX
L9$:
		MOV	EAX,EDX		;3 PER 4 BYTES + 6 OVERHEAD + 3 FOR FIRST ODD BYTE + 4 FOR NEXT + 1 FOR NEXT

		MOV	ECX,ESI
		POP	ESI
L95$:
		RET

OPTI_HASH32_CASE	ENDP


DO_SSEARCH_SYMS	PROC	NEAR
		;
		;OUTPUT S_SSEARCH SYMBOLS, SET UP NECESSARY ARRAYS
		;
		MOV	EDX,CV_SSEARCH_CNT	;# OF START_SEARCH SYMBOLS NEEDED

		TEST	EDX,EDX
		JZ	L9$

		PUSH	EDI
		MOV	EDI,EDX
L1$:
		MOV	ECX,CV_SSEARCH_TXT_LEN
		LEA	EDX,CV_ASYM_STRUCTURE

		MOV	EAX,OFF CV_SSEARCH_TXT
		CALL	STORE_EAXECX_EDX_SEQ

		DEC	EDI
		JNZ	L1$

		MOV	ECX,CV_SSEARCH_CNT
		LEA	EDI,CV_SSEARCH_PTRS

		CMP	ECX,8
		JA	L5$			;TOO MANY, DO THE HARD WAY
L4$:
		ADD	ECX,ECX
		XOR	EAX,EAX

		REP	STOSD

		MOV	CV_NEXT_SSEARCH,4	;SKIP LEADING 00000001
		POP	EDI
L9$:
		RET


L5$:
		CMP	ECX,PAGE_SIZE/8
		JAE	L99$

		CALL	GET_NEW_LOG_BLK

		MOV	EDI,EAX
		MOV	CV_SSEARCH_PTRS,EAX

		JMP	L4$

L99$:
		MOV	AL,CVP_SSEARCH_ERR
		push	EAX
		call	_err_abort

DO_SSEARCH_SYMS	ENDP


GET_CV_SYMBOL2	PROC	NEAR
		;
		;RETURN ESI PTR TO SYMBOL
		;
		MOV	ESI,CV_BYTES_PTR
		CALL	GET_CV_DWORD		;LENGTH OF SYMBOL RECORD & ID

		MOV	ECX,EAX
		MOV	DPTR TEMP_RECORD,EAX

		SHR	ECX,16
		AND	EAX,0FFFFH

		SUB	EAX,2			;ID ALREADY STORED
		MOV	EDI,OFF TEMP_RECORD+4

		CMP	CL,I_S_DELETE
		JZ	L9$

		CALL	MOVE_EAX_CV_BYTES

		MOV	EBX,DPTR TEMP_RECORD
		MOV	CL,2

		SUB	ECX,EBX
		MOV	CV_BYTES_PTR,ESI

		SHR	EBX,16
		MOV	ESI,OFF TEMP_RECORD

		AND	ECX,3			;DOING DWORD ALIGN
		JZ	L5$

		ADD	WPTR [ESI],CX
		XOR	EAX,EAX
L3$:
		MOV	[EDI],AL
		INC	EDI

		DEC	ECX
		JNZ	L3$
L5$:
		RET

L9$:
		MOV	EBX,ECX
		CALL	SKIP_EAX_CV_BYTES

		MOV	CV_BYTES_PTR,ESI
		MOV	ESI,OFF TEMP_RECORD

		RET

GET_CV_SYMBOL2	ENDP


SKIP_EAX_CV_BYTES	PROC	NEAR	PRIVATE
		;
		;NEED TO SKIP SMALLER OF EAX AND PAGE_SIZE-SI
		;
		MOV	ECX,CV_THIS_BLOCK_LIMIT
		MOV	EDX,CV_BYTES_LEFT

		SUB	ECX,ESI
		SUB	EDX,EAX

		MOV	CV_BYTES_LEFT,EDX
		JC	L9$
L1$:
		SUB	EAX,ECX
		JA	L5$

		ADD	ECX,EAX
		XOR	EAX,EAX
L5$:
		ADD	EDI,ECX
		ADD	ESI,ECX

		XOR	ECX,ECX

		OR	EAX,EAX
		JNZ	L3$
L9$:
		RET

L3$:
		;
		;GET NEXT BLOCK
		;
		PUSH	EAX
		CALL	ADJUST_CV_PTR

		POP	EAX
		MOV	ECX,PAGE_SIZE

		JNC	L1$

		RET

SKIP_EAX_CV_BYTES	ENDP


PUT_CV_SYMBOL2	PROC	NEAR
		;
		;
		;
		ASSUME	ESI:PTR CV_SYMBOL_STRUCT

		MOV	EAX,DPTR [ESI]._LENGTH

		MOV	ECX,EAX

		SHR	EAX,16
		AND	ECX,0FFFFH

		CMP	AL,I_S_DELETE
		JZ	L9$

		MOV	EAX,I2S_TBL[EAX*4]
		ADD	ECX,2

		MOV	[ESI]._ID,AX
		LEA	EDX,CV_ASYM_STRUCTURE

		MOV	EAX,ESI
		JMP	STORE_EAXECX_EDX_SEQ

L9$:
		RET

PUT_CV_SYMBOL2	ENDP


		ASSUME	ESI:NOTHING

PP2_RETT	PROC	NEAR
		;
		;NOTHING
		;
		RET

PP2_RETT	ENDP


PP2_ERROR	PROC	NEAR
		;
		;CANNOT HAPPEN
		;
		MOV	AL,CVP_CORRUPT_ERR
		push	EAX
		call	_err_abort

PP2_ERROR	ENDP


PP2_TYPE_4	PROC	NEAR
		;
		;CONVERT TYPE AT OFFSET 4
		;
		MOV	EAX,4[ESI]

		CMP	AH,10H
		JB	L9$

		AND	EAX,0FFFFH
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	4[ESI],AX
L9$:
		RET

PP2_TYPE_4	ENDP


PP2_TYPE_6	PROC	NEAR
		;
		;CONVERT TYPE AT OFFSET 6
		;
		MOV	EAX,4[ESI]

		CMP	EAX,10000000H
		JB	L9$

		SHR	EAX,16
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	6[ESI],AX
L9$:
		RET

PP2_TYPE_6	ENDP


PP2_TYPE_8	PROC	NEAR
		;
		;CONVERT TYPE AT OFFSET 8
		;
		MOV	EAX,8[ESI]

		CMP	AH,10H
		JB	L9$

		AND	EAX,0FFFFH
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	8[ESI],AX
L9$:
		RET

PP2_TYPE_8	ENDP


PP2_VFTPATH16	PROC	NEAR
		;
		;
		;
		CALL	PP2_TYPE_8
;		JMP	PP2_TYPE_10

PP2_VFTPATH16	ENDP


PP2_TYPE_10	PROC	NEAR
		;
		;CONVERT TYPE AT OFFSET 10
		;
		MOV	EAX,8[ESI]

		CMP	EAX,10000000H
		JB	L9$

		SHR	EAX,16
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	10[ESI],AX
L9$:
		RET

PP2_TYPE_10	ENDP


PP2_VFTPATH32	PROC	NEAR
		;
		;
		;
		CALL	PP2_TYPE_10
;		CALL	PP2_TYPE_12
;		RET

PP2_VFTPATH32	ENDP


PP2_TYPE_12	PROC	NEAR
		;
		;CONVERT TYPE AT OFFSET 12
		;
		MOV	EAX,12[ESI]

		CMP	AH,10H
		JB	L9$

		AND	EAX,0FFFFH
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	12[ESI],AX
L9$:
		RET

PP2_TYPE_12	ENDP


PP2_TYPE_26	PROC	NEAR
		;
		;CONVERT TYPE AT OFFSET 26
		;
		MOV	EAX,24[ESI]

		CMP	EAX,10000000H
		JB	L9$

		SHR	EAX,16
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	26[ESI],AX
L9$:
		RET

PP2_TYPE_26	ENDP


PP2_TYPE_34	PROC	NEAR
		;
		;CONVERT TYPE AT OFFSET 34
		;
		MOV	EAX,32[ESI]

		CMP	EAX,10000000H
		JB	L9$

		SHR	EAX,16
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	34[ESI],AX
L9$:
		RET

PP2_TYPE_34	ENDP


PP2_DATA16	PROC	NEAR
		;
		;CONVERT TYPE
		;INSTALL A DATAREF IN STATICSYM
		;
		ASSUME	ESI:PTR CV_LDATA16_STRUCT

		CALL	PP2_TYPE_8

		MOV	EDX,DPTR [ESI]._LENGTH
		MOV	EAX,DPTR [ESI]._OFFSET

		SHR	EDX,16				;_ID
		MOV	ECX,EAX

		PUSH	ESI
		LEA	ESI,[ESI]._NAME

		SHR	ECX,16				;_SEGMENT
		AND	EAX,0FFFFH			;_OFFSET

		CMP	EDX,I_S_LDATA16
		JZ	L5$

		MOV	DL,I_S_DATAREF
		CALL	INSTALL_GSYM_REF

		POP	ESI

		RET

L5$:
		MOV	EDX,S_DATAREF
		CALL	INSTALL_SSYM

		POP	ESI
		JC	PP2_DELETE

		RET

PP2_DATA16	ENDP


PP2_DATA32	PROC	NEAR
		;
		;CONVERT TYPE
		;INSTALL A DATAREF IN STATICSYM
		;
		ASSUME	ESI:PTR CV_LDATA32_STRUCT

		PUSH	ESI
		CALL	PP2_TYPE_10

		MOV	EDX,DPTR [ESI]._LENGTH
		MOV	ECX,DPTR [ESI]._SEGMENT

		SHR	EDX,16				;_ID
		AND	ECX,0FFFFH			;_SEGMENT

		MOV	EAX,[ESI]._OFFSET
		LEA	ESI,[ESI]._NAME

		CMP	DL,I_S_LDATA32
		JZ	L5$

		MOV	DL,I_S_DATAREF
		CALL	INSTALL_GSYM_REF

		POP	ESI

		RET

L5$:
		MOV	EDX,S_DATAREF
		CALL	INSTALL_SSYM

		POP	ESI
		JC	PP2_DELETE

		RET

PP2_DATA32	ENDP


PP2_PROC16	PROC	NEAR
		;
		;CONVERT TYPE
		;HANDLE NESTING
		;
		ASSUME	ESI:PTR CV_LPROC16_STRUCT

		CALL	PP2_TYPE_26

		MOV	EAX,DPTR [ESI]._SEGMENT
		CALL	NEST_PROC

		MOV	EAX,DPTR [ESI]._DBG_END
		MOV	ECX,DPTR [ESI]._SEGMENT

		SHR	EAX,16			;_OFFSET
		AND	ECX,0FFFFH		;_SEGMENT

		MOV	EDX,DPTR [ESI]._LENGTH
		PUSH	ESI

		SHR	EDX,16			;_ID
		LEA	ESI,[ESI]._NAME

		CMP	DL,I_S_LPROC16
		JZ	L5$

		MOV	DL,I_S_PROCREF
		CALL	INSTALL_GSYM_REF

		POP	ESI

		RET

L5$:
		MOV	EDX,S_PROCREF
		CALL	INSTALL_SSYM

		POP	ESI
		JC	PP2_DELETE

		RET

PP2_PROC16	ENDP


PP2_DELETE	PROC	NEAR
		;
		;I DON'T REMEMBER WHY THIS IS DIFFERENT FROM PP1_DELETE...
		;
		MOV	BPTR [ESI]._ID,I_S_DELETE

		RET

PP2_DELETE	ENDP


PP2_PROC32	PROC	NEAR
		;
		;CONVERT TYPE
		;HANDLE NESTING
		;
		ASSUME	ESI:PTR CV_LPROC32_STRUCT

		PUSH	ESI
		CALL	PP2_TYPE_34

		MOV	EAX,DPTR [ESI]._SEGMENT
		CALL	NEST_PROC

		MOV	EDX,DPTR [ESI]._LENGTH
		MOV	ECX,DPTR [ESI]._SEGMENT

		SHR	EDX,16			;_ID
		AND	ECX,0FFFFH		;_SEGMENT

		MOV	EAX,[ESI]._OFFSET
		LEA	ESI,[ESI]._NAME

		CMP	DL,I_S_LPROC32
		JZ	L5$

		MOV	DL,I_S_PROCREF
		CALL	INSTALL_GSYM_REF

		POP	ESI

		RET

L5$:
		MOV	EDX,S_PROCREF
		CALL	INSTALL_SSYM

		POP	ESI
		JC	PP2_DELETE

		RET

PP2_PROC32	ENDP


PP2_THUNK16	PROC	NEAR
		;
		;NEST PROC
		;
		ASSUME	ESI:PTR CV_THUNK16_STRUCT

		MOV	AX,[ESI]._SEGMENT
		JMP	NEST_PROC

PP2_THUNK16	ENDP


PP2_THUNK32	PROC	NEAR
		;
		;NEST PROC
		;
		ASSUME	ESI:PTR CV_THUNK32_STRUCT

		MOV	EAX,DPTR [ESI]._SEGMENT
		JMP	NEST_PROC

PP2_THUNK32	ENDP


PP2_BLOCK16	PROC	NEAR
		;
		;NEST BLOCK
		;
		ASSUME	ESI:PTR CV_BLOCK16_STRUCT

		MOV	EAX,DPTR [ESI]._SEGMENT
		JMP	NEST_BLOCK

PP2_BLOCK16	ENDP


PP2_BLOCK32	PROC	NEAR
		;
		;NEST BLOCK
		;
		ASSUME	ESI:PTR CV_BLOCK32_STRUCT

		MOV	EAX,DPTR [ESI]._SEGMENT
		JMP	NEST_BLOCK

PP2_BLOCK32	ENDP


PP2_S_END	PROC	NEAR
		;
		;CLOSE A SCOPE
		;
		MOV	EDX,CV_PPARENT		;IS THERE A PARENT?
		GET_CV_ASYM_OFFSET		;IN EAX

		TEST	EDX,EDX
		JZ	L99$

		MOV	CV_TEMP_DWORD,EAX
		LEA	EAX,CV_TEMP_DWORD

		LEA	EBX,[EDX+8]
		LEA	EDX,CV_ASYM_STRUCTURE

		MOV	ECX,4
		CALL	STORE_EAXECX_EDXEBX_RANDOM

		MOV	ECX,4
		MOV	EBX,CV_PPARENT

		LEA	EAX,CV_PPARENT
		LEA	EDX,CV_ASYM_STRUCTURE

		ADD	EBX,ECX
		JMP	READ_EAXECX_EDXEBX_RANDOM

L99$:
		MOV	AL,CVP_SCOPE_ERR
		push	EAX
		call	_err_abort

PP2_S_END	ENDP


NEST_PROC	PROC	NEAR
		;
		;AX IS SEGMENT, NEST PLEASE
		;
		MOV	EDX,CV_PPARENT		;IS THERE A PARENT?
		AND	EAX,0FFFFH

		TEST	EDX,EDX
		JNZ	L7$
		;
		;THIS IS ROOT LEVEL, HOOK THIS TO CORRECT SSEARCH CHAIN.
		;
;		PUSH	ESI
		MOV	CV_PPARENT_SEGMENT,EAX

		MOV	ECX,CV_SSEARCH_CNT
		LEA	EDX,CV_SSEARCH_PTRS

		CMP	ECX,8
		JBE	L1$

		MOV	EDX,CV_SSEARCH_PTRS	;SEARCH FOR MATCH OR ZERO
L1$:
		MOV	ECX,[EDX]
		ADD	EDX,8

		CMP	ECX,EAX
		JZ	L14$

		TEST	ECX,ECX
		JNZ	L1$
L12$:
		;
		;CREATE ENTRY
		;
		MOV	[EDX-8],EAX
		GET_CV_ASYM_OFFSET		;IN EAX

		MOV	[EDX-4],EAX
L13$:
		MOV	EBX,CV_NEXT_SSEARCH
		MOV	CV_PPARENT,EAX

		MOV	EAX,EBX
		ADD	EBX,4

		ADD	EAX,SIZE CV_SEARCH_STRUCT
		MOV	ECX,6

		MOV	CV_NEXT_SSEARCH,EAX
		LEA	EDX,CV_ASYM_STRUCTURE

		LEA	EAX,CV_PPARENT
		JMP	STORE_EAXECX_EDXEBX_RANDOM

L14$:
		;
		;FOUND ENTRY
		;
		GET_CV_ASYM_OFFSET		;IN EAX
		MOV	ECX,[EDX-4]

		MOV	CV_PPARENT,EAX
		MOV	[EDX-4],EAX

		LEA	EBX,[ECX+12]		;POINT TO PNEXT
		LEA	EDX,CV_ASYM_STRUCTURE

		LEA	EAX,CV_PPARENT		;UPDATE PREVIOUS TO POINT TO ME
		MOV	ECX,4

		JMP	STORE_EAXECX_EDXEBX_RANDOM

L7$:
NEST_PROC_WITH_PARENT::
		ASSUME	ESI:PTR CV_LPROC16_STRUCT

		MOV	ECX,CV_PPARENT_SEGMENT
		MOV	[ESI]._PPARENT,EDX

		CMP	ECX,EAX
		JNZ	L99$
L8$:
		GET_CV_ASYM_OFFSET		;IN EAX

		MOV	CV_PPARENT,EAX

		RET

L99$:
		MOV	AL,CVP_NEST_SEG_ERR
		CALL	WARN_RET
		JMP	L8$

		ASSUME	ESI:NOTHING

NEST_PROC	ENDP


NEST_BLOCK	PROC	NEAR
		;
		;AX IS SEGMENT, NEST PLEASE
		;
		MOV	EDX,CV_PPARENT		;IS THERE A PARENT?

		TEST	EDX,EDX
		JNZ	NEST_PROC_WITH_PARENT

		MOV	AL,CVP_BLOCK_WO_PARENT_ERR
		push	EAX
		call	_err_abort

NEST_BLOCK	ENDP


CV_SYMBOL_CLEANUP	PROC	NEAR
		;
		;CLEAN-UP
		;
		;	1.  OUTPUT ALIGNSYM SECTION AND CV_INDEX IF NOT ZERO LENGTH
		;	2.  FIX TYPES ON ANY GLOBALSYM ENTRIES WE MADE
		;
		PUSHM	EDI,ESI,EBX

		CMP	CV_SSEARCH_CNT,8
		JBE	L1$

		MOV	EAX,CV_SSEARCH_PTRS
		CALL	RELEASE_BLOCK
L1$:
		;
		;TRANSFER STUFF FROM CV_ASYM_STRUCTURE TO EXETABLE
		;
		LEA	ESI,CV_ASYM_STRUCTURE._SEQ_TABLE
		MOV	EBX,OFF EXETABLE
L11$:
		MOV	EAX,[ESI]
		ADD	ESI,4

		MOV	[EBX],EAX
		ADD	EBX,4

		TEST	EAX,EAX
		JNZ	L11$
		;
		;NOW FLUSH THAT STUFF TO FINAL
		;
		GET_CV_ASYM_OFFSET	;EAX IS BYTES IN TABLE

		PUSH	EAX
		CALL	FLUSH_EAX_TO_FINAL
		;
		;WRITE CV_INDEX
		;
		POP	ECX
		MOV	EAX,0125H		;SSTALIGNSYM

		PUSH	ECX
		CALL	WRITE_CV_INDEX

		POP	ECX
		MOV	EDX,BYTES_SO_FAR

		ADD	EDX,ECX
		MOV	ESI,CV_GSYM_START
		;
		;NOW CHECK GLOBALSYMS I ADDED FOR TYPES TO CONVERT
		;
		MOV	BYTES_SO_FAR,EDX
		GETT	AL,CV_WARNINGS

		CMP	ECX,64K
		JB	L3$

		TEST	AL,AL
		JZ	L3$

		MOV	AL,CVP_SYMBOLS_64K_ERR
		CALL	WARN_RET
L3$:
		TEST	ESI,ESI
		JZ	L4$

		CONVERT	ESI,ESI,CV_GSYM_GARRAY
		ASSUME	ESI:PTR CVG_REF_STRUCT

		MOV	ESI,[ESI]._NEXT_GSYM_GINDEX
		JMP	L6$

L4$:
		MOV	ESI,FIRST_GSYM_GINDEX
		JMP	L6$

L5$:
		CONVERT	ESI,ESI,CV_GSYM_GARRAY
		ASSUME	ESI:PTR CVG_REF_STRUCT

		MOV	EBX,[ESI]._NEXT_GSYM_GINDEX
		XOR	EAX,EAX

		MOV	AL,BPTR [ESI]._ID	;INTERNAL ID...
		ADD	ESI,SIZE CV_GLOBALSYM_STRUCT

		CMP	AL,I_S_CONSTANT
		JZ	L55$

		CMP	AL,I_S_UDT
		JZ	L55$

		ADD	ESI,4

		CMP	AL,I_S_GDATA16
		JZ	L55$

		ADD	ESI,2

		CMP	AL,I_S_GDATA32
		JNZ	L59$

		ASSUME	ESI:NOTHING

L55$:
		MOV	AH,[ESI+1]

		CMP	AH,10H
		JB	L59$

		MOV	AL,[ESI]
		CALL	CONVERT_CV_LTYPE_GTYPE_A

		MOV	[ESI],AX
L59$:
		MOV	ESI,EBX
L6$:
		TEST	ESI,ESI
		JNZ	L5$
		;
		;THAT SHOULD DO IT...
		;
		POPM	EBX,ESI,EDI

		RET

CV_SYMBOL_CLEANUP	ENDP


INSTALL_SSYM	PROC	NEAR
		;
		;EAX IS OFFSET
		;ECX IS SEGMENT
		;EDX IS REF TYPE
		;ESI IS NAME TEXT
		;

		SHL	EDX,16
		MOV	ISSYM_OFFSET,EAX

		OR	ECX,EDX
		MOV	EAX,ESI

		MOV	DPTR ISSYM_SEGMENT,ECX
		CALL	GET_NAME_HASH32

		MOV	EDX,DPTR ISSYM_SEGMENT
		MOV	ECX,ISSYM_OFFSET

		SHL	EDX,16
		MOV	ISSYM_HASH,EAX

		XOR	EAX,ECX
		MOV	ESI,SSYM_HASH_LOG

		XOR	EAX,EDX
		XOR	EDX,EDX
		;
		;SEE IF ONE ALREADY IN TABLE WITH MATCHING HASH AND ADDRESS
		;
		HASHDIV	SSYM_HASH

		PUSHM	EDI,EBX

		MOV	ECX,ISSYM_HASH
		MOV	EDI,ISSYM_OFFSET

		MOV	EBX,DPTR ISSYM_SEGMENT
		MOV	EAX,[ESI+EDX*4]

		LEA	ESI,[ESI+EDX*4 - CV_GLOBALSYM_STRUCT._NEXT_HASH_GINDEX]
		JMP	L2$

		ASSUME	ESI:PTR CV_GLOBALSYM_STRUCT
L1$:
		MOV	EAX,[ESI]._NEXT_HASH_GINDEX
L2$:
		TEST	EAX,EAX
		JZ	L5$

		CONVERT	EAX,EAX,CV_SSYM_GARRAY
		ASSUME	EAX:PTR CVG_REF_STRUCT
		MOV	ESI,EAX
		MOV	EDX,[EAX]._HASH

		CMP	EDX,ECX
		JNZ	L1$

		MOV	DX,[EAX]._SEGMENT
		MOV	EAX,[EAX]._OFFSET

		CMP	EAX,EDI
		JNZ	L1$

		CMP	DX,BX
		JNZ	L1$

		CMP	ESP,-1

		POPM	EBX,EDI

		RET

L5$:
		MOV	EAX,SIZE CVG_REF_STRUCT
		CALL	CV_SSYM_POOL_GET

		MOV	EDX,EAX
		ASSUME	EDX:PTR CVG_REF_STRUCT
		INSTALL_POINTER_GINDEX	CV_SSYM_GARRAY
		MOV	[ESI]._NEXT_HASH_GINDEX,EAX

		MOV	ESI,LAST_SSYM_GINDEX
		MOV	[EDX]._HASH,ECX

		TEST	ESI,ESI
		JZ	L6$

		CONVERT	ESI,ESI,CV_SSYM_GARRAY
		MOV	[ESI]._NEXT_GSYM_GINDEX,EAX
L7$:
		MOV	LAST_SSYM_GINDEX,EAX

		XOR	EAX,EAX
		MOV	[EDX]._OFFSET,EDI

		MOV	[EDX]._NEXT_HASH_GINDEX,EAX
		MOV	[EDX]._NEXT_GSYM_GINDEX,EAX

		MOV	[EDX]._TEXT_OFFSET,EAX
		MOV	DPTR [EDX]._LENGTH,EBX		;ACTUALLY, ID IN HIGH WORD

		SHL	EBX,16				;MOVE SEGMENT TO HI WORD
		MOV	EAX,CV_REFSYM_CNT

		MOV	ECX,CURNMOD_NUMBER
		INC	EAX

		OR	EBX,ECX
		MOV	CV_REFSYM_CNT,EAX

		GET_CV_ASYM_OFFSET		;IN EAX
		MOV	DPTR [EDX]._MODULE,EBX

		POPM	EBX,EDI

		MOV	[EDX]._ALIGN_OFF,EAX
		OR	EAX,EAX

		RET

L6$:
		MOV	FIRST_SSYM_GINDEX,EAX
		JMP	L7$

INSTALL_SSYM	ENDP


		.DATA

		ALIGN	4

PROCSYM_PASS1	LABEL	DWORD

		DD	PP1_W_DELETE		;TYPE 0 - UNDEFINED, WARN AND DELETE
		DD	PP1_PASS_THRU		;TYPE 1 - S_COMPILE
		DD	PP1_PASS_ND		;TYPE 2 - S_REGISTER, PASS THRU IF NOT DELETING THIS SCOPE
		DD	PP1_CONSTANT		;TYPE 3 - S_CONSTANT, GLOBALIZE IF LEVEL 0
		DD	PP1_UDT			;TYPE 4 - S_UDT
		DD	PP1_W_DELETE		;TYPE 5 - S_SSEARCH, ILLEGAL
		DD	PP1_S_END		;TYPE 6 - UNNEST SCOPES
		DD	PP1_DELETE		;TYPE 7 - S_SKIP, IGNORE
		DD	PP1_W_DELETE		;TYPE 8 - INTERNAL, MEANS DELETE LATER
		DD	PP1_PASS_THRU		;TYPE 9 - S_OBJNAME, KEEP IT
		DD	PP1_PASS_ND		;TYPE A - S_ENDARG
		DD	PP1_PASS_ND		;TYPE B - S_COBOL_UDT
		DD	PP1_PASS_ND		;TYPE C - S_MANYREG
		DD	PP1_PASS_ND		;TYPE D - S_RETURN
		DD	PP1_W_DELETE		;TYPE E - S_ENTRYTHIS
		DD	PP1_W_DELETE		;TYPE F - S_TDBNAME (error - new format)
		DD	PP1_PASS_ND		;TYPE 100 - S_BPREL16
		DD	PP1_LDATA16		;TYPE 101 - S_LDATA16
		DD	PP1_S_GDATA16		;TYPE 102
		DD	PP1_W_DELETE		;TYPE 103, LINKER GENERATED ONLY...
		DD	PP1_PROC16		;TYPE 104 - S_LPROC16, ENTER A 16-BIT PROCEDURE SCOPE
		DD	PP1_PROC16		;TYPE 105 - S_GPROC16
		DD	PP1_THUNK16		;TYPE 106 - S_THUNK16
		DD	PP1_BLOCK16		;TYPE 107 - S_BLOCK16
		DD	PP1_BLOCK16		;TYPE 108 - S_WITH16
		DD	PP1_LABEL16		;TYPE 109 - S_LABEL16
		DD	PP1_CEXMODEL16		;TYPE 10A - S_CEXMODEL16
		DD	PP1_VFTPATH16		;TYPE 10B - S_VFTPATH16
		DD	PP1_PASS_ND		;TYPE 10C - S_REGREL16
		DD	PP1_PASS_ND		;TYPE 200 - S_BPREL32
		DD	PP1_LDATA32		;TYPE 201 - S_LDATA32
		DD	PP1_S_GDATA32		;TYPE 202
		DD	PP1_W_DELETE		;TYPE 203, LINKER GENERATED ONLY...
		DD	PP1_PROC32		;TYPE 204 - S_LPROC32, ENTER A 32-BIT PROCEDURE SCOPE
		DD	PP1_PROC32		;TYPE 205 - S_GPROC32
		DD	PP1_THUNK32		;TYPE 206 - S_THUNK32
		DD	PP1_BLOCK32		;TYPE 207 - S_BLOCK32
		DD	PP1_BLOCK32		;TYPE 208 - S_WITH32
		DD	PP1_LABEL32		;TYPE 209 - S_LABEL32
		DD	PP1_CEXMODEL32		;TYPE 20A - S_CEXMODEL32
		DD	PP1_VFTPATH32		;TYPE 20B - S_VFTPATH32
		DD	PP1_PASS_ND		;TYPE 20C - S_REGREL32
		DD	PP1_LDATA32		;TYPE 20D - S_LTHREAD32
		DD	PP1_S_GDATA32		;TYPE 20E - S_GTHREAD32


		ALIGN	4

PROCSYM_PASS2	LABEL	DWORD

		DD	PP2_ERROR		;TYPE 0 - UNDEFINED, CAN'T PASS 2
		DD	PP2_RETT		;TYPE 1 - S_COMPILE
		DD	PP2_TYPE_4		;TYPE 2 - S_REGISTER, TYPE AT 4
		DD	PP2_TYPE_4		;TYPE 3 - S_CONSTANT, TYPE AT 4
		DD	PP2_TYPE_4		;TYPE 4 - S_UDT, TYPE AT 4
		DD	PP2_ERROR		;TYPE 5 - S_SSEARCH, ILLEGAL
		DD	PP2_S_END		;TYPE 6 - UNNEST SCOPES
		DD	PP2_ERROR		;TYPE 7 - S_SKIP, CAN'T PASS 2
		DD	PP2_RETT		;TYPE 8 - INTERNAL, MEANS DELETE LATER
		DD	PP2_RETT		;TYPE 9 - S_OBJNAME, KEEP IT
		DD	PP2_RETT		;TYPE A - S_ENDARG
		DD	PP2_TYPE_4		;TYPE B - S_COBOL_UDT
		DD	PP2_TYPE_4		;TYPE C - S_MANYREG
		DD	PP2_RETT		;TYPE D - S_RETURN
		DD	PP2_ERROR		;TYPE E - S_ENTRYTHIS
		DD	PP2_ERROR		;TYPE F - S_TDBNAME
		DD	PP2_TYPE_6		;TYPE 100 - S_BPREL16
		DD	PP2_DATA16		;TYPE 101 - S_LDATA16
		DD	PP2_DATA16		;TYPE 102 - S_GDATA16
		DD	PP2_ERROR		;TYPE 103, LINKER GENERATED ONLY...
		DD	PP2_PROC16		;TYPE 104 - S_LPROC16, ENTER A 16-BIT PROCEDURE SCOPE
		DD	PP2_PROC16		;TYPE 105 - S_GPROC16
		DD	PP2_THUNK16		;TYPE 106 - S_THUNK16
		DD	PP2_BLOCK16		;TYPE 107 - S_BLOCK16
		DD	PP2_BLOCK16		;TYPE 108 - S_WITH16
		DD	PP2_RETT		;TYPE 109 - S_LABEL16
		DD	PP2_RETT		;TYPE 10A - S_CEXMODEL16
		DD	PP2_VFTPATH16		;TYPE 10B - S_VFTPATH16
		DD	PP2_TYPE_8		;TYPE 10C - S_REGREL16
		DD	PP2_TYPE_8		;TYPE 200 - S_BPREL32
		DD	PP2_DATA32		;TYPE 201 - S_LDATA32
		DD	PP2_DATA32		;TYPE 202 - S_GDATA32
		DD	PP2_ERROR		;TYPE 203, LINKER GENERATED ONLY...
		DD	PP2_PROC32		;TYPE 204 - S_LPROC32, ENTER A 32-BIT PROCEDURE SCOPE
		DD	PP2_PROC32		;TYPE 205 - S_GPROC32
		DD	PP2_THUNK32		;TYPE 206 - S_THUNK32
		DD	PP2_BLOCK32		;TYPE 207 - S_BLOCK32
		DD	PP2_BLOCK32		;TYPE 208 - S_WITH32
		DD	PP2_RETT		;TYPE 209 - S_LABEL32
		DD	PP2_RETT		;TYPE 20A - S_CEXMODEL32
		DD	PP2_VFTPATH32		;TYPE 20B - S_VFTPATH32
		DD	PP2_TYPE_10		;TYPE 20C - S_REGREL32
		DD	PP2_DATA32		;TYPE 20D - S_LTHREAD32
		DD	PP2_DATA32		;TYPE 20E - S_GTHREAD32

ZERO_ONE	DD	1

I2S_TBL		DD	0,1,2,3,4,5,6,7,8,9,0AH,0BH,0CH,0DH,0EH,0FH
		DD	100H,101H,102H,103H,104H,105H,106H,107H,108H,109H,10AH,10BH,10CH
		DD	200H,201H,202H,203H,204H,205H,206H,207H,208H,209H,20AH,20BH,20CH,20DH,20EH
		DD	300H,301H
		DD	400H,401H,402H

CV_REFSYM	DB	SIZE CV_GLOBALSYM_STRUCT - 4 + SIZE CVG_REF_STRUCT DUP(?)


LEAF_SIZE	LABEL	BYTE

		DB	1		;8000
		DB	2		;8001
		DB	2		;8002
		DB	4		;8003
		DB	4		;8004
		DB	4		;8005
		DB	8		;8006
		DB	10		;8007
		DB	16		;8008
		DB	8		;8009
		DB	8		;800A
		DB	6		;800B
		DB	8		;800C
		DB	16		;800D
		DB	20		;800E
		DB	32		;800F


		ALIGN	4

CV_SSEARCH_TXT	DW	10,S_SSEARCH,0,0,0,0

CV_SSEARCH_TXT_LEN	EQU	$-CV_SSEARCH_TXT


		.DATA?

		ALIGN	4

ISSYM_OFFSET		DD	?
ISSYM_SEGMENT		DW	?
ISSYM_TYPE		DW	?
ISSYM_HASH		DD	?

endif

		END

