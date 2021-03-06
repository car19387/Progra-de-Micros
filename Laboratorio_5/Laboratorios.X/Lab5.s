;-------------------------------------------------------------------------------
; Encabezado
;-------------------------------------------------------------------------------
; Archivo: Lab5
; Dispositivo: PIC16f887
; Autor: Jefry Carrasco
; Descripción: 
; Contador binario de 8bits en PORTA controlado por interrupciones
; 5 Display 7seg multiplexados en PORTC controlado por contador binario
; Hardware: 
; 8 Leds en PORTA
; 1 Display 7 segmentos MPX4 en PORTC
; 1 Display 7 segmentos MPX2 en PORTC
; 2 PushButtoms en el PORTB
; 5 transistores en el PORTD
; Creado: 01 marzo, 2021
; Modificado:  marzo, 2021   

;-------------------------------------------------------------------------------
; Librerías incluidas
;-------------------------------------------------------------------------------
PROCESSOR 16F887
#include <xc.inc>
    
;-------------------------------------------------------------------------------
; Configuración de PIC16f887
;-------------------------------------------------------------------------------

; CONFIG1
CONFIG FOSC=INTRC_NOCLKOUT  ; Oscilador interno sin salida
CONFIG WDTE=OFF	    ; WatchDogTimer desactivado
CONFIG PWRTE=ON	    ; Espera de 72ms al iniciar
CONFIG MCLRE=OFF    ; MCLR se utiliza como I/O
CONFIG CP=OFF	    ; Sin proteccion de codigo
CONFIG CPD=OFF	    ; Sin proteccion de datos

CONFIG BOREN=OFF    ; Sin reinicio si Volt. cae debajo de 4V durante 100us o más
CONFIG IESO=OFF	    ; Cambio entre relojes internos y externos desactivado
CONFIG FCMEN=OFF    ; Cambio de reloj externo a interno por fallo desactivado
CONFIG LVP=ON	    ; Programaciòn en bajo voltaje permitida

; CONFIG2
CONFIG WRT=OFF	    ; Protección de autoescritura por el programa desactivado
CONFIG BOR4V=BOR40V ; Reinicio abajo de 4V, (BOR21v=2.1V)

;-------------------------------------------------------------------------------
; Macros
;-------------------------------------------------------------------------------
reiniciar_tmr0 macro	; Reinicio de Timer0
    Banksel PORTA   ; Acceder al Bank 0
    movlw   250	    ; Cargar valor de registro W, valor inicial del tmr0
    ; t_deseado=(4*t_oscilación)(256-TMR0)(Preescaler)
    movwf   TMR0    ; Mover el valor de W a TMR0 por interrupción
    bcf	    T0IF    ; Limpiar bit de interrupción por overflow (Bit de INTCON)	
    endm
    
;-------------------------------------------------------------------------------
; Variables a utilizar
;-------------------------------------------------------------------------------
PSECT udata_bank0  ; Variables en banco 0
    var:	DS 1 
    flags:	DS 1
    nibble:	DS 2	
    displays:	DS 2
    unidades:	DS 1
    decenas:	DS 1
    centenas:	DS 1
    unidades_1:	DS 1
    decenas_1:	DS 1
    centenas_1:	DS 1
    var_temp:	DS 1
        
PSECT udata_shr	    ; Variables en Share memory
    W_TEMP:	    DS 1 
    STATUS_TEMP:    DS 1 

;-------------------------------------------------------------------------------
; Vector reset
;-------------------------------------------------------------------------------
PSECT resVect, class=CODE, abs, delta=2
ORG 00h
resetVec:
    PAGESEL main
    goto main

;-------------------------------------------------------------------------------
; Vector de interrupción
;-------------------------------------------------------------------------------
PSECT intVect, class=CODE, abs, delta=2
ORG 04h	    ; Posicion para las interrupciones
push:
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP
 
isr:
    btfsc   T0IF	; Testear si esta encendida la bandera para...
    call    int_tmr0	; Ir a la subrutina del TMR0
    btfsc   RBIF	; Testear si esta encendida la bandera para...
    call    int_IOCB	; Incrementa o decrementa el puerto A y el display
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
;-------------------------------------------------------------------------------
; Sub rutinas para interrupciones
;-------------------------------------------------------------------------------
int_IOCB:   
    banksel PORTA
    btfss   PORTB, 0  ; Si se presiona el PB +
    incf    PORTA     ; Incrementar PORTA
    btfss   PORTB, 1  ; Si se presiona el PB - 
    decf    PORTA     ; Decrementar PORTA
    bcf	    RBIF      ; Limpiar la bandera de IOC
    return
    
