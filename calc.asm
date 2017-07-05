;Calculadora Hexadecimal para MSP430
;Autor: Israel Lopez

   #include    <msp430.h>
;------------------------------------------------------------------------------
    ORG   0F800h        ;Program start
;------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
;	NUMEROS
;	Proposito: Asignarle el valor ascii de los caracteres a las etiquetas correspondientes
;	Post-Condicion: Cada etiqueta ahora es quivalente al valor ascii del caracter asignado
;-------------------------------------------------------------------------------
CERO     	EQU    '0'
UNO      	EQU    '1'
DOS      	EQU    '2'
TRES     	EQU    '3'
CUATRO   	EQU    '4'
CINCO    	EQU    '5'
SEIS    	EQU    '6'
SIETE    	EQU    '7'
OCHO     	EQU    '8'
NUEVE    	EQU    '9'
LETRA_A  	EQU    'A'
LETRA_B  	EQU    'B'
LETRA_C  	EQU    'C'
LETRA_D  	EQU    'D'
LETRA_E  	EQU    'E'
LETRA_F  	EQU    'F'
Simbolo_1	EQU    '+'
Simbolo_2	EQU    '-'

;------------------------------------------------------------------------------
;	ARRAY
;	Proposito: Crear los array NUMEROS y SIMBOLOS que contienen los valores ascii de los caracteres a utilizarse
;	Post-Condicion: Los array NUMEROS y SIMBOLOS ahora contienen los valores ascii a utilizarse 
;------------------------------------------------------------------------------
NUMEROS        DB    CERO,UNO,DOS,TRES,CUATRO,CINCO,SEIS,SIETE,OCHO,NUEVE,LETRA_A,LETRA_B,LETRA_C,LETRA_D,LETRA_E,LETRA_F
SIMBOLOS       DB    Simbolo_1,Simbolo_2

;-------------------------------------------------------------------------------
;	HOUSE KEEPING
;	Proposito:Inicializar los pines de input y output. apagar el watchdogtimer, inicializar las resistencias interna
;		  establecerla como pull up y prender las interrupciones.
;	Post-Condicion:Procesos de inicializacion completados
;-------------------------------------------------------------------------------
RESET        mov     #0280h,SP        		;Initialize stackpointer
StopWDT      mov     #WDTPW+WDTHOLD,&WDTCTL     ;Stop WDT
SetupP1      bis.b   #11111111b,&P1DIR          ;P1.0-P1.7 as output
SetupP2      bis.b   #00000011b, &P2DIR    	;P2.0/2.1 as output

Input        bic.b   #00111100b, &P2DIR	  	;set buttons as input
             bis.b   #00111100b, &P2REN   	; Pone la resisitencia en P2.2-2.5
             bis.b   #00111100b, &P2OUT   	; Prende P2.2-2.5 como pull up
	     bis.b   #00111100b, &P2IE	  	;interrupt enable
	     bic.b   #0FFh, &P2IFG              ; set interrputs for p2.2-2.5

	     call    #INIT
	     
	     mov    #0x0000, R8
	     mov    #0x0000, R14
	     mov    #0x0000, R12
	     mov    #0x0001, R13
	     
	     jmp    SLEEP
	     
