		TITLE GRPDEF - Copyright (c) 1994 by SLR Systems

		INCLUDE	MACROS
		INCLUDE	SEGMENTS
		INCLUDE	GROUPS
		INCLUDE	CDDATA

		PUBLIC	GRPDEF


		.DATA

		EXTERNDEF	END_OF_RECORD:DWORD,BUFFER_OFFSET:DWORD,GROUP_NAME_LINDEX:DWORD,FLAT_GINDEX:DWORD

		EXTERNDEF	GROUP_LARRAY:LARRAY_STRUCT,SEGMOD_LARRAY:LARRAY_STRUCT


		.CODE	PASS1_TEXT

		EXTERNDEF	OBJ_PHASE:PROC,GET_GROUP:PROC,PUT_SM_IN_GROUP:PROC,ERR_RET:PROC

		EXTERNDEF	GRP_ERR:ABS


GRPDEF		PROC
		;
		;DS:SI OF COURSE IS GRPDEF RECORD POINTER...
		;
		;FIRST IS GROUP INDEX, FOLLOWED BY MULTIPLE DESCRIPTORS
		;
		NEXT_INDEX	L1	;IN AX

		MOV	GROUP_NAME_LINDEX,EAX
		MOV	BUFFER_OFFSET,ESI

		CALL	GET_GROUP	;EAX IS GROUP_MINDEX, ECX IS PHYS
		MOV	EDI,EAX		;SAVE MASTER INDEX
		MOV	BL,[ECX].GROUP_STRUCT._G_TYPE

		INSTALL_GINDEX_LINDEX	GROUP_LARRAY

		AND	BL,MASK SEG_RELOC + MASK SEG_ASEG
		JMP	OBJ_CHECK

		DOLONG	L1
		DOLONG	L2

SEG_LOOP:
		MOV	AL,[ESI]
		INC	ESI
		CMP	AL,-1
		MOV	BUFFER_OFFSET,ESI
		JNZ	PHASE1		;SKIP FF
		NEXT_INDEX	L2
		;CMP	EAX,16K
		;JA	GRPDEF_MVIRDEF
GRPDEF_NVIRDEF:
		CONVERT_LINDEX_EAX_EAX	SEGMOD_LARRAY,EDX
GRPDEF_NORMAL:
		MOV	EDX,FLAT_GINDEX
		MOV	CL,BL
		CMP	EDI,EDX
		JZ	GRPDEF_SKIP_FLAT
		MOV	EDX,EDI
		CALL	PUT_SM_IN_GROUP		;EDX=GROUP_MINDEX, ECX=G_TYPE, EAX=SEGMOD_MINDEX
GRPDEF_SKIP_FLAT:

OBJ_CHECK:
		CMP	END_OF_RECORD,ESI
		JA	SEG_LOOP
		JNE	PHASE
		RET

PHASE:		CALL	OBJ_PHASE
		RET

PHASE1:
		MOV	AL,GRP_ERR
		CALL	ERR_RET
		RET

GRPDEF_MVIRDEF:
		PUSH	EAX
		CONVERT_MYCOMDAT_EAX_ECX
		POP	EAX
		JC	GRPDEF_NVIRDEF
		MOV	EAX,[ECX].MYCOMDAT_STRUCT._MCD_SEGMOD_GINDEX
		JMP	GRPDEF_NORMAL

GRPDEF		ENDP

		END