int_tmr0:
    reiniciar_tmr0		; Reiniciar el TMR0
    clrf    PORTD		; Reiniciar los displays
    btfsc   flags, 0		; Revisa el bit de la bandera que 
    goto    display_1		; enciende el display 1
    btfsc   flags, 1		; Revisa el bit de la bandera que 
    goto    display_unidades	; enciende el display de unidades
    btfsc   flags, 2		; Revisa el bit de la bandera que 
    goto    display_decenas	; enciende el display de decenas
    btfsc   flags, 3		; Revisa el bit de la bandera que 
    goto    display_centenas	; enciende el display de centenas
    
display_0:
    movf    displays+0, 0	; El primer byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 0		; Seleccionar unidades
    goto    siguiente_display	; para que se encienda el display 0
    
display_1:
    movf    displays+1, 0	; El segundo byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 1		; Seleccionar decenas
    goto    siguiente_display	; para que se encienda el display 1
    
display_unidades:
    movf    unidades_1, 0	; La variable de unidades va al registro W
    movwf   PORTC		; Ese valor se coloca en el PORTC
    bsf	    PORTD, 2		; Seleccionar unidades
    goto    siguiente_display	; para que se encienda el display de unidades
    
display_decenas:
    movf    decenas_1, 0	; La variable de decenas va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 3		; Seleccionar decenas
    goto    siguiente_display	; para que se encienda el display de decenas
    
display_centenas:		
    movf    centenas_1, 0	; La variable de centenas va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 4		; Seleccionar centenas
    goto    siguiente_display	; para que se encienda el display de centenas
    
siguiente_display:
    movf    flags, W	; Muever la bandera al registro W
    andlw   0x0F	; Se utilizan solo los 4 bits menos signficativos
    incf    flags	; Incrementar la bandera para que cambie de display    
    return
    
;-------------------------------------------------------------------------------
; Configuración del microcontrolador
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 100h ;Posición para el código
 
tabla:
    clrf    PCLATH	; PCLATH = 00
    bsf	    PCLATH, 0	; PCLATH = 01
    andlw   0x0F	; Se utilizan solo los 4 bits menos signficativos
    addwf   PCL		; PC = PCL + PCLATH
    retlw   00111111B	; 0
    retlw   00000110B	; 1
    retlw   01011011B	; 2
    retlw   01001111B	; 3	
    retlw   01100110B	; 4
    retlw   01101101B	; 5
    retlw   01111101B	; 6
    retlw   00000111B	; 7
    retlw   01111111B	; 8
    retlw   01101111B	; 9
    retlw   01110111B	; A
    retlw   01111100B	; B
    retlw   00111001B	; C
    retlw   01011110B	; D
    retlw   01111001B	; E
    retlw   01110001B	; F

;-------------------------------------------------------------------------------
; Configuraciones
;-------------------------------------------------------------------------------
main:
    call    config_io	    ; Configurar entradas y salidas
    call    config_reloj    ; Configurar el reloj (oscilador)
    call    config_tmr0	    ; Configurar el registro de TMR0
    call    config_int	    ; Configuración de enable interrupciones
    call    config_IOC	    ; Configuración IOC del puerto B
    
loop: 
    movf    PORTA, 0	; Mueve el valor del contador al registro W
    movwf   var		; Mueve el valor a una variable
    call    separar_nibbles 
    call    preparar_displays
    movf    PORTA, 0	; Mueve el valor del contador al registro W
    movwf   var_temp	; Mueve el valor a una variable temporal
    call    Contador_decimal	
    goto    loop
    
;-------------------------------------------------------------------------------
; Subrutinas para loop principal
;-------------------------------------------------------------------------------
 separar_nibbles:
    movf    var, 0	; Mueve el valor de la variable al registro W
    andlw   0x0F	; Solamente toma los primeros 4 bits de la variable
    movwf   nibble	; Mueve el valor de la variable a nibble
    swapf   var, 0	; Cambia los bytes de la variable var
    andlw   0x0F	; Solamente toma los primeros 4 bits de la variable
    movwf   nibble+1	; Mueve el valor de la variable al segundo byte de nibble
    return

preparar_displays:
    movf    nibble, 0	; Mueve el valor del primer nibble al registro W
    call    tabla	; Conversion del nibble para el display
    movwf   displays	; Se guarda el primer byte de nibble en el primer byte display
    movf    nibble+1, 0	; Mueve el valor del segundo nibble al registro W
    call    tabla	; Conversion del nibble para el display
    movwf   displays+1	; Se guarda el segundo byte de nibble en el segundo byte display
    return 

