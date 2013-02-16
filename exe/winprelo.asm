		TITLE	WINPRELO - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SEGMENTS
		INCLUDE	RELOCSS
		INCLUDE	SEGMSYMS

if	fg_segm

		PUBLIC	WINPACK_RELOC_FLUSH


		.DATA

		EXTERNDEF	TEMP_RECORD:BYTE

		EXTERNDEF	RELOC_COUNT:DWORD,MOVABLE_MASK:DWORD,LAST_SEG_OS2_NUMBER:DWORD,RELOC_HIGH_WATER:DWORD,EXETABLE:DWORD
		EXTERNDEF	RELOC_BITS:DWORD,LIDATA_RELOCS_NEXT:DWORD,OLD_HIGH_WATER:DWORD,HIGH_WATER:DWORD,NEW_REPT_ADDR:DWORD
		EXTERNDEF	FINAL_HIGH_WATER:DWORD,EXEPACK_SEGMENT_START:DWORD,FIRST_RELOC_GINDEX:DWORD,LAST_RELOC_GINDEX:DWORD
		EXTERNDEF	LIDATA_RELOCS_START:DWORD,LIDATA_RELOCS_NEXT:DWORD

		EXTERNDEF	RELOC_STUFF:ALLOCS_STRUCT,RELOC_GARRAY:STD_PTR_S,SEGMENT_TABLE:SEGTBL_STRUCT


		.CODE	PASS2_TEXT

		EXTERNDEF	SEARCH_ENTRY:PROC,ERR_RET:PROC,_release_minidata:proc,RELEASE_BLOCK:PROC,RELEASE_EAX_BUFFER:PROC
		EXTERNDEF	MOVE_EAX_TO_FINAL_HIGH_WATER:PROC,RELEASE_SEGMENT:PROC,RELEASE_GARRAY:PROC,QUICK_RELOCS:PROC

		EXTERNDEF	RC_64K_ERR:ABS


CURN_BYTE_0	EQU	TEMP_RECORD
CURN_BYTE_1	EQU	(TEMP_RECORD+1)
CURN_WORD_2	EQU	(WPTR TEMP_RECORD+2)


WINPACK_RELOC_FLUSH PROC
		;
		;IF THERE IS ANY RELOCATION INFORMATION, SET BIT IN SEGMENT
		;TABLE AND THEN WRITE THE STUFF OUT.. RELEASE ALL INFO
		;
		PUSHM	EDI,ESI,EBX
		MOV	EAX,RELOC_COUNT		;# OF RELOCS THIS SEGMENT

		TEST	EAX,EAX
		JZ	L9$

		MOV	EAX,OFF EXETABLE
		CALL	QUICK_RELOCS		;SORT PLEASE

		CALL	TBLINIT

		XOR	EAX,EAX
		MOV	EDI,OFF TEMP_RECORD

		MOV	RELOC_BYTES,EAX
		MOV	AL,-1

		STOSB
RELOC_NEXT:
		CALL	TBLNEXT

		JZ	RELOC_END
		;
		;GET RELOC
		;
		CONVERT	EAX,EAX,RELOC_GARRAY
		ASSUME	EAX:PTR RELOC_STRUCT

		MOV	ESI,[EAX]._RL_TARG_OFFSET
		MOV	ECX,[EAX]._RL_SEG_OFFSET

		MOV	EDX,[EAX]._RL_OS2_NUMBER
		MOV	EAX,[EAX]._RL_FLAGS

		CMP	EAX,0802H		;BASE, NOT ADDITIVE, IGNORE MOVEABILITY, INTERNAL
		JZ	RELO_INT_BASE

		MOV	EBX,OFF RELO_TO_NEW
		MOV	ITEM_FLAGS,EAX

		XLAT	[RELO_TO_NEW]

		AND	EAX,703H

		TEST	EAX,400H
		JZ	L1$

		AND	AH,3

		OR	AL,4
L1$:
		MOV	BL,AH

		SHL	AL,5
		AND	EBX,0FFH

		SHR	EAX,5

		CMP	AL,CURN_BYTE_0

		JMP	WINP_RELO_TBL[EBX*4]


RELO_INT_BASE:
		MOV	EAX,0F0H
		MOV	BL,CURN_BYTE_0

		CMP	BL,AL
		JNZ	RIB_1

		INC	CURN_BYTE_1
		JNZ	RIB_2

		DEC	CURN_BYTE_1
RIB_1:
		CALL	FLUSH_CURRENT
RIB_2:
		MOV	[EDI],DL		;TARGET SEGMENT #

		MOV	[EDI+1],CL

		MOV	[EDI+2],CH		;SEG_OFFSET
		ADD	EDI,3

		JMP	RELOC_NEXT

RELO_OSF::
		;
		;
		;
		MOV	AH,BPTR CURN_WORD_2
		JNZ	ROS_1

		CMP	AH,DL			;DOES OS# MATCH?
		JNZ	ROS_1

		INC	CURN_BYTE_1		;CAN I FIT ONE MORE IN PACKET?
		JNZ	ROS_2

		DEC	CURN_BYTE_1
