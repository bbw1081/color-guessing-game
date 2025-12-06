;            Exercise 12 - Game
;****************************************************************
;Assembly functions needed to run the game, main is contained in the
;C file.
;Name:  Richard Bradley Wilkinson & Frank Zou
;Date:  December 3, 2024
;Class:  CMPE-250
;Section:  Lab02
;---------------------------------------------------------------
;Keil Template for KL05 Assembly with Keil C startup
;R. W. Melton
;November 3, 2020
;****************************************************************
;Assembler directives
            THUMB
            GBLL  MIXED_ASM_C
MIXED_ASM_C SETL  {TRUE}
            OPT   64  ;Turn on listing macro expansions
;****************************************************************
;Include files
            GET  MKL05Z4.s
            OPT  1          ;Turn on listing
;****************************************************************
;EQUates
;Characters
BS          EQU  0x08
CR          EQU  0x0D
DEL         EQU  0x7F
ESC         EQU  0x1B
LF          EQU  0x0A
NULL        EQU  0x00
;---------------------------------------------------------------
;DAC0
DAC0_BITS   EQU   12
DAC0_STEPS  EQU   4096
DAC0_0V     EQU   0x00
;---------------------------------------------------------------
;Servo
SERVO_POSITIONS  EQU  5
;---------------------------------------------------------------
PWM_FREQ          EQU  50
;TPM_SOURCE_FREQ  EQU  48000000
TPM_SOURCE_FREQ   EQU  47972352
TPM_SC_PS_VAL     EQU  4
;PWM_PERIOD       EQU  ((TPM_SOURCE_FREQ / (1 << TPM_SC_PS_VAL)) / \
;                       PWM_FREQ)
;PWM_DUTY_5       EQU  (PWM_PERIOD / 20)  ;  5% duty cycle
;PWM_DUTY_10      EQU  (PWM_PERIOD / 10)  ; 10% duty cycle
PWM_PERIOD        EQU  60000
PWM_DUTY_10       EQU  6000
PWM_DUTY_5        EQU  3000
;---------------------------------------------------------------
;Number output characteristics
MAX_WORD_DECIMAL_DIGITS  EQU  10
;---------------------------------------------------------------
; Queue management record field offsets
IN_PTR      EQU   0
OUT_PTR     EQU   4
BUF_STRT    EQU   8
BUF_PAST    EQU   12
BUF_SIZE    EQU   16
NUM_ENQD    EQU   17
; Queue structure sizes
XQ_BUF_SZ   EQU   80  ;Xmit queue contents
Q_REC_SZ    EQU   18  ;Queue management record
;---------------------------------------------------------------
;NVIC_ICER
;31-00:CLRENA=masks for HW IRQ sources;
;             read:   0 = unmasked;   1 = masked
;             write:  0 = no effect;  1 = mask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ICER_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ICER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_ICPR
;31-00:CLRPEND=pending status for HW IRQ sources;
;             read:   0 = not pending;  1 = pending
;             write:  0 = no effect;
;                     1 = change status to not pending
;22:PIT IRQ pending status
;12:UART0 IRQ pending status
NVIC_ICPR_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ICPR_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;NVIC_IPR0-NVIC_IPR7
;2-bit priority:  00 = highest; 11 = lowest
;--PIT--------------------
PIT_IRQ_PRIORITY    EQU  0
NVIC_IPR_PIT_MASK   EQU  (3 << PIT_PRI_POS)
NVIC_IPR_PIT_PRI_0  EQU  (PIT_IRQ_PRIORITY << PIT_PRI_POS)
;--UART0--------------------
UART0_IRQ_PRIORITY    EQU  3
NVIC_IPR_UART0_MASK   EQU (3 << UART0_PRI_POS)
NVIC_IPR_UART0_PRI_3  EQU (UART0_IRQ_PRIORITY << UART0_PRI_POS)
;---------------------------------------------------------------
;NVIC_ISER
;31-00:SETENA=masks for HW IRQ sources;
;             read:   0 = masked;     1 = unmasked
;             write:  0 = no effect;  1 = unmask
;22:PIT IRQ mask
;12:UART0 IRQ mask
NVIC_ISER_PIT_MASK    EQU  PIT_IRQ_MASK
NVIC_ISER_UART0_MASK  EQU  UART0_IRQ_MASK
;---------------------------------------------------------------
;PIT_LDVALn:  PIT load value register n
;31-00:TSV=timer start value (period in clock cycles - 1)
;Clock ticks for 0.01 s at ~24 MHz count rate
;0.01 s * ~24,000,000 Hz = ~240,000
;TSV = ~240,000 - 1
;Clock ticks for 0.01 s at 23,986,176 Hz count rate
;0.01 s * 23,986,176 Hz = 239,862
;TSV = 239,862 - 1
PIT_LDVAL_10ms  EQU  239861
;---------------------------------------------------------------
;PIT_MCR:  PIT module control register
;1-->    0:FRZ=freeze (continue'/stop in debug mode)
;0-->    1:MDIS=module disable (PIT section)
;               RTI timer not affected
;               must be enabled before any other PIT setup
PIT_MCR_EN_FRZ  EQU  PIT_MCR_FRZ_MASK
;---------------------------------------------------------------
;PIT_TCTRL:  timer control register
;0-->   2:CHN=chain mode (enable)
;1-->   1:TIE=timer interrupt enable
;1-->   0:TEN=timer enable
PIT_TCTRL_CH_IE  EQU  (PIT_TCTRL_TEN_MASK :OR: PIT_TCTRL_TIE_MASK)
;---------------------------------------------------------------
;PORTx_PCRn (Port x pin control register n [for pin n])
;___->10-08:Pin mux control (select 0 to 8)
;Use provided PORT_PCR_MUX_SELECT_2_MASK
;---------------------------------------------------------------
;Port B
PORT_PCR_SET_PTB2_UART0_RX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
PORT_PCR_SET_PTB1_UART0_TX  EQU  (PORT_PCR_ISF_MASK :OR: \
                                  PORT_PCR_MUX_SELECT_2_MASK)
;---------------------------------------------------------------
;SIM_SCGC4
;1->10:UART0 clock gate control (enabled)
;Use provided SIM_SCGC4_UART0_MASK
;---------------------------------------------------------------
;SIM_SCGC5
;1->09:Port B clock gate control (enabled)
;Use provided SIM_SCGC5_PORTB_MASK
;---------------------------------------------------------------
;SIM_SCGC6
;1->23:PIT clock gate control (enabled)
;Use provided SIM_SCGC6_PIT_MASK
;---------------------------------------------------------------
;SIM_SOPT2
;01=27-26:UART0SRC=UART0 clock source select (MCGFLLCLK)
;---------------------------------------------------------------
SIM_SOPT2_UART0SRC_MCGFLLCLK  EQU  \
                                 (1 << SIM_SOPT2_UART0SRC_SHIFT)
;---------------------------------------------------------------
;SIM_SOPT5
; 0->   16:UART0 open drain enable (disabled)
; 0->   02:UART0 receive data select (UART0_RX)
;00->01-00:UART0 transmit data select source (UART0_TX)
SIM_SOPT5_UART0_EXTERN_MASK_CLEAR  EQU  \
                               (SIM_SOPT5_UART0ODE_MASK :OR: \
                                SIM_SOPT5_UART0RXSRC_MASK :OR: \
                                SIM_SOPT5_UART0TXSRC_MASK)
;---------------------------------------------------------------
;UART0_BDH
;    0->  7:LIN break detect IE (disabled)
;    0->  6:RxD input active edge IE (disabled)
;    0->  5:Stop bit number select (1)
;00001->4-0:SBR[12:0] (UART0CLK / [9600 * (OSR + 1)]) 
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDH_9600  EQU  0x01
;---------------------------------------------------------------
;UART0_BDL
;26->7-0:SBR[7:0] (UART0CLK / [9600 * (OSR + 1)])
;UART0CLK is MCGPLLCLK/2
;MCGPLLCLK is 96 MHz
;MCGPLLCLK/2 is 48 MHz
;SBR = 48 MHz / (9600 * 16) = 312.5 --> 312 = 0x138
UART0_BDL_9600  EQU  0x38
;---------------------------------------------------------------
;UART0_C1
;0-->7:LOOPS=loops select (normal)
;0-->6:DOZEEN=doze enable (disabled)
;0-->5:RSRC=receiver source select (internal--no effect LOOPS=0)
;0-->4:M=9- or 8-bit mode select 
;        (1 start, 8 data [lsb first], 1 stop)
;0-->3:WAKE=receiver wakeup method select (idle)
;0-->2:IDLE=idle line type select (idle begins after start bit)
;0-->1:PE=parity enable (disabled)
;0-->0:PT=parity type (even parity--no effect PE=0)
UART0_C1_8N1  EQU  0x00
;---------------------------------------------------------------
;UART0_C2
;0-->7:TIE=transmit IE for TDRE (disabled)
;0-->6:TCIE=transmission complete IE for TC (disabled)
;0-->5:RIE=receiver IE for RDRF (disabled)
;0-->4:ILIE=idle line IE for IDLE (disabled)
;1-->3:TE=transmitter enable (enabled)
;1-->2:RE=receiver enable (enabled)
;0-->1:RWU=receiver wakeup control (normal)
;0-->0:SBK=send break (disabled, normal)
UART0_C2_T_R    EQU  (UART0_C2_TE_MASK :OR: UART0_C2_RE_MASK)
UART0_C2_T_RI   EQU  (UART0_C2_RIE_MASK :OR: UART0_C2_T_R)
UART0_C2_TI_RI  EQU  (UART0_C2_TIE_MASK :OR: UART0_C2_T_RI)
;---------------------------------------------------------------
;UART0_C3
;0-->7:R8T9=9th data bit for receiver (not used M=0)
;           10th data bit for transmitter (not used M10=0)
;0-->6:R9T8=9th data bit for transmitter (not used M=0)
;           10th data bit for receiver (not used M10=0)
;0-->5:TXDIR=UART_TX pin direction in single-wire mode
;            (no effect LOOPS=0)
;0-->4:TXINV=transmit data inversion (not inverted)
;0-->3:ORIE=overrun IE for OR (disabled)
;0-->2:NEIE=noise error IE for NF (disabled)
;0-->1:FEIE=framing error IE for FE (disabled)
;0-->0:PEIE=parity error IE for PF (disabled)
UART0_C3_NO_TXINV  EQU  0x00
;---------------------------------------------------------------
;UART0_C4
;    0-->  7:MAEN1=match address mode enable 1 (disabled)
;    0-->  6:MAEN2=match address mode enable 2 (disabled)
;    0-->  5:M10=10-bit mode select (not selected)
;01111-->4-0:OSR=over sampling ratio (16)
;               = 1 + OSR for 3 <= OSR <= 31
;               = 16 for 0 <= OSR <= 2 (invalid values)
UART0_C4_OSR_16           EQU  0x0F
UART0_C4_NO_MATCH_OSR_16  EQU  UART0_C4_OSR_16
;---------------------------------------------------------------
;UART0_C5
;  0-->  7:TDMAE=transmitter DMA enable (disabled)
;  0-->  6:Reserved; read-only; always 0
;  0-->  5:RDMAE=receiver full DMA enable (disabled)
;000-->4-2:Reserved; read-only; always 0
;  0-->  1:BOTHEDGE=both edge sampling (rising edge only)
;  0-->  0:RESYNCDIS=resynchronization disable (enabled)
UART0_C5_NO_DMA_SSR_SYNC  EQU  0x00
;---------------------------------------------------------------
;UART0_S1
;0-->7:TDRE=transmit data register empty flag; read-only
;0-->6:TC=transmission complete flag; read-only
;0-->5:RDRF=receive data register full flag; read-only
;1-->4:IDLE=idle line flag; write 1 to clear (clear)
;1-->3:OR=receiver overrun flag; write 1 to clear (clear)
;1-->2:NF=noise flag; write 1 to clear (clear)
;1-->1:FE=framing error flag; write 1 to clear (clear)
;1-->0:PF=parity error flag; write 1 to clear (clear)
UART0_S1_CLEAR_FLAGS  EQU  (UART0_S1_IDLE_MASK :OR: \
                            UART0_S1_OR_MASK :OR: \
                            UART0_S1_NF_MASK :OR: \
                            UART0_S1_FE_MASK :OR: \
                            UART0_S1_PF_MASK)
;---------------------------------------------------------------
;UART0_S2
;1-->7:LBKDIF=LIN break detect interrupt flag (clear)
;             write 1 to clear
;1-->6:RXEDGIF=RxD pin active edge interrupt flag (clear)
;              write 1 to clear
;0-->5:(reserved); read-only; always 0
;0-->4:RXINV=receive data inversion (disabled)
;0-->3:RWUID=receive wake-up idle detect
;0-->2:BRK13=break character generation length (10)
;0-->1:LBKDE=LIN break detect enable (disabled)
;0-->0:RAF=receiver active flag; read-only
UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS  EQU  \
        (UART0_S2_LBKDIF_MASK :OR: UART0_S2_RXEDGIF_MASK)
		
; Queue structure sizes
Q_BUF_SZ    EQU   4   ;Queue buffer contents
Q_BUF_SZ_TXRX EQU	80
; Queue delimiters for printed output
Q_BEGIN_CH  EQU   '>'
Q_END_CH    EQU   '<'
MAX_STR		EQU	 100
	
TAB			EQU	 0x09
;---------------------------------------------------------------
;****************************************************************
;MACROs
;---------------------------------------------------------------
		;creates a new line using a carriage return and a line feed character
		MACRO
		NEWLINE
		PUSH	{R0}
		MOVS	R0,#CR
		BL		PutChar
		MOVS	R0,#LF
		BL		PutChar
		POP		{R0}
		MEND
;---------------------------------------------------------------		
		;sets the C flag to the input value (1 or 0)
		MACRO
		SETC	$VALUE
		PUSH	{R0}
		MOVS	R0, $VALUE
		LSRS	R0, R0, #1
		POP		{R0}
		MEND
;---------------------------------------------------------------		
		;used to put the character from a command to the terminal followed by a colon and a tab	
		;INPUT: The character value to print to the terminal
		MACRO
		CMND_PUT	$VALUE
		PUSH	{R0}
		MOVS	R0,$VALUE
		BL		PutChar
		MOVS	R0,#':'
		BL		PutChar
		MOVS	R0,#0x9
		BL		PutChar
		POP		{R0}
		MEND
;---------------------------------------------------------------
;****************************************************************
;Program
;C source will contain main ()
;Only subroutines and ISRs in this assembly source
            AREA    MyCode,CODE,READONLY
			IMPORT DIVU
			EXPORT GetChar
			EXPORT GetStringSB
			EXPORT Init_UART0_IRQ
			EXPORT PutChar
			EXPORT PutNumHex
			EXPORT PutNumUB
			EXPORT PutStringSB
			EXPORT UART0_IRQHandler
			EXPORT ReturnCount
			EXPORT ClearCount
			EXPORT CheckRxQueue
			EXPORT PIT_IRQHandler
			EXPORT Init_PIT_IRQ
;>>>>> begin subroutine code <<<<<
ReturnCount		PROC	{R1-R14}
;*********************************************
; returns the current count of the timer
; NO INPUTS
; OUTPUTS: R0 - current count
;*********************************************
		LDR		R0,=TimerVar
		LDR		R0,[R0, #0]
		BX		LR
                  ENDP
		
ClearCount		PROC	{R0-R14}
;*********************************************
;clears the count of the timer
;NO INPUTS
;NO OUTPUTS
;*********************************************
		PUSH	{R0,R1}
		LDR      R0,=TimerVar
		MOVS	R1,#0
		STR	R1,[R0,#0]
		POP	{R0,R1}
		BX	LR
                  ENDP
		
CheckRxQueue	PROC	{R1-R14}
;*********************************************
;returns the number of values enqueued into the RXQueue
;NO INPUTS
;OUTPUT: R0 - boolean value whether there is a value(s) in the RXQueue
;*********************************************
		PUSH	{R1}
		LDR		R1,=RxQueue
		LDRB	R1,[R1,#NUM_ENQD]
		CMP		R1,#0
		BEQ		CheckRxQueueFalse
		MOVS	R0,#1
		B		CheckRxQueueEnd
CheckRxQueueFalse
		MOVS	R0, #0
CheckRxQueueEnd
		POP		{R1}
		BX		LR
	ENDP


PIT_IRQHandler		PROC	{R0-R14}
;*********************************************
;increments the counter if the stopwatch is enabled,
;otherwise just skips. Always clears the timer at the end
;No inputs or outputs
;MODIFY: APSR
;no other registers modified upon return
;*********************************************
		CPSID	I					;mask interrupts
		PUSH	{R0-R1}				;push used registers
		;increment the count by one
		LDR		R1,=TimerVar
		LDR		R0,[R1,#0]
		ADDS	R0,R0,#1
		STR		R0,[R1,#0]
		;clear the interrupt condition
		LDR	R0,=PIT_TFLG0		
		LDR	R1,=PIT_TFLG_TIF_MASK
		STR	R1,[R0,#0]
		POP	{R0-R1}					;restore used registers
		CPSIE	I					;unmask interrupts
		BX	LR						;return
	ENDP

Init_PIT_IRQ		PROC	{R0-R14}
;********************************************************
;initilaize the timer driver interrupt
;No inputs/outputs
;MODIFY: APSR
;no other registers are changed upon return
;********************************************************
			PUSH	{R0-R3}
			;Enable clock for PIT module
			LDR	R0,=SIM_SCGC6
			LDR	R1,=SIM_SCGC6_PIT_MASK
			LDR	R2,[R0,#0]
			ORRS	R2,R2,R1
			STR	R2,[R0,#0]
			;disable PIT timer 0
			LDR	R0,=PIT_CH0_BASE
			LDR	R1,=PIT_TCTRL_TEN_MASK
			LDR	R2,[R0,#PIT_TCTRL_OFFSET]
			BICS	R2,R2,R1
			STR	R2,[R0,#PIT_TCTRL_OFFSET]
			;set PIT interrupt priority
			LDR	R0,=PIT_IPR
			LDR	R1,=NVIC_IPR_PIT_MASK
			LDR	R3,[R0,#0]
			BICS	R3,R3,R1
			STR	R3,[R0,#0]
			;clear pending interrupts
			LDR	R0,=NVIC_ICPR
			LDR	R1,=NVIC_ICPR_PIT_MASK
			STR	R1,[R0,#0]
			;Unmask PIT interrupts
			LDR	R0,=NVIC_ISER
			LDR	R1,=NVIC_ISER_PIT_MASK
			STR	R1,[R0,#0]
			;enable PIT module
			LDR	R0,=PIT_BASE
			LDR	R1,=PIT_MCR_EN_FRZ
			STR	R1,[R0,#PIT_MCR_OFFSET]
			;set pit timer 0 for period 0.01s
			LDR	R0,=PIT_CH0_BASE
			LDR	R1,=PIT_LDVAL_10ms
			STR	R1,[R0,#PIT_LDVAL_OFFSET]
			;enable pit timer 0 for interrupts
			LDR	R1,=PIT_TCTRL_CH_IE
			STR	R1,[R0,#PIT_TCTRL_OFFSET]

			POP	{R0-R3}
			BX	LR
		ENDP

InitQueue	PROC	{R0-R14}
;*******************************************************************************
;Initializes the queue from the input registers
;Input:	R0 - starting address for queue buffer
;		R1 - starting address for queue record structure
;		R2 - the size of the queue
;Output: NONE
;Modify: APSR
;All other registers remain unchanged upon return
;*******************************************************************************
			PUSH		{R3}							;push registers onto stack
			STR			R0, [R1, #IN_PTR]				;set in-pointer which is the beginning of the buffer
			STR			R0, [R1, #OUT_PTR]				;set out pointer which is the beginning of the buffer
			STR			R0, [R1, #BUF_STRT]				;set buffer start to the beginning buffer address
			MOVS		R3, R0							;set R3 to the beginning address of the buffer
			ADDS		R3, R3, R2						;add the size of the buffer to R3
			ADDS		R3, R3, #1						;add one to that address to get the buffer past
			STR			R3, [R1, #BUF_PAST]				;store buffer past in memory
			STR			R2, [R1, #BUF_SIZE]				;store the size in R2 to buffer size
			MOVS		R3, #0							;set R3 to R0 to be used as num enqueued
			STRB		R3, [R1, #NUM_ENQD]				;set num enqd to 0
			POP			{R3}							;pop registers from stack
			BX			LR
	ENDP

Enqueue		PROC	{R0-R14}
;*******************************************************************************
;If the queue is not full (whose record address is in R1), enqueues the character
;from R0 to the queue and reports success by returning with the C flag cleared
;otherwise reports a failure by setting the C flag
;Input:	R0 - Character to enqueue
;	R1 - Address of queue record structure
;Output: PSR C flag - Success(0) or Failure(1)
;Modify: APSR
;All other registers remain unchanged on return
;*******************************************************************************
			PUSH		{R2-R3}							;save on stack any registers used
			LDRB		R2, [R1, #NUM_ENQD]		;load the number enqueued from the queue record into R2
			LDRB		R3, [R1, #BUF_SIZE]		;load the size of the queue buffer from the queue record into R3
			CMP			R2, R3			
			BHS			EnqueueNotQueue			;if queue not full
			LDR			R2, [R1, #IN_PTR]			;load the in pointer into R2
			STRB		R0, [R2, #0]					;put new element at memory location pointed by InPointer
			LDRB		R3, [R1, #NUM_ENQD]		;load the current number enqueued into R3
			ADDS		R3, R3, #1						;increment the number enqueued
			STRB		R3, [R1, #NUM_ENQD]		;store the number enqueued in the queue record
			ADDS		R2, R2, #1						;increment the in pointer by 1
			STR			R2, [R1, #IN_PTR]			;store the in pointer into the queue record
			LDR			R3, [R1, #BUF_PAST]		;load the address of buffer past into R3
			CMP			R2, R3			
			BLO			EnqueueClearC				;if InPointer is inside the queue buffer skip this next step
			LDR			R2, [R1, #BUF_STRT]		;load the beginning of the queue buffer into R2
			STR			R2, [R1, #IN_PTR]			;adjust InPointer to the beginning of the buffer
EnqueueClearC
			MRS			R2,APSR							;Clear the C flag to reflect success
			MOVS 		R3,#0x20
			LSLS		R3,R3,#24
			BICS 		R2,R2,R3
			MSR			APSR,R2
			B			EnqueueEnd
EnqueueNotQueue
			MRS 		R2,APSR							;Set the C flag to reflect failure
			MOVS 		R4,#0x20
			LSLS 		R3,R3,#24
			ORRS		R2,R2,R3
			MSR 		APSR,R2
EnqueueEnd
			POP			{R2-R3}							;restore registers from stack
			BX				LR
		ENDP

Dequeue		PROC		{R1-R14}
;*******************************************************************************
;If the queue is not empty, dequeues a character from the queue to R0 and reports
;success by returning with the C flag cleared, or reports failure by returning with
;the C flag set
;Input:	R1 - Address of queue record structure
;Output: R0 - Character Dequeued
;	 PSR C flag - Success(0) or Failure(1)
;Modify: R0, APSR
;All other registers remain unchanged on return
;*******************************************************************************
			PUSH			{R2-R3}							;save on stack any registers used (other than R0)
			LDRB			R2, [R1, #NUM_ENQD]	
			CMP				R2, #0			
			BEQ				DequeueFailure					;if queue is empty, if it isn't than continue
			LDR				R0, [R1, #OUT_PTR]				;get the address stored in out pointer
			LDRB			R0, [R0, #0]					;get the value at the out address' pointer
			SUBS			R2, R2, #1						;decrement number enqueued
			STRB			R2, [R1, #NUM_ENQD]				;store the new num enqueued in the queue record
			LDR				R2, [R1, #OUT_PTR]				;load the current out pointer into R2
			ADDS			R2, R2, #1						;increment the out pointer
			STR				R2, [R1, #OUT_PTR]				;store the new out pointer into the queue record
			LDR				R3, [R1, #BUF_PAST]				;load the address past the queue buffer into R3
			CMP				R2, R3			
			BLO				DequeueClearC					;if the pointer is inside the buffer skip this next step
			LDR				R2, [R1, #BUF_STRT]				;load the starting address of the queue buffer into R2
			STR				R2, [R1, #OUT_PTR]				;adjust out pointer to beginning of queue buffer
DequeueClearC	
			MRS				R2,APSR							;Clear the C flag to reflect success
			MOVS 			R3,#0x20
			LSLS 			R3,R3,#24
			BICS 			R2,R2,R3
			MSR				APSR,R2
			B				DequeueEnd
DequeueFailure
			MRS 			R2,APSR							;Set the C flag to reflect failure
			MOVS 			R4,#0x20
			LSLS 			R3,R3,#24
			ORRS			R2,R2,R3
			MSR 			APSR,R2		
DequeueEnd
			POP				{R2-R3}							;restore registers from stack
			BX				LR
		ENDP

PutNumHex	PROC		{R0-R14}
;*******************************************************************************
;Prints to the terminal screen the text hexadecimal representation of the 
;unsigned word value in R0
;Input:	R0 - an unsigned word value
;Output: NONE
;Modify: APSR
;All other registers remain unchanged on return
;*******************************************************************************
			PUSH		{R1-R3, LR}							;push all used registers onto the stack
			MOVS		R1, #28								;nibble counter
			MOVS		R2, #0xF							;nibble mask for the and operation
			MOVS		R3, R0								;save the original value in R0
PutNumHexLoop
			MOVS		R0, R3								;restore R0's original value after being changed
			LSRS		R0, R0, R1							;shift the nibble to the least significant nibble by the current pointer amount
			ANDS		R0, R0, R2							;AND the mask with the value in R0 to isolate the current bit
			CMP			R0,#0								;check if the nibble is a number value, if not then its a letter value and will be converted as such
			BLO			PutNumHexNotDigit
			CMP			R0,#9
			BHI			PutNumHexNotDigit
			ADDS		R0, R0, #'0'						;if the nibble is a number value convert it to the proper ASCII value of the number
			B			PutNumHexPrint
PutNumHexNotDigit
			ADDS		R0, R0, #0x37							;conver the nibble to the proper ASCII letter
PutNumHexPrint
			BL			PutChar								;print the character
			CMP			R1, #0								;check if the counter is equal to zero, if so end the loop
			BEQ			PutNumHexLoopEnd
			SUBS		R1, R1, #4							;if not decrment the counter and then loop
			B			PutNumHexLoop
PutNumHexLoopEnd
			MOVS		R0, R3								;restore the original value of R0
			POP			{R1-R3, PC}							;pop modified registers from stack
			BX			LR
		ENDP

PutNumUB	PROC
;*******************************************************************************
;Prints to the terminal screen the text decimal representation of the
;unsigned byte value in R0
;Input:	R0 - unsigned byte value
;Output: NONE
;Modify: APSR
;All other registers remain unchanged on return
;*******************************************************************************
			PUSH				{R1, LR}							;push all used registers onto stack
			MOVS				R1, #0xFF
			ANDS				R0, R0, R1							;mask off LSB
			BL					PutNumU								;call PutNumU
			POP					{R1, PC}							;pop registers from stack
			BX					LR
		ENDP
			
Init_UART0_IRQ		PROC	{R0-R14}
;*******************************************************************************
;Initializes UART0 for polled serial I/O at 9600 baud using a format of eight data bits,
;no parity, and one stop bit, along with initializing the UART0 interrupt service routine
;and it's components
;Input: NONE
;Output: NONE
;Modify: APSR
;*******************************************************************************
			PUSH	{LR, R0-R3}				;push modified registers onto stack
			
			;initialize the transmit queue
			LDR		R0, =TxBuffer
			LDR		R1, =TxQueue
			MOVS	R2, #Q_BUF_SZ_TXRX
			BL		InitQueue
			;initialize the receive queue
			LDR		R0, =RxBuffer
			LDR		R1, =RxQueue
			MOVS	R2, #Q_BUF_SZ_TXRX
			BL		InitQueue

			;Set SIM_SOPT2 for UART0 FLL CLK
			LDR 	R0,=SIM_SOPT2
			LDR 	R1,=SIM_SOPT2_UART0SRC_MASK
			LDR 	R3,[R0,#0]
			BICS 	R3,R3,R2
			LDR 	R2,=SIM_SOPT2_UART0SRC_MCGFLLCLK
			ORRS 	R3,R3,R2
			STR 	R3,[R0,#0]
			;Set SIM_SOPT5 for UART0 External
			LDR		R0, =SIM_SOPT5
			LDR		R1, =SIM_SOPT5_UART0_EXTERN_MASK_CLEAR
			LDR		R2, [R0, #0]
			BICS	R2, R2, R1
			STR		R2, [R0, #0]
			;Set SIM_SCGC4 for UART0 Clock Enabled
			LDR		R0, =SIM_SCGC4
			LDR		R1, =SIM_SCGC4_UART0_MASK
			LDR		R2, [R0, #0]
			ORRS	R2, R2, R1
			STR		R2, [R0, #0]
			;Set SIM_CGC5 for Port B Clock Enabled
			LDR		R0, =SIM_SCGC5
			LDR		R1, =SIM_SCGC5_PORTB_MASK
			LDR		R2, [R0, #0]
			ORRS	R2, R2, R1
			STR		R2, [R0, #0]
			;Set Pins for UART0 Rx and Tx
			LDR		R0, =PORTB_PCR2
			LDR		R1, =PORT_PCR_SET_PTB2_UART0_RX
			STR		R1, [R0, #0]
			LDR		R0, =PORTB_PCR1
			LDR		R1, =PORT_PCR_SET_PTB1_UART0_TX
			STR		R1, [R0, #0]
			;Load base address for UART0
			LDR		R0, =UART0_BASE
			;Disable UART0
			MOVS 	R1,#UART0_C2_T_R
			LDRB	R2,[R0,#UART0_C2_OFFSET]
			BICS 	R2,R2,R1
			STRB 	R2,[R0,#UART0_C2_OFFSET]
			;Set UART0_IRQ priority
			LDR	R0,=UART0_IPR
			;LDR	R1,	=NVIC_IPR_UART0_MASK
			LDR	R2, =NVIC_IPR_UART0_PRI_3
			LDR	R3,[R0,#0]
			;BICS	R3, R3, R1
			ORRS	R3,R3,R2
			STR	R3,[R0,#0]
			;clear pending interrupts
			LDR	R0,=NVIC_ICPR
			LDR	R1,=NVIC_ICPR_UART0_MASK
			STR	R1,[R0,#0]
			;unmask interrupts
			LDR	R0,=NVIC_ISER
			LDR	R1,=NVIC_ISER_UART0_MASK
			STR	R1,[R0,#0]
			;Set UART0 baud rate
			LDR		R0,=UART0_BASE
			MOVS 	R1,#UART0_BDH_9600
			STRB	R1,[R0,#UART0_BDH_OFFSET]
			MOVS 	R1,#UART0_BDL_9600
			STRB 	R1,[R0,#UART0_BDL_OFFSET]
			;Set UART0 character format for serial bit stream and clear flags
			MOVS	R1,#UART0_C1_8N1
			STRB	R1,[R0,#UART0_C1_OFFSET]
			MOVS 	R1,#UART0_C3_NO_TXINV
			STRB 	R1,[R0,#UART0_C3_OFFSET]
			MOVS 	R1,#UART0_C4_NO_MATCH_OSR_16
			STRB 	R1,[R0,#UART0_C4_OFFSET]
			MOVS 	R1,#UART0_C5_NO_DMA_SSR_SYNC
			STRB 	R1,[R0,#UART0_C5_OFFSET]
			MOVS 	R1,#UART0_S1_CLEAR_FLAGS
			STRB	R1,[R0,#UART0_S1_OFFSET]
			MOVS 	R1,#UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS
			STRB 	R1,[R0,#UART0_S2_OFFSET]
			;enable UART0 Tx, Rx, and Rx Interrupt
			MOVS	R1, #UART0_C2_T_RI
			STRB	R1,[R0,#UART0_C2_OFFSET]

			;pop modified registers from stack
			POP		{PC, R0-R3}
			BX		LR
			ENDP
				
GetChar		PROC	{R1-R14}
;*******************************************************************************
;Dequeues a character from the receive queue and returns it in R0
;Input:	NONE
;Output: R0 - The output character
;	 PSR C flag - Success(0) or Failure(1)
;Modify: R0, APSR
;All other registers remain unchanged on return
;*******************************************************************************
			PUSH	{LR, R1}
GetCharLoop
			CPSID	I				;mask off other interrupts
			LDR	R1, =RxQueue			;load address of receive queue
			BL	Dequeue				;dequeue from receive queue
			CPSIE	I				;unmask interrupts
			BCS	GetCharLoop			;loop while unsuccessful
			POP	{PC, R1}
		ENDP
			
PutChar		PROC	{R0-R14}
;*******************************************************************************
;Enqueues a character to the transmit queue and re-enables the transmit interrupt
;Input:	 R0 - Character to transmit
;Output: PSR C flag - Success(0) or Failure(1)
;Modify: APSR
;All other registers remain unchanged on return
;*******************************************************************************
			PUSH	{LR, R1-R2}
PutCharLoop
			CPSID	I				;mask other interrupts
			LDR	R1, =TxQueue			;load address of transmit queue
			BL	Enqueue				;enqueue to TXQueue
			CPSIE	I				;unmask interrupts
			BCS	PutCharLoop			;loop while unsuccessful
			LDR	R1,=UART0_BASE		;enable TXinterrupt
			MOVS	R2, #UART0_C2_TI_RI
			STRB	R2,[R1, #UART0_C2_OFFSET]
			POP	{PC, R1-R2}
		ENDP
				
GetStringSB	PROC		{R1-R14}				
;*******************************************************************************
;gets a string from the terminal based on keyboard input
;Input: R0, the address for the start of the string; R1, the string buffer max address
;Output: R0, the address of the string in memory
;Modify: APSR, R0
;R2<-- holds the base address of R0 to be called again at the beginning
;R3<-- string pointer
;*******************************************************************************
			PUSH		{LR, R2-R3}				;Push modified registers onto stack
			MOVS		R2, R0					;move the value of r0 into R2 for when R0 gets modified by getchar
			MOVS		R3, R0					;Load the address of the string into R3, string pointer
GetStringWhile	
			BL		GetChar						;get the input character and store it in R0
			CMP		R0, #CR						;compare the character to the end character
			BEQ		GetStringWhileEnd			;if it is the end character (enter key) than end the loop
			CMP		R3, R1						;compare the string pointer to the max string length
			BHS		GetStringWhile				;if it is greater than or equal to the max pointer than loop but no longer store
			BL		PutChar						;print the character
			STRB	R0, [R3, #0]				;store the char in String in the pointer
			ADDS	R3, R3, #1					;pointer++
			B		GetStringWhile				;loop
GetStringWhileEnd
			MOVS	R0, #NULL					;put the null value into R0
			STRB	R0, [R3, #0]				;null terminate then string
			MOVS	R0, #CR
			BL		PutChar						;make a new line by printing CR then LF
			MOVS	R0, #LF	
			BL		PutChar			
			MOVS	R0, R2						;put the base address of the string back into R0
			POP		{PC, R2-R3}
			BX		LR
			ENDP
		
PutStringSB	PROC	{R0-R14}		
;*******************************************************************************
;prints a string to the terminal
;Input: R0, the address for the start of the string; R1, max string buffer
;Output: NONE
;Modify: APSR
;*******************************************************************************
;R2<-- string ptr
;R3<-- holder for main string address
			PUSH	{LR, R2-R3}					;push modified registers onto stack
			MOVS	R2, #0						;put the string address into the string ptr
			MOVS	R3, R0						;put the string address in the holder
PutStringWhile
			CMP		R2, R1						;Compare the string pointer to the max string buffer		
			BHI		PutStringEnd				;if the pointer is larger than the buffer end the loop
			LDRB	R0, [R3, R2]				;load the current character into R0
			CMP		R0, #NULL					;check the current character against the null termination
			BEQ		PutStringEnd				;if it is the termination than end the subroutine
			BL		PutChar						;else print the character to the terminal
			ADDS	R2, R2,#1					;string pointer++
			B		PutStringWhile				;loop
PutStringEnd
			MOVS	R0, R3						;put the address of the string back into R0
			POP		{PC, R2-R3}					;pop modified registers from stack
			BX		LR
			ENDP
		
PutNumU		PROC	{R0-R14}		
;*******************************************************************************
;prints a hex value to the terminal
;Input: R0, hex value to be printed to the terminal in decimal
;Output: NONE
;Modify: APSR
;*******************************************************************************
;R2<--divisor for the division algorithm
			PUSH	{LR, R0-R3}					;push modified registers onto stack
			LDR		R2, =1000000000 			;load 1 billion for divisor
			MOVS	R1, R0						;put the dividend in R1
NumULoop
			MOVS	R0, R2						;put the divisor into R0
			BL		DIVU						;Divide
			ADDS	R0, R0, #0x30
			BL		PutChar						;print the number in R0 to the terminal
			CMP		R2, #1						;if we just did a divide by one
			BEQ		NumULoopEnd					;end the loop, else continue
			;get the next divisor by diving the current one by 10
			MOVS	R3, R1						;we need R1 so R3<--R1
			MOVS	R1, R2						; to set up division R1 <-- R2
			MOVS	R0, #10						;R0 <-- #10
			BL		DIVU						;DIVU to get the next divisor
			MOVS	R2, R0						;put the quotient into r2
			MOVS	R1, R3						;restore r1 from r3
			B		NumULoop
NumULoopEnd	
			POP		{PC, R0-R3}					;push modified registers onto stack
			BX		LR
			ENDP

UART0_IRQHandler	PROC	{R0-R14}
;*******************************************************************************
;UART0 interrupt service routine. If the ISR was called by a transmit interrupt,
;it dequeues a charcter from the Txqueue and then prints it to the terminal. If
;if the ISR was called by a recieve interrupt, it gets the chracter from the terminal
;and enqueues it to the RxQueue
;No inputs/outputs
;MODIFY: APSR
;no other registers modified upon return
;*******************************************************************************
		CPSID	I							;mask other interrupts
		PUSH	{LR, R0-R3}					;push changed registers, R0-R3, R12, and LR not needed
		LDR		R3, =UART0_BASE				;get the base UART0 address
		LDRB	R0, [R3,#UART0_C2_OFFSET]	;load in the data in UART0_C2
		MOVS	R1, #UART0_C2_TIE_MASK
		TST		R0, R1						;Check UART0_C2 against the TIE mask
		BEQ		UART0_ISR_SKIP_1			;if TIE is zero skip this part
		LDR		R0, [R3,#UART0_S1_OFFSET]	;load in UART0_S1
		MOVS	R1, #UART0_S1_TDRE_MASK
		TST		R0, R1						;Check TDRE
		BEQ		UART0_ISR_SKIP_1			;if TDRE is zero (no character to dequeue) than skip this
		LDR		R1, =TxQueue				;load in the address of the transmit queue
		BL		Dequeue						;dequeue a character from the queue
		BCS		UART0_ISR_ELSE_1			;if it was unsuccessful skip this part
		STRB	R0, [R3, #UART0_D_OFFSET]	;transmit the character to the data register
		B 		UART0_ISR_SKIP_1			;move on to the next step
UART0_ISR_ELSE_1							;if the dequeue is unsuccessful
		MOVS	R2, #UART0_C2_T_RI
		STRB	R2,[R3,#UART0_C2_OFFSET]
UART0_ISR_SKIP_1
		LDRB	R0, [R3,#UART0_S1_OFFSET]	;load in the receive data from UART
		MOVS	R1, #UART0_S1_RDRF_MASK
		TST		R0, R1						;check against the RDRF mask
		BEQ		UART0_ISR_SKIP_2			;if it isn't ready to receive skip this step
		LDRB	R0,[R3,#UART0_D_OFFSET]
		LDR		R1, =RxQueue				;load in the address for the receive queue
		BL		Enqueue
UART0_ISR_SKIP_2
		CPSIE	I							;unmask other interrupts
		POP		{PC, R0-R3}
	ENDP
;>>>>>   end subroutine code <<<<<
            ALIGN
;**********************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
;>>>>>   end constants here <<<<<
;**********************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
RxBuffer		SPACE	Q_BUF_SZ_TXRX
				ALIGN
RxQueue			SPACE	Q_REC_SZ
TxBuffer		SPACE	Q_BUF_SZ_TXRX
				ALIGN
TxQueue			SPACE	Q_REC_SZ
				ALIGN
TimerVar		SPACE	8				
;>>>>>   end variables here <<<<<
            END