;------------------------------------------------------------------------------
;	8-bit INITIALIZATION LCD
;	Proposito: Inicializar la pantalla
;	Post-Condicion:Procesos de inicializacion de pantalla completados
;------------------------------------------------------------------------------
INIT    bic.b    #00000010b,&P2OUT  ; E=0
        mov      #14025,R15         ; delay of >40ms (42ms)
        call     #DELAYs
        mov      #0x30,R10	    ;turn on first line
        call     #COMMAND
        mov      #1785,R15          ;delay of 5ms
        call     #DELAYs
        call     #WAKEUP            ;2nd wakeup
        mov      #54,R15            ;delay of 160us (162us)
        call     #DELAYs
        call     #WAKEUP            ;3rd wakeup
        mov      #54,R15            ;delay of 160us    (162us)
        call     #DELAYs
        mov      #0x38,R10	    ;turn second line
        call     #COMMAND
        mov      #0x10,R10	    ;turn cursor on
        call     #COMMAND
        mov      #0x0E,R10	    ;modify cursor blink off
        call     #COMMAND
        mov      #0x06,R10	    ;entry mode set
        call     #COMMAND
        mov.b    #00000001b,R10     ;clear display command
        call     #COMMAND
	
	mov	 #0xC0, R10         ;WRITE FLAGS
	call     #COMMAND
	mov	 #'C',R10	    
	call 	 #WRITEch
	mov      #'=',R10
	call 	 #WRITEch
	mov      #'?',R10
	call 	 #WRITEch
	mov	 #0X16,R10	    ;move cursor right
	call     #COMMAND
	
	mov	#'N',R10
	call 	#WRITEch
	mov	#'=',R10
	call 	#WRITEch
	mov	#'?',R10
	call	#WRITEch
	mov	#0X16,R10
	call    #COMMAND
	
        mov	#'Z',R10
	call	#WRITEch
	mov	#'=',R10
	call	#WRITEch
	mov	#'?',R10
	call	#WRITEch
	mov	#0X16,R10
	call    #COMMAND
	
	mov	#'V',R10
	call	#WRITEch
	mov	#'=',R10
	call 	#WRITEch
	mov	#'?',R10
	call 	#WRITEch
	
	mov	 #0x8B, R10            ;Write = symbol
	call     #COMMAND
	mov	 #'=',R10	    
	call 	 #WRITEch
	mov	 #0X80,R10
	call     #COMMAND
        ret
;-------------------------------------------------------------------------------
;	Sleep
;	Proposito: Colocar el microprocesador en low power mode
;	Post-Condicion: Micro se encuentra en low power mode en espera de una interrupcion
;------------------------------------------------------------------------------
SLEEP        
	     bis.w   #CPUOFF+GIE,SR
	     nop
	     
	     jmp     SLEEP
;------------------------------------------------------------------------------
;	Button
;	Proposito: Identificar el boton presionado y ejecutar la operacion pertinente a ese boton
;	Pre-Condicion: Alguno de los botones debe generar una interrupcion
;	Post-Condicion: Se realiza la operacion pertinente al boton que se haya presionado
;	Valores y argumentos: Recibe un 1 correspondiente al boton presionado, 
;			      esto reprenta un cambio en estado en el boton
;------------------------------------------------------------------------------

BUTTON		
BUTTON_1        bit.b   #00000100b,&P2IN      ; Hacer un And con el valor actual de la entrada al puerto
                jnz     BUTTON_2
		cmp	#5,R13
		jz	Symbols
                inc     R12    		    ;Counter
                cmp.b   #16,R12
                jnz     NORESET_1
                bic.b   #11111111b,R12
NORESET_1       mov     NUMEROS(R12),R10
		bit	#0x0001,R12
		jnz	Shift
ENDSHIFT        call    #WRITEsel
Finish          mov     #0xFFFF,R15         ;delay of 5ms
                call    #DELAYs
		bic.b   #0FFh, &P2IFG  
		reti
		
BUTTON_2        bit.b #00001000b,&P2IN   
                jnz  BUTTON_3
		cmp	#1,R13
		jz	NOMORE
		mov	#' ',R10
		call #WRITEch
		cmp	#6,R13
		jz	DELSYMB
		cmp	#5,R13
		jz	DELSYMB
		jnz	DELNUM
		
DELSYMB		mov.b	 #0x84, R10
		call     #COMMAND
		mov	#' ',R10
		call #WRITEch
		mov	#' ',R10
		call #WRITEch
		mov	#' ',R10
		call #WRITEch
		mov.b	 #0x84, R10
		call     #COMMAND
		cmp	#5,R13
		jz	DEL5
		jmp	MID
		
DEL5		mov	#18,R10
		call	#COMMAND
		mov	#' ',R10
		call #WRITEch
		mov.b	 #0x83, R10
		call     #COMMAND
		jmp 	MID
		
DELNUM		mov	#18,R10
		call	#COMMAND
		mov	#18,R10
		call	#COMMAND
		mov	#' ',R10
		call #WRITEch
		mov	#18,R10
		call	#COMMAND
		