ROS_1:
		CALL	FLUSH_CURRENT

		MOV	[EDI],DX
		ADD	EDI,2			;MOV	CURN_WORD_2,DX
ROS_2:
		;
		;JUST STORE OFFSET
		;
		MOV	[EDI],CX
		ADD	EDI,2

		JMP	RELOC_NEXT

RELO_ORD::
RELO_NAM::
		;
		;IMPORT BY ORDINAL
		;
		CONVERT	EDX,EDX,IMPMOD_GARRAY
		ASSUME	EDX:PTR IMPMOD_STRUCT

		MOV	EDX,[EDX]._IMPM_NUMBER
		JNZ	RORD_1

		CMP	CURN_WORD_2,DX		;DOES MODULE # MATCH?		
		JNZ	RORD_1

		INC	CURN_BYTE_1		;CAN I FIT ONE MORE IN PACKET
		JNZ	RORD_2

		DEC	CURN_BYTE_1
RORD_1:
		CALL	FLUSH_CURRENT

		MOV	[EDI],DX
		ADD	EDI,2
RORD_2:
		;
		;STORE OFFSET, FOLLOWED BY ORDINAL #
		;
		MOV	[EDI],CX
		MOV	EAX,ESI

		MOV	[EDI+2],AX
		ADD	EDI,4

		JMP	RELOC_NEXT

RELO_INT::
		;
		;FIRST, DEFINE THIS GUY
		;
		;ESI IS TARGET OFFSET
		;EDX IS TARGET SEGMENT
		;ECX IS OFFSET TO BE MODIFIED
		;AL IS FLAGS AS WE KNOW THEM
		;
		PUSHFD				;SAVE FLUSH COMMAND TILL I GET SEGMENT

		MOV	EBX,ITEM_FLAGS
		GETT	AH,ENTRIES_POSSIBLE

		AND	BH,8			;IGNORE MOVEABILITY?
		JNZ	RI_2

		OR	AH,AH
		JZ	RI_2

		PUSH	EAX
		MOV	EAX,EDX

		PUSH	ECX
		CONV_EAX_SEGTBL_ECX		;MOVABLE

		MOV	EAX,MOVABLE_MASK
		MOV	ECX,[ECX]._SEGTBL_FLAGS

		AND	EAX,ECX
		JZ	RI_1
		;
		;PROBABLE ENTRY-POINT REFERENCE
		;
		TEST	EAX,MASK SR_MOVABLE+MASK SR_DISCARD
		JNZ	RI_12

		AND	ECX,MASK SR_CONF+1
		JNZ	RI_1
RI_12:
		;
		;ENTRY-POINT REFERENCE...
		;

		;
		;NOW LOOK UP ENTRY POINT IN ENTRY TABLE TO GET ORD NUMBER
		;
		MOV	EAX,ESI
		CALL	SEARCH_ENTRY	;DL:EAX IS ITEM TO SEARCH FOR

		MOV	ESI,EAX
		MOV	EDX,0FFH

		POPM	ECX,EAX

		JNC	RI_19

		MOV	AL,0
		CALL	ERR_RET

		JMP	RI_19


RI_1:
		POPM	ECX,EAX
RI_19:

RI_2:
		POPFD				;AX IS SEGNUM, BX IS TARG OFF, DL IS FLAGS

		MOV	AH,BPTR CURN_WORD_2
		JNZ	RI_3

		CMP	AH,DL			;DOES SEGMENT # MATCH?
		JNZ	RI_3

		INC	CURN_BYTE_1		;CAN I FIT ONE MORE IN PACKET?
		JNZ	RI_4

		DEC	CURN_BYTE_1
RI_3:
		CALL	FLUSH_CURRENT		;RESETS DI

		MOV	[EDI],DL
		INC	EDI
RI_4:
		MOV	[EDI],CX

		MOV	[EDI+2],SI
		ADD	EDI,4

		JMP	RELOC_NEXT

RELOC_END:
		CALL	FLUSH_CURRENT		;FLUSH TEMP_RECORD
		;
		;RELEASE RELOC SPACE
		;
		MOV	EAX,OFF RELOC_STUFF
		push	EAX
		call	_release_minidata
		add	ESP,4

		MOV	EAX,OFF RELOC_GARRAY
		CALL	RELEASE_GARRAY

		XOR	EAX,EAX

		MOV	RELOC_STUFF.ALLO_HASH_TABLE_PTR,EAX
		MOV	RELOC_COUNT,EAX

		MOV	RELOC_HIGH_WATER,EAX
		MOV	LIDATA_RELOCS_NEXT,EAX

		MOV	FIRST_RELOC_GINDEX,EAX
		MOV	LAST_RELOC_GINDEX,EAX

		XCHG	RELOC_BITS,EAX

		CALL	RELEASE_BLOCK

		XOR	EAX,EAX

		XCHG	LIDATA_RELOCS_START,EAX

