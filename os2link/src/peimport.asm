		TITLE	PEIMPORT - Copyright (c) SLR Systems 1994

		INCLUDE MACROS
if	fg_pe
		INCLUDE	SYMBOLS
		INCLUDE	SEGMSYMS
		INCLUDE	PE_STRUC

		PUBLIC	PE_OUTPUT_IMPORTS


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE,IMPORT_TABLE_USE:BYTE

		EXTERNDEF	N_IMPORTS_REFERENCED:DWORD,N_MODULES_REFERENCED:DWORD,FINAL_HIGH_WATER:DWORD,MODNAM_TEXT_SIZE:DWORD
		EXTERNDEF	NAME_TEXT_SIZE:DWORD,PE_THUNKS_RVA:DWORD,FIRST_IMPMOD_GINDEX:DWORD

		EXTERNDEF	SYMBOL_GARRAY:STD_PTR_S,IMPNAME_GARRAY:STD_PTR_S,IMPMOD_GARRAY:STD_PTR_S,IMPNAME_STUFF:ALLOCS_STRUCT


		.CODE	PASS2_TEXT

		EXTERNDEF	RELEASE_BLOCK:PROC,CHANGE_PE_OBJECT:PROC,MOVE_EAX_TO_EDX_FINAL:PROC,UNUSE_IMPORTS:PROC
		EXTERNDEF	_release_minidata:proc,RELEASE_GARRAY:PROC


N_LOOKUPS_ALLOWED	EQU	32


PE_IMP_VARS	STRUC

PEIMP_DIR_BP		PE_IMPORT_DIR_STRUCT <>

LOOKUPS_BUFFER_BP	DD	N_LOOKUPS_ALLOWED DUP(?)

PEIMP_DIRS_FA_BP	DD	?

LOOKUPS_RVA_BP		DD	?
LOOKUPS_FA_BP		DD	?
LOOKUPS_SIZE_BP		DD	?

HINTS_RVA_BP		DD	?
HINTS_FA_BP		DD	?

MODNAMS_RVA_BP		DD	?
MODNAMS_FA_BP		DD	?

THUNKS_RVA_BP		DD	?
THUNKS_FA_BP		DD	?

HINTS_PTR_BP		DD	?
LOOKUPS_PTR_BP		DD	?

HINT_BYTES_LEFT_BP	DD	?
LOOKUPS_LEFT_BP		DD	?

MY_RVA_BP		DD	?
MY_DELTA_BP		DD	?

PE_IMP_VARS	ENDS


FIX	MACRO	X

X	EQU	([EBP-SIZE PE_IMP_VARS].(X&_BP))

	ENDM


FIX	PEIMP_DIR
FIX	LOOKUPS_BUFFER
FIX	PEIMP_DIRS_FA

FIX	LOOKUPS_RVA
FIX	LOOKUPS_FA
FIX	LOOKUPS_SIZE

FIX	HINTS_RVA
FIX	HINTS_FA

FIX	MODNAMS_RVA
FIX	MODNAMS_FA

FIX	THUNKS_RVA
FIX	THUNKS_FA

FIX	HINTS_PTR
FIX	LOOKUPS_PTR

FIX	HINT_BYTES_LEFT
FIX	LOOKUPS_LEFT

FIX	MY_RVA
FIX	MY_DELTA


PE_OUTPUT_IMPORTS	PROC
		;
		;THIS BUILDS AND OUTPUTS THE IMPORTS SECTION...
		;
		GETT	AL,OUTPUT_PE
		MOV	ECX,FIRST_IMPMOD_GINDEX

		OR	AL,AL
		JZ	L09$

		TEST	ECX,ECX
		JNZ	L0$
L09$:
		RET				;NO IMPORTS, DONE!