MID		dec	R13
		mov	#0,R14
NOMORE		bic.b   #0FFh, &P2IFG 
		reti
	
BUTTON_3        bit.b   #00010000b,&P2IN   
                jnz     BUTTON_4
		cmp	#0,R14
		jz	nomore
                call    #SAVE_DIGIT
		cmp.b   #5,R13
		jz	NEXT
		cmp.b   #9,R13
		jz	NEXT
                mov.b   R14,R10		;mueve el ascii del valor q se escogio a R10, ultimo valor desplegado por el boton 1
                call    #WRITEch
NEXT		mov	#0,R14
		inc	R13
		cmp	#3,R8
		jz	FNOT
		cmp	#10,R13
		jz	FUNCTIONS
                mov    #0xFFFF,R15        ;delay of 5ms
                call    #DELAYs
nomore		bic.b   #0FFh, &P2IFG 	
		reti;	done
		
BUTTON_4        bit.b #00100000b,&P2IN   
                jnz     BUTTON_1
		jmp	RESET
 
;-------------------------------------------------------------------------------
;	Save Digit
;	Proposito: Guardar cada digito del primer numero, cada digito del
;		   segundo y un valor que representa una operacion
;	Precondiciones: Boton 3 debe haber sido presionado para guardar un digito u operacion.
;	Post-Condiciones: Guarda cada digito del primer numero en el registro R7, cada digito del
;		   segundo numero en R9 y un valor que representa una operacion en R8
;	Valores y argumentos: Recibe el digito a guardar en R12 y recibe la posicion en pantalla con el contador R13
;-------------------------------------------------------------------------------

SAVE_DIGIT
DG	cmp.b   #9,R13    ;Cuarto Digito
	jnz	DD
	mov.b   R12,R5
	bic.w	#0000000000001111b,R9
	bis	R5,R9
        mov.b   #0,R12
    	ret

DD	cmp.b   #8,R13    ; Tercer Digito
	jnz     DC
	mov.b   R12,R5
	mov.b	#4,R6
	call	#SHift
	bic.w	#0000000011110000b,R9	
	bis	R5,R9
        mov.b   #0,R12
	ret

DC	cmp.b   #7,R13    ;Segundo Digito
	jnz     DA
	mov.b   R12,R5
	mov.b	#8,R6
	call	#SHift
	bic.w	#0000111100000000b,R9	
	bis	R5,R9
	mov.b   #0,R12
	ret  

DA	cmp.b   #6,R13    ;Primer Digito
	jnz	S
	mov.b   R12,R5    
	mov.b	#12,R6
	call	#SHift
	mov	R5,R9
    	mov.b   #0,R12
        ret

S	cmp.b   #5,R13    ;Funcion
	jnz	CA
	mov.b   R12,R8
        mov.b   #0,R12
	mov.b	#0x16,R10
	call    #COMMAND 
    	ret
	
CA	cmp.b   #4,R13    ;Cuarto Digito
	jnz	CB
	mov.b   R12,R5
	bic.w	#0000000000001111b,R7	
	bis	R5,R7
        mov.b   #0,R12
    	ret
    
CB	cmp.b    #3,R13    ; Tercer Digito
	jnz    CC
	mov.b     R12,R5
	mov.b	#4,R6
	call	#SHift
	bic.w	#0000000011110000b,R7	
	bis	R5,R7
        mov.b   #0,R12
	ret
    
CC	cmp.b    #2,R13    ;Segundo Digito
	jnz    CD
	mov.b     R12,R5
	mov.b	#8,R6
	call	#SHift
	bic.w	#0000111100000000b,R7	
	bis	R5,R7
	mov.b     #0,R12
	ret    
    
CD	mov.b   R12,R5    ;Primer Digito
	mov.b	#12,R6
	call	#SHift
	mov	R5,R7
    	mov.b   #0,R12
        ret