if	page_size EQ 8K

		OR	EAX,EAX
		JZ	L85$

		CALL	RELEASE_BLOCK
L85$:
endif

		MOV	EAX,OFF EXETABLE
		CALL	RELEASE_EAX_BUFFER

		MOV	EAX,LAST_SEG_OS2_NUMBER

		CONV_EAX_SEGTBL_ECX

		MOV	EAX,RELOC_BYTES
		MOV	EDX,[ECX]._SEGTBL_PSIZE

		ADD	EAX,EDX
		GETT	DL,RC_PRELOADS

		MOV	[ECX]._SEGTBL_PSIZE,EAX

		CMP	EAX,64K
		JAE	L99$

		OR	DL,DL
		JZ	L91$

		MOV	EAX,FINAL_HIGH_WATER		;MAKE SURE PRELOADED SEGMENT + RELOCS
		MOV	EDX,EXEPACK_SEGMENT_START	;IS NOT >= 64K

		SUB	EAX,EDX

		CMP	EAX,64K
		JAE	L99$
L91$:
L9$:
		XOR	EAX,EAX
		POPM	EBX,ESI,EDI

		MOV	OLD_HIGH_WATER,EAX
		MOV	HIGH_WATER,EAX

		MOV	NEW_REPT_ADDR,EAX

		RET

L99$:
		MOV	AX,RC_64K_ERR
		CALL	ERR_RET

		JMP	L91$

WINPACK_RELOC_FLUSH ENDP


FLUSH_CURRENT	PROC	NEAR
		;
		;
		;
		PUSH	ECX
		MOV	ECX,EDI

		PUSH	EAX
		MOV	EAX,OFF TEMP_RECORD

		PUSH	EDX
		SUB	ECX,EAX

		CMP	ECX,5
		JB	L9$

		ADD	RELOC_BYTES,ECX
		GETT	DL,WINPACK_SELECTED		;PROBABLY YES, UNLESS SEGPACK

		OR	DL,DL
		JZ	L5$

		BITT	WINPACK_LICENSED
		JNZ	L5$

		XOR	WPTR [EAX],-1			;CRUNCH THIS...
L5$:
		CALL	MOVE_EAX_TO_FINAL_HIGH_WATER
L9$:
		POPM	EDX,EAX

		MOV	EDI,OFF TEMP_RECORD
		MOV	AH,1

		STOSW

		POP	ECX

		RET

FLUSH_CURRENT	ENDP

endif


TBLINIT		PROC	PRIVATE

		MOV	ECX,OFF EXETABLE+8	;TABLE OF BLOCKS OF INDEXES
		MOV	EAX,EXETABLE+4		;FIRST BLOCK

		MOV	WM_BLK_PTR,ECX		;POINTER TO NEXT BLOCK

		TEST	EAX,EAX
		JZ	L9$
		;
		MOV	ECX,PAGE_SIZE/4
		MOV	WM_PTR,EAX		;PHYSICAL POINTER TO NEXT INDEX TO PICK

		MOV	WM_CNT,ECX
		OR	AL,1
L9$:
		RET

TBLINIT 	ENDP


TBLNEXT		PROC	NEAR	PRIVATE
		;
		;GET NEXT SYMBOL INDEX IN AX, DS:SI POINTS
		;
		MOV	EDX,WM_CNT
		MOV	ECX,WM_PTR

		DEC	EDX			;LAST ONE?
		JZ	L5$

		MOV	EAX,DPTR [ECX]		;NEXT INDEX
		ADD	ECX,4

		TEST	EAX,EAX
		JZ	L9$

		MOV	WM_PTR,ECX		;UPDATE POINTER
		MOV	WM_CNT,EDX		;UPDATE COUNTER

L9$:
		RET

L5$:
		;
		;NEXT BLOCK
		;
		MOV	EAX,DPTR [ECX]
		MOV	ECX,WM_BLK_PTR

		MOV	WM_CNT,PAGE_SIZE/4

		MOV	EDX,DPTR [ECX]
		ADD	ECX,4

		MOV	WM_PTR,EDX
		MOV	WM_BLK_PTR,ECX

		TEST	EAX,EAX

		RET


TBLNEXT 	ENDP


		.DATA

		ALIGN	4

WINP_RELO_TBL	LABEL	DWORD

		DD	RELO_INT		;INTERNAL
		DD	RELO_ORD		;IMPORT BY ORDINAL
		DD	RELO_NAM		;IMPORT BY NAME
		DD	RELO_OSF		;FLOAT


RELO_TO_NEW	LABEL	BYTE

		DB	0			;LOBYTE
		DB	-1			;ERROR
		DB	1			;BASE
		DB	2			;PTR
		DB	-1			;ERROR
		DB	3			;OFFSET
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR
		DB	-1			;ERROR


		.DATA?

RELOC_BYTES	DD	?
ITEM_FLAGS	DD	?
WM_PTR		DD	?
WM_CNT		DD	?
WM_BLK_PTR	DD	?


		END