L0$:
		PUSHM	EBP,EDI,ESI,EBX

		MOV	EBP,ESP
		SUB	ESP,SIZE PE_IMP_VARS
		ASSUME	EBP:PTR PE_IMP_VARS
		;
		;CALCULATE ADDRESSES TO STORE STUFF AT...
		;
		CALL	CHANGE_PE_OBJECT	;FLUSH PREVIOUS OBJECT, SETUP FOR NEW, DS:SI POINTS TO OBJECT
		ASSUME	EAX:PTR PE_OBJECT_STRUCT

		MOV	[EAX]._PEOBJECT_FLAGS,MASK PEL_INIT_DATA_OBJECT + MASK PEH_READABLE

		MOV	EBX,[EAX]._PEOBJECT_RVA
		MOV	EAX,FINAL_HIGH_WATER

		MOV	PEIMP_DIRS_FA,EAX
		SUB	EAX,EBX

		MOV	MY_DELTA,EAX
		MOV	ECX,EAX

		MOV	EAX,N_MODULES_REFERENCED
		MOV	MY_RVA,EBX

		INC	EAX
		MOV	EDX,SIZE PE_IMPORT_DIR_STRUCT

		MUL	EDX

		ADD	EBX,EAX
		MOV	EDX,ECX

		MOV	LOOKUPS_RVA,EBX
		MOV	EAX,N_IMPORTS_REFERENCED

		ADD	EDX,EBX
		MOV	ECX,N_MODULES_REFERENCED

		MOV	LOOKUPS_FA,EDX
		ADD	EAX,ECX

		SHL	EAX,2

		MOV	LOOKUPS_SIZE,EAX
		ADD	EBX,EAX

		MOV	HINTS_RVA,EBX
		MOV	ECX,MY_DELTA

		ADD	ECX,EBX
		MOV	EAX,NAME_TEXT_SIZE

		MOV	HINTS_FA,ECX
		ADD	EBX,EAX

		MOV	MODNAMS_RVA,EBX
		MOV	ECX,MY_DELTA

		ADD	ECX,EBX
		MOV	EAX,MODNAM_TEXT_SIZE

		MOV	MODNAMS_FA,ECX
		ADD	EBX,EAX

		ADD	EBX,3

		AND	BL,0FCH
		MOV	EAX,MY_DELTA

		MOV	THUNKS_RVA,EBX
		ADD	EAX,EBX

		MOV	PE_THUNKS_RVA,EBX
		MOV	THUNKS_FA,EAX

		LEA	EAX,LOOKUPS_BUFFER
		MOV	ECX,OFF TEMP_RECORD

		MOV	LOOKUPS_LEFT,N_LOOKUPS_ALLOWED

		MOV	LOOKUPS_PTR,EAX
		MOV	HINTS_PTR,ECX

		MOV	HINT_BYTES_LEFT,MAX_RECORD_LEN
		;
		;NOW SCAN FOR IMPORTS
		;
		MOV	EAX,FIRST_IMPMOD_GINDEX

		PUSH	EAX
		JMP	L3$

L1$:
		CONVERT	ESI,ESI,IMPMOD_GARRAY
		ASSUME	ESI:PTR IMPMOD_STRUCT

		MOV	EAX,[ESI]._IMPM_NEXT_GINDEX

		PUSH	EAX
		CALL	HANDLE_IMPMOD		;AX IS IMPMOD
L3$:
		;
		;ZERO OUT DIRECTORY FOR NEXT USE
		;
		LEA	EDI,PEIMP_DIR
		MOV	ECX,SIZE PE_IMPORT_DIR_STRUCT/4

		XOR	EAX,EAX
		POP	ESI

		REP	STOSD

		TEST	ESI,ESI
		JNZ	L1$

		CALL	WRITE_IMPDIR			;WRITE OUT A BLANK ONE...
		;
		;FLUSH DATA TO OUTPUT FILE
		;
		CALL	FLUSH_LOOKUPS

		CALL	FLUSH_HINT_BUFFER

		CALL	FLUSH_MODNAMS			;DEAL WITH DWORD ALIGN

		CALL	UNUSE_IMPORTS			;FREE UP THAT STORAGE IF .MAP DOESN'T NEED IT...

		MOV	ESP,EBP

		POPM	EBX,ESI,EDI,EBP

		RET

PE_OUTPUT_IMPORTS	ENDP