;------------------------------------------------------------------------------
;	WAKE-UP
;	Proposito: Hacer toggle al enable
;	Precondicion: Haber enviado data o un comando al data bus
;	Post-Condiciones: Se ejecuta la instruccion en el data bus o se imprime la data en el data bus
;-------------------------------------------------------------------------------
WAKEUP  bis.b    #00000010b, &P2OUT    ;E= P2.1 HIGH
        mov      #800,R15        ;wait 600 ns, greater than 300 ns
        call     #DELAYs
        bic.b    #00000010b, &P2OUT    ;E=0
        ret
;-------------------------------------------------------------------------------
;	Delay
;	Proposito: Darle tiempo a la pantalla a procesar la data o instrucciones enviadas
;	Precondicion: Haber determinado el tiempo del delay, el cual debe ser mayor al tiempo que tarda la pantalla
;	Post-condicion: Pantalla debe haber terminado de ejecutar
;	Valores y argumentos: Tiempo del delay dicatod por R15 (en nanosegundos)
;-------------------------------------------------------------------------------
DELAYs  dec R15
        jnz DELAYs
        ret

;-----------------------------------------------------------------------------
;	COMMAND
;	Proposito: Enviar instruccion al databus de la pantalla
;	Precondion: Se haya guardado un comando en R10
;	Post-Condiciones: Se coloca RS en estado bajo para indicar que es una instruccion y esta se manda al data bus
;	Valores y argumentos: Recibe el commando que se va a mandar al data bus en R10
;-------------------------------------------------------------------------------
COMMAND  bic.b    #11111111b,&P1OUT
         bis.b    R10, &P1OUT
         bic.b    #00000001b, &P2OUT    ;RS=P2.0 LOW; send instruction
         call     #WAKEUP
         ret
;-------------------------------------------------------------------------------
;	WRITE a Character
;	Proposito: Enviar data al databus de la pantalla
;	Precondion: Se haya guardado data en R10
;	Post-Condiciones: Se coloca RS en estado alto para indicar que es data y esta se manda al data bus
;	Valores y argumentos: Recibe la data que se va a mandar al data bus en R10
;-------------------------------------------------------------------------------
WRITEch bic.b     #11111111b, &P1OUT
        bis.b    R10,&P1OUT
        bis.b    #00000001b, &P2OUT    ;RS=P2.0 HIGH, send data
        call     #WAKEUP
        ret
;-------------------------------------------------------------------------------
;       WRITE in Character Selection
;	Proposito: Enviar data al databus de la pantalla y mueve el cursor hacia atras
;	Precondion: Se haya guardado data en R10
;	Post-Condiciones: Se coloca RS en estado alto para indicar que es data y esta se manda al data bus
;	Valores y argumentos: Recibe la data que se va a mandar al data bus en R10
;-------------------------------------------------------------------------------
WRITEsel    mov	     R10,R14
	    bic.b    #11111111b, &P1OUT
            bis.b    R10,&P1OUT
            bis.b    #00000001b, &P2OUT    ;RS=P2.0 HIGH, send data
            call     #WAKEUP
            mov      #0x10, R10              ;Move Cursor to the left
            call     #COMMAND
            ret
;-------------------------------------------------------------------------------
;	Shift Uneven Numbers
;	Proposito: Shift Right a R10 8 veces, para que el codigo ascii del numero impar quede en las posiciones menos significativas
;	Precondicion: R10 debe tener el codigo ascii del numero impar que se quiere imprimir
;	Post-condicion: Codigo ascii del numero impar queda en la posicion menos significativa
;	Valores y argumentos: Codigo ascii de numero impar y par en el registro 10
;-------------------------------------------------------------------------------
Shift	mov	#0x0001,R11
Again	rra	R10
	inc	R11
	cmp.b	#0x0009,R11
	jnz	Again
	jz	ENDSHIFT
;-------------------------------------------------------------------------------
;	Shift  Numbers
;	Proposito: Shift left a R5 las veces que indique R6
;	Precondicion: R5 debe tener el numero que se quiere rotar a la izquierda
;	Post-condicion: Numero es rotado a la izquierda las veces que dicte R6
;	Valores y argumentos: R5 que contiene el numero a rotar hacia la izquierda y R6 que contiene las vees que se va a rotar
;-------------------------------------------------------------------------------
SHift	mov	#0x0001,R11
	inc	R6
AGain	rlc	R5
	inc	R11
	cmp.b	R6,R11
	jnz	AGain
	ret
;-------------------------------------------------------------------------------
;	Symbols
;	Proposito: Determinar cual operacion se va a mostrar proximamente en la pantalla
;	Precondiciones: R12 debe contener un valor que equivale a una de las operaciones, 
;                       R13 debe contener un 5 que equivale a la quinta posicion en pantalla designada para operaciones
;	Post-condiciones: Se determina la operacion que se va a mostrar en pantalla
;	Valores y Argumentos: R12 debe contener un valor que equivlga a alguna de las operaciones
;-------------------------------------------------------------------------------
Symbols	 	inc     R12    ;Counter
		cmp.b   #2,R12
		jz	FUNC1
		mov.b	 #0x84, R10
		call     #COMMAND 
		
		cmp	#3,R12
		jz	FUNC3
		mov.b	 #0x84, R10
		call     #COMMAND 
		
		cmp	#4,R12
		jz	FUNC5
		mov.b	 #0x84, R10
		call     #COMMAND 
		
		cmp	#5,R12
		jz	FUNC4
		mov.b	 #0x84, R10
		call     #COMMAND 
		
		cmp	#6,R12
		jz	FUNC2
		
		cmp.b    #7,R12
                jnz      NORESETS_1
                bic.b    #11111111b,R12
		mov.b	 #0x85, R10
		call     #COMMAND 
		mov	 #' ',R10
		call #WRITEch
		mov.b	 #0x84, R10
		call     #COMMAND
		
NORESETS_1      mov     SIMBOLOS(R12),R10
		bit	#0x0001,R12
		jnz	Shift
		jmp	ENDSHIFT
;-------------------------------------------------------------------------------
;	Symbols2
;	Proposito: mostrar en pantalla la operacion pertinente
;	Precondiciones: R12 debe haber conteneido un valor equivalente a alguna de las operaciones
;	Post-condiciones: Se muestra en pantalla la operacion euivalente al valor de R12
;-------------------------------------------------------------------------------
FUNC1	mov	#'a',R10
	call #WRITEch
	mov	#'n',R10
	call #WRITEch
	mov	#'d',R10
	call #WRITEch
	mov.b	 #0x86, R10
	call     #COMMAND
	mov	#1,R14
	jmp  Finish
FUNC2	mov	#'o',R10
	call #WRITEch
	mov	#'r',R10
	call #WRITEch
	mov	#' ',R10
	call #WRITEch
	mov.b	 #0x85, R10
	call     #COMMAND
	mov	#1,R14
	jmp  Finish
FUNC3	mov	#'n',R10
	call #WRITEch
	mov	#'o',R10
	call #WRITEch
	mov	#'t',R10
	call #WRITEch
	mov.b	 #0x86, R10
	call     #COMMAND 
	mov	#1,R14
	jmp  Finish
FUNC4	mov	#'s',R10
	call #WRITEch
	mov	#'h',R10
	call #WRITEch
	mov	#'r',R10
	call #WRITEch
	mov.b	 #0x86, R10
	call     #COMMAND 
	mov	#1,R14
	jmp  Finish
FUNC5	mov	#'r',R10
	call #WRITEch
	mov	#'o',R10
	call #WRITEch
	mov	#'l',R10
	call #WRITEch
	mov.b	 #0x86, R10
	call     #COMMAND 
	mov	#1,R14
	jmp  Finish
	
;-------------------------------------------------------------------------------
;	FUNCTIONS
;	Proposito: Determinar cual operacion se va a llevar a cabo
;	Precondicion: R8 debe tener un valor que equivale a alguna de las operaciones, 
;		      R13 debe tener un 10 esto quivale a que ya se tomaron todos los digitos necesarios para realizar la operacion escogida
;	Post-condicion: Se determina cual operacion se va a ejecutar con los dos numeros ingresados por el usuario
;	Valores y argumentos: R8 debe contener un valor equivalente a la operacion que desea hacer el usuario
;-------------------------------------------------------------------------------
FUNCTIONS	cmp.b	#0,R8
		jz	FSUM
		cmp.b	#1,R8
		jz	FSUB
		cmp.b	#2,R8
		jz	FAND
		cmp.b	#4,R8
		jz	FROL
		cmp.b	#5,R8
		jz	FSHR
		cmp.b	#6,R8
		jz	FOR
