		TITLE	GTNXTU - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS

		PUBLIC	GTNXTU


		.CODE	PHASE1_TEXT

GTNXTU		PROC
		;
		;
		;
		MOV	AL,[EBX]
		INC	EBX
		CMP	AL,'a'
		JC	L1$
		CMP	AL,'z'+1
		JNC	L1$
		SUB	AL,20H
L1$:
		RET

GTNXTU		ENDP

		END