HANDLE_IMPMOD	PROC	NEAR	PRIVATE
		;
		;ESI IS IMPMOD PHYSICAL
		;
		MOV	ECX,[ESI]._IMPM_N_IMPORTS
		MOV	EAX,LOOKUPS_RVA

		TEST	ECX,ECX
		JZ	L9$

		MOV	EDX,THUNKS_RVA
		MOV	PEIMP_DIR._PEIMP_LOOKUPS_RVA,EAX

		MOV	PEIMP_DIR._PEIMP_THUNKS_RVA,EDX
		MOV	EAX,MODNAMS_RVA

		MOV	ECX,[ESI]._IMPM_LENGTH
		MOV	PEIMP_DIR._PEIMP_MODNAM_RVA,EAX

		LEA	EAX,[ESI]._IMPM_TEXT
		INC	ECX

		CALL	MOVE_MODNAME

		MOV	EAX,[ESI]._IMPM_NAME_SYM_GINDEX
		CALL	HANDLE_BYNAMES

		MOV	EAX,[ESI]._IMPM_ORD_SYM_GINDEX
		CALL	HANDLE_BYORDS

		XOR	EAX,EAX
		CALL	STORE_LOOKUP		;ZEROS MARK END OF MODULE

		JMP	WRITE_IMPDIR

L9$:
		RET

HANDLE_IMPMOD	ENDP


HANDLE_BYNAMES	PROC	NEAR	PRIVATE
		;
		;AX IS SYMBOL GINDEX
		;BY NAME MEANS:
		;	OUTPUT NAME TO HINT TABLE
		;	OUTPUT RVA OF HINT TO LOOKUP TABLE
		;
		TEST	EAX,EAX
		JZ	L9$

		PUSHM	ESI,EBX

		MOV	EBX,EAX
L1$:
		CONVERT	EBX,EBX,SYMBOL_GARRAY
		ASSUME	EBX:PTR SYMBOL_STRUCT

		MOV	ESI,[EBX]._S_IMP_IMPNAME_GINDEX
		MOV	EBX,[EBX]._S_IMP_NEXT_GINDEX

		MOV	EAX,HINTS_RVA
		CALL	STORE_LOOKUP

		CONVERT	ESI,ESI,IMPNAME_GARRAY
		ASSUME	ESI:PTR IMPNAME_STRUCT

		CALL	STORE_HINT

		TEST	EBX,EBX
		JNZ	L1$

		POPM	EBX,ESI
L9$:
		RET


HANDLE_BYNAMES	ENDP


HANDLE_BYORDS	PROC	NEAR	PRIVATE
		;
		;AX IS SYMBOL GINDEX
		;BY ORDINAL MEANS:
		;	OUTPUT (ORDINAL OR 80000000H) TO LOOKUP TABLE
		;
		TEST	EAX,EAX
		JZ	L9$

		PUSH	EBX
		MOV	EBX,EAX
L1$:
		CONVERT	EBX,EBX,SYMBOL_GARRAY
		ASSUME	EBX:PTR SYMBOL_STRUCT

		MOV	EAX,[EBX]._S_IMP_ORDINAL
		MOV	EBX,[EBX]._S_IMP_NEXT_GINDEX

		OR	EAX,80000000H
		CALL	STORE_LOOKUP

		TEST	EBX,EBX
		JNZ	L1$

		POP	EBX
L9$:
		RET

HANDLE_BYORDS	ENDP


STORE_LOOKUP	PROC	NEAR
		;
		;EAX IS ADDRESS TO STORE
		;
		MOV	EDX,LOOKUPS_PTR
		MOV	ECX,LOOKUPS_RVA

		ADD	ECX,4

		MOV	[EDX],EAX
		MOV	LOOKUPS_RVA,ECX

		MOV	EAX,THUNKS_RVA
		ADD	EDX,4

		ADD	EAX,4
		MOV	LOOKUPS_PTR,EDX

		MOV	ECX,LOOKUPS_LEFT
		MOV	THUNKS_RVA,EAX

		DEC	ECX

		MOV	LOOKUPS_LEFT,ECX
		JZ	FLUSH_LOOKUPS

		RET

STORE_LOOKUP	ENDP


FLUSH_LOOKUPS	PROC	NEAR
		;
		;
		;
		LEA	EAX,LOOKUPS_BUFFER
		MOV	ECX,LOOKUPS_PTR

		SUB	ECX,EAX
		JZ	L9$

		PUSH	ECX
		MOV	EDX,LOOKUPS_FA

		MOV	LOOKUPS_LEFT,N_LOOKUPS_ALLOWED

		ADD	EDX,ECX
		MOV	LOOKUPS_PTR,EAX

		MOV	LOOKUPS_FA,EDX
		SUB	EDX,ECX

		CALL	MOVE_EAX_TO_EDX_FINAL

		POP	ECX
		MOV	EDX,THUNKS_FA

		ADD	EDX,ECX
		LEA	EAX,LOOKUPS_BUFFER

		MOV	THUNKS_FA,EDX
		SUB	EDX,ECX

		JMP	MOVE_EAX_TO_EDX_FINAL