;-------------------------------------------------------------------------------
;	SUM
;	Proposito: Realizar una suma entre el primer numero ingresado y el segundo
;	Precondicion: Haber ingresado los dos operando y haber escogido suma como operacion
;	Post-condicion: Resultado de la suma en R12
;	Valores y argumentos: Primer numero en R7 y segundo numero en R9
;-------------------------------------------------------------------------------
FSUM		add	R7,R9
		call	#Flags	
		call	#WRITEFLAGS
		mov	R9,R12
		call	#ANSWER
;-------------------------------------------------------------------------------
;	SUB
;	Proposito: Realizar una resta entre el primer numero ingresado y el segundo
;	Precondicion: Haber ingresado los dos operando y haber escogido resta como operacion
;	Post-condicion: Resultado de la resta en R12
;	Valores y argumentos: Primer numero en R7 y segundo numero en R9
;-------------------------------------------------------------------------------
FSUB		sub	R9,R7
		call	#Flags	
		call	#WRITEFLAGS
		mov	R7,R12
		call	#ANSWER
;-------------------------------------------------------------------------------
;	AND
;	Proposito: Realizar un and entre el primer numero ingresadi y el segundo
;	Precondicion: Haber ingresado los dos operando y haber escogido and como operacion
;	Post-condicion: Resultado del and en R12
;	Valores y argumentos: Primer numero en R7 y segundo numero en R9
;-------------------------------------------------------------------------------
FAND		and	R7,R9
		call	#Flags	
		call	#WRITEFLAGS
		mov	R9,R12
		call	#ANSWER
;-------------------------------------------------------------------------------
;	OR
;	Proposito: Realizar un or entre el primer numero ingresado y el segundo
;	Precondicion: Haber ingresado los dos operando y haber escogido or como operacion
;	Post-condicion: Resultado del or en R12
;	Valores y argumentos: Primer numero en R7 y segundo numero en R9
;-------------------------------------------------------------------------------
FOR		mov	R7,R5
		mov	R9,R8
		xor	R7,R9
		and	R5,R8
		xor	R9,R8
		clrc
		call	#Flags	
		call	#WRITEFLAGS
		mov	R8,R12
		call	#ANSWER
;-------------------------------------------------------------------------------
;	NOT
;	Proposito: Realizar un not con el numero ingresado
;	Precondicion: Haber ingresado el operando y haber escogido not como operacion
;	Post-condicion: Resultado del not en R12
;	Valores y argumentos: Operando en R7
;-------------------------------------------------------------------------------
FNOT		xor	#0xFFFF,R7
		call	#Flags	
		call	#WRITEFLAGS
		mov	R7,R12
		call	#ANSWER
;-------------------------------------------------------------------------------
;	SHR
;	Proposito: Realizar un shift right con el primer numero ingresado las veces que dicte el segundo numero
;	Precondicion: Haber ingresado el numero a ser rodado, haber escogido con el segundo numero las veces que se va a rotar y haber escogido shift right como operacion
;	Post-condicion: Resultado del shift right en R12
;	Valores y argumentos: Numero a rotar en R7 y cantidad de veces a rotar en R9
;-------------------------------------------------------------------------------
FSHR	cmp	#0,R9
	jz	IFZERO
	mov	#0x0001,R11
	inc	R9
AGain3	rra	R7
	call	#Flags	
	inc	R11
	cmp.b	R9,R11
	jnz	AGain3
FSHR2	call	#WRITEFLAGS
	mov	R7,R12
	call	#ANSWER
	ret
IFZERO	clrc
	clrn
	clrz
	call	#Flags
	jmp	FSHR2