Contador_decimal:
    clrf    unidades	; Se limpian las variables a utilizar 
    clrf    decenas
    clrf    centenas
    
    movlw 100		; Revisión centenas
    subwf var_temp,1	; Se restan 100 a la variable temporal 
    btfsc STATUS, 0	; Revisión de la bandera de Carry
    incf centenas, 1	; Si C=1 entonces es menor a 100 y no incrementa la variable
    btfsc STATUS, 0	; Revisión de la bandera de Carry para saber si volver 
    goto $-4		; a realizar la resta 
    addwf var_temp,1	; Se regresa la variable temporal a su valor original
    
    movlw 10		; Revisión decenas
    subwf var_temp,1	; Se restan 10 a la variable temporal
    btfsc STATUS, 0	; Revisión de la bandera de Carry
    incf decenas, 1	; Si C=1 entonces es menor a 10 y no incrementa la variable
    btfsc STATUS, 0	; Revisión de la bandera de Carry
    goto $-4
    addwf var_temp,1	; Se regresa la variable temporal a su valor original
    
    ;Resultado unidades
    movf var_temp, 0 ; Se mueve lo restante en la variable temporal a la
    movwf unidades   ; variable de unidades
    
    call preparar_displays_decimal ; Se mueven los valores a los displays
    
    return
    
preparar_displays_decimal:
    clrf    unidades_1	; Se limpian las variables
    clrf    decenas_1
    clrf    centenas_1
    
    movf    centenas, 0	
    call    tabla	; Se obtiene el valor correspondiente para el display
    movwf   centenas_1	; y se coloca en la variable que se utiliza en el cambio
			; de displays (Interrupción TMR0)
    
    movf    decenas, 0
    call    tabla
    movwf   decenas_1
    
    movf    unidades, 0
    call    tabla
    movwf   unidades_1
    
    return
;-------------------------------------------------------------------------------
; Subrutinas de configuración
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL ;Banco 11
    clrf    ANSEL ;Pines digitales
    clrf    ANSELH
    
    banksel TRISA ;Banco 01
    clrf    PORTA
    bsf	    TRISB, 0 ;Push button de incremento
    bsf	    TRISB, 1 ;Push button de decremento 
    clrf    TRISC    ;Display multiplexados 7seg 
    clrf    TRISD    ;Alternancia de displays
    
    bcf	    OPTION_REG, 7 ;Habilitar pull-ups
    bsf	    WPUB, 0 
    bsf	    WPUB, 1
    
    banksel PORTA ;Banco 00
    clrf    PORTA ;;Comenzar contador binario en 0
    clrf    PORTC ;Comenzar displays en 0
    clrf    PORTD ;Comenzar la alternancia de displays en 0
    clrf    var_temp ;Se limpia la variable temporal utilizada para el contador decimal
    return
 
config_reloj:	; Configuración de reloj interno
    Banksel OSCCON  ; Acceder al Bank 1
    bsf	    IRCF2
    bsf	    IRCF1
    bcf	    IRCF0   ; Configuración del oscilador a 4MHz
    bsf	    SCS	    ; Seleccionar el reloj interno
    return

config_int:
    bsf	GIE	; Se habilitan las interrupciones globales
    bsf	RBIE	; Se habilita la interrupción de las resistencias pull-ups 
    bcf	RBIF	; Se limpia la bandera
    bsf	T0IE    ; Se habilitan la interrupción del TMR0
    bcf	T0IF    ; Se limpia la bandera
    return

config_IOC:
    banksel TRISA
    bsf	    IOCB, 0 ;Se habilita el Interrupt on change de los pines
    bsf	    IOCB, 1 ;
    
    banksel PORTA
    movf    PORTB, W 
    bcf	    RBIF     ; Se limpia la bandera
    return
    
config_tmr0:	; Configuración de Timer0
    Banksel TRISA   ; Acceder al Bank 1
    bcf	    T0CS    ; Seleccion entre reloj int. o ext. (Bit de OPTION_REG)
    bcf	    PSA	    ; Prescaler asignado a Timer0 (Bit de OPTION_REG)
    bsf	    PS2	    
    bsf	    PS1
    bsf	    PS0	    ; Bits para prescaler (1:256) (Bits de OPTION_REG)
    reiniciar_tmr0  ; Ir al reinicio del Timer0
    return
end