L9$:
		RET

FLUSH_LOOKUPS	ENDP


MOVE_MODNAME	PROC	NEAR
		;
		;DS:SI (AX) IS STRING TO MOVE
		;UPDATE MODNAMS_RVA
		;
		ADD	MODNAMS_RVA,ECX
		MOV	EDX,MODNAMS_FA

		ADD	MODNAMS_FA,ECX
		JMP	MOVE_EAX_TO_EDX_FINAL

MOVE_MODNAME	ENDP


FLUSH_MODNAMS	PROC	NEAR
		;
		;DO DWORD ALIGN FOR ME
		;
		MOV	EAX,MODNAMS_FA
		XOR	ECX,ECX

		SUB	ECX,EAX
		XOR	EDX,EDX

		AND	ECX,3
		JZ	L9$

		LEA	EAX,MODNAMS_RVA
		MOV	MODNAMS_RVA,EDX

		MOV	EDX,MODNAMS_FA
		JMP	MOVE_EAX_TO_EDX_FINAL

L9$:
		RET

FLUSH_MODNAMS	ENDP


WRITE_IMPDIR	PROC	NEAR
		;
		;
		;
		MOV	ECX,SIZE PE_IMPORT_DIR_STRUCT
		MOV	EDX,PEIMP_DIRS_FA

		ADD	EDX,ECX
		LEA	EAX,PEIMP_DIR

		MOV	PEIMP_DIRS_FA,EDX
		SUB	EDX,ECX

		JMP	MOVE_EAX_TO_EDX_FINAL

WRITE_IMPDIR	ENDP


STORE_HINT	PROC	NEAR
		;
		;ESI IS IMPNAME
		;
		ASSUME	ESI:PTR IMPNAME_STRUCT

		MOV	EAX,[ESI]._IMP_LENGTH
		MOV	ECX,[ESI]._IMP_HINT

		ADD	EAX,4
		LEA	ESI,[ESI]._IMP_TEXT

		MOV	EDX,HINTS_RVA
		AND	AL,0FEH

		ADD	EDX,EAX
		PUSH	EDI

		MOV	HINTS_RVA,EDX
L0$:
		MOV	EDX,HINT_BYTES_LEFT
		MOV	EDI,HINTS_PTR

		SUB	EDX,EAX
		JC	L5$

		MOV	[EDI],CX
		ADD	EDI,2

		MOV	HINT_BYTES_LEFT,EDX
		LEA	ECX,[EAX-2]

		OPTI_MOVSB

		MOV	HINTS_PTR,EDI
		POP	EDI

		RET

L5$:
		PUSHM	ECX,EAX
		CALL	FLUSH_HINT_BUFFER

		POPM	EAX,ECX
		JMP	L0$

STORE_HINT	ENDP


FLUSH_HINT_BUFFER	PROC	NEAR
		;
		;
		;
		MOV	ECX,HINTS_PTR
		MOV	EAX,OFF TEMP_RECORD

		SUB	ECX,EAX
		JZ	L9$

		MOV	HINTS_PTR,EAX
		MOV	EDX,HINTS_FA

		MOV	HINT_BYTES_LEFT,MAX_RECORD_LEN

		ADD	HINTS_FA,ECX
		JMP	MOVE_EAX_TO_EDX_FINAL

L9$:
		RET

FLUSH_HINT_BUFFER	ENDP

endif

		PUBLIC	UNUSE_IMPORTS

UNUSE_IMPORTS	PROC
		;
		;I AM DONE USING ENTRYNAME TABLE, AM I THE LAST?
		;
		DEC	IMPORT_TABLE_USE
		JZ	RELEASE_IMPORT_TABLE

		RET

UNUSE_IMPORTS	ENDP


RELEASE_IMPORT_TABLE	PROC	NEAR
		;
		;
		;
		MOV	EAX,OFF IMPNAME_STUFF
		push	EAX
		call	_release_minidata
		add	ESP,4

		MOV	EAX,OFF IMPNAME_GARRAY
		JMP	RELEASE_GARRAY

RELEASE_IMPORT_TABLE	ENDP


		END