;-------------------------------------------------------------------------------
;	ROL
;	Proposito: Realizar un shift left con el primer numero ingresado las veces que dicte el segundo numero y asumir flag C=1
;	Precondicion: Haber ingresado el numero a ser rodado, haber escogido con el segundo numero las veces que se va a rotar, 
;		      haber escogido shift left como operacion y flag C=1
;	Post-condicion: Resultado del shift left en R12
;	Valores y argumentos: Numero a rotar en R7 y cantidad de veces a rotar en R9
;-------------------------------------------------------------------------------
FROL	cmp	#0,R9
	jz	ifzero
	mov	#0x0001,R11
	inc	R9
	setc
AGain4	rlc	R7
	call	#Flags	
	inc	R11
	cmp.b	R9,R11
	jnz	AGain4
FROL2	call	#WRITEFLAGS
	mov	R7,R12
	call	#ANSWER
	ret
ifzero	setc
	clrn
	clrz
	call	#Flags
	jmp	FROL2
;-------------------------------------------------------------------------------
;	FLAGS
;	Proposito: Identificar el valor de cada flag (1 o 0) y moverlos al registro correspondiente
;	Precondicion: Se tiene que haber ejecutado la operacion justo antes de llamar esta subrutina
;	Post-condicion: Se mueve el valor de cada flag a los registros pertinentes
;	Valores y argumentos: Utiliza los valores que contiene el status register en ese momento
;-------------------------------------------------------------------------------
Flags		jz	FLAGZ
		mov	#0,R4
Flag2		jc	FLAGC
		mov	#0,R5
Flag3		jn	FLAGN
		mov	#0,R6
Flag4		jge     FLAGV
		jl	FLAGV2
FlagF		ret
;-------------------------------------------------------------------------------
;	WRITE FLAGS
;	Proposito: Escribir el valor de cada flag en pantalla
;	Precondicion: Se tiene que haber identificado el valor de cada flag y se tiene que haber guardado cada valor en su registro asignado
;	Post-condicion: Se escribe en pantalla los valores de cada flag
;	Valores y argumentos: Utiliza los valores de los flags guardados en los registros R4, R5, R6, R13
;-------------------------------------------------------------------------------
WRITEFLAGS	mov	#1,R12
		mov	#0xCA, R10
		call    #COMMAND
		cmp.b	#1,R4
		jz	Writeone
		mov	#'0',R10
		call #WRITEch
FLAG2		inc	R12
		
		mov	#0xC2, R10
		call    #COMMAND
		cmp.b	#1,R5
		jz	Writeone
		mov	#'0',R10
		call #WRITEch
FLAG3		inc	R12
		
		mov	#0xC6, R10
		call    #COMMAND
		cmp.b	#1,R6
		jz	Writeone
		mov	#'0',R10
		call #WRITEch
FLAG4		inc	R12

		mov	#0xCE, R10
		call    #COMMAND
		cmp.b	#1,R13
		jz	Writeone
		mov	#'0',R10
		call #WRITEch
FLAGF		ret
;-------------------------------------------------------------------------------
;	WriteAnswer
;	Proposito: Mostrar cada digito del resultado de la operacion realizada
;	Precondicion: se tiene que haber realizado la operacion y el resultado debe estar guardado en R12
;	Post-condicion: Se muestra resultado en pantalla
;	Valores y argumentos: Recibe el resultado de la operacion en R12
;-------------------------------------------------------------------------------
ANSWER		mov	R12,R4
		mov	#0x0001,R5		
		mov	#0x8C,R10      ;posicion 8C para primer digito de contestacion
		call    #COMMAND
		mov.b	#12,R6
		call	#SHift2
		mov     NUMEROS(R4),R10
		bit	#0x0001,R4
		jnz	Shift2
CONT1		call    #WRITEch
		inc	R5
		
		mov	R12,R4
		mov.b	#8,R6
		call	#SHift2
		bic.w	#1111111111110000b,R4
		mov     NUMEROS(R4),R10
		bit	#0x0001,R4
		jnz	Shift2
CONT2		call    #WRITEch
		inc	R5
		
		mov	R12,R4
		mov.b	#4,R6
		call	#SHift2
		bic.w	#1111111111110000b,R4
		mov     NUMEROS(R4),R10
		bit	#0x0001,R4
		jnz	Shift2
CONT3		call    #WRITEch
		inc	R5
		
		mov	R12,R4	
		bic.w	#1111111111110000b,R4
		mov     NUMEROS(R4),R10
		bit	#0x0001,R4
		jnz	Shift2
CONT4		call    #WRITEch

		bic.b   #00011100b, &P2IE
SLEEP2       bis.w   #CPUOFF+GIE,SR
	     nop
	     
	     jmp     SLEEP2


;-------------------------------------------------------------------------------
;	Shift Uneven Numbers2
;	Proposito: Shift Right a R10 8 veces, para que el codigo ascii del numero impar quede en las posiciones menos significativas.
;		   Esta subrutina es especificamente para el uso de la subrutina Answer para evitar problemas con el range del PC
;	Precondicion: R10 debe tener el codigo ascii del numero impar que se quiere imprimir
;	Post-condicion: Codigo ascii del numero impar queda en la posicion menos significativa
;	Valores y argumentos: Codigo ascii de numero impar y par en R10
;-------------------------------------------------------------------------------
Shift2	mov	#0x0001,R11
Again2	rra	R10
	inc	R11
	cmp.b	#0x0009,R11
	jnz	Again2
	cmp.b	#1,R5
	jz	CONT1
	cmp.b	#2,R5
	jz	CONT2
	cmp.b	#3,R5
	jz	CONT3
	cmp.b	#4,R5
	jz	CONT4
;-------------------------------------------------------------------------------
;	Shift  Numbers2
;	Proposito: Shift right a R4 las veces que indique R6
;	Precondicion: R4 debe tener el numero que se quiere rotar a la derecha
;	Post-condicion: Numero es rotado a la derecha las veces que dicte R6
;	Valores y argumentos: 45 que contiene el numero a rotar hacia la derecha y R6 que contiene las vees que se va a rotar
;-------------------------------------------------------------------------------
SHift2	mov	#0x0001,R11
	inc	R6
AGain2	rrc	R4
	inc	R11
	cmp.b	R6,R11
	jnz	AGain2
	ret
;-------------------------------------------------------------------------------
;	Move 1 to flag
;	Proposito: Mover un 1 al register del flag indicado si este es el valor que tiene el Status register luego de la operacion
;	Precondicion: Flag debe tener un 1 en el status register
;	Post-condicion: Se mueve un 1 al registro asignado para ese flag
;	Valores y argumentos: tiliza los valores que contiene el status register en ese momento
;-------------------------------------------------------------------------------
FLAGZ	mov	#1,R4
	jmp	Flag2

FLAGC	mov	#1,R5
	jmp	Flag3

FLAGN	mov	#1,R6
	jmp	Flag4

FLAGV	mov	R6,R13
	jmp	FlagF

FLAGV2	mov	R6,R13
	cmp.b	#1,R13
	jz	V1
	jnz	V2
V1	mov	#0,R13
	jmp	FlagF
V2	mov	#1,R13
	jmp	FlagF
	
;-------------------------------------------------------------------------------
;	WRITE 1
;	Proposito: Si el registro del flag contiene un 1 este se escribe en pantalla
;	Precondicion: Valor del flag debe ser 1
;	Post-condicion: Se escribe el 1 perteneciente al flag indicado
;	Valores y argumentos: Recibe R12 para saber a cual es el proximo flag y regresar a WRITE FLAGS
;-------------------------------------------------------------------------------
Writeone	mov	#'1',R10
		call #WRITEch
		cmp.b	#1,R12
		jz	FLAG2
		cmp.b	#2,R12
		jz	FLAG3
		cmp.b	#3,R12
		jz	FLAG4
		cmp.b	#4,R12
		jz	FLAGF
;-------------------------------------------------------------------------------
;            Interrupt Vectors
;-------------------------------------------------------------------------------
        ORG    0FFFEh           ;MSP430 RESET Vector
        DW     RESET            
	ORG    0FFE6h		;Se utilizo 0FFE6h debido a que esa es la localizacion de los puertos 2
	DW     BUTTON		; Nombre del ISR
        END