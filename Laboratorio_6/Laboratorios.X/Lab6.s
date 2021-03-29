;-------------------------------------------------------------------------------
; Encabezado
;-------------------------------------------------------------------------------
; Archivo: Lab6
; Dispositivo: PIC16f887
; Autor: Jefry Carrasco
; Descripción: 
; Rutina que aumenta una variable con el TMR1
; Led intermitente controlado por TMR2
; Se muestra la variable de la primera parte en displays controlados con TMR0
; Encendido y apagado de los displays controlado con el TMR2    
; Hardware: 
; 8 Leds en PORTA
; 1 Display 7 segmentos MPX2 en PORTC
; 2 transistores en el PORTD
; 1 Led en PORTE
; Creado: 23 marzo, 2021
; Modificado: 28 marzo, 2021   

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
    movlw   6	    ; Cargar valor de registro W, valor inicial del tmr0
    ; t_deseado=(4*t_oscilación)(256-TMR0)(Preescaler)
    movwf   TMR0    ; Mover el valor de W a TMR0 por interrupción
    bcf	    T0IF    ; Limpiar bit de interrupción por overflow (Bit de INTCON)	
    endm
    
reiniciar_tmr1 macro	; Reinicio de Timer1
    Banksel PORTA    ; Acceder al Bank 0
    movlw   0x85     ; Cargar valor de registro W, valor inicial del tmr0
    movwf   TMR1H    ; Mover el valor de W a TMR0 por interrupción
    movlw   0xEE     ; Cargar valor de registro W, valor inicial del tmr0
    movwf   TMR1L    ; Mover el valor de W a TMR0 por interrupción
    bcf	    TMR1IF   ; Limpiar bit de interrupción por overflow (Bit de INTCON)	
    endm
 
reiniciar_tmr2 macro	; Reinicio de Timer1
    Banksel PORTA   ; Acceder al Bank 0
    movlw   0xFF   ; Cargar valor de registro W, valor inicial del tmr0
    movwf   PR2    ; Mover el valor de W a TMR0 por interrupción
    bcf	    TMR2IF    ; Limpiar bit de interrupción por overflow (Bit de INTCON)	
    endm
    
;-------------------------------------------------------------------------------
; Variables a utilizar
;-------------------------------------------------------------------------------
PSECT udata_bank0  ; Variables en banco 0
    var:	DS 1 
    flags:	DS 1
    nibble:	DS 2	
    displays:	DS 2
    
    banderas: DS 1 ;1 byte -> para contador de display timer0
    display_var: DS 2	
    cont:DS 1
    
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
    btfsc   TMR1IF	; Testear si esta encendida la bandera para...
    call    int_tmr1	; Ir a la subrutina del TMR1
    btfsc   TMR2IF	; Testear si esta encendida la bandera para...
    call    int_tmr2	; Ir a la subrutina del TMR2

pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
   
;--------------------------------------------------------------------------------
; Sub rutinas para interrupciones
;------------------------------------------------------------------------------- 
int_tmr2:
    reiniciar_tmr2
    incf    PORTE
    return

int_tmr1:
    reiniciar_tmr1
    incf    PORTA
    return
    
int_tmr0:
    reiniciar_tmr0		; Reiniciar el TMR0
    clrf    PORTD		; Reiniciar los displays
    btfsc   PORTE, 0
    return
    btfsc   flags, 0		; Revisa el bit de la bandera que 
    goto    display_1		; enciende el display 1
    
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
    call    config_tmr1
    call    config_tmr2
    call    config_int	    ; Configuración de enable interrupciones
        
loop: 
    call    Display7seg
    goto    loop
  
;-------------------------------------------------------------------------------
; Subrutinas para loop principal
;-------------------------------------------------------------------------------
 Display7seg:
    movf    PORTA, 0	; Mueve el valor del contador al registro W
    movwf   var	
    movf    var, 0	; Mueve el valor de la variable al registro W
    andlw   0x0F	; Solamente toma los primeros 4 bits de la variable
    movwf   nibble	; Mueve el valor de la variable a nibble
    swapf   var, 0	; Cambia los bytes de la variable var
    andlw   0x0F	; Solamente toma los primeros 4 bits de la variable
    movwf   nibble+1	; Mueve el valor de la variable al segundo byte de nibble

    movf    nibble, 0	; Mueve el valor del primer nibble al registro W
    call    tabla	; Conversion del nibble para el display
    movwf   displays	; Se guarda el primer byte de nibble en el primer byte display
    movf    nibble+1, 0	; Mueve el valor del segundo nibble al registro W
    call    tabla	; Conversion del nibble para el display
    movwf   displays+1	; Se guarda el segundo byte de nibble en el segundo byte display
    return 

;-------------------------------------------------------------------------------
; Subrutinas de configuración
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL ;Banco 11
    clrf    ANSEL ;Pines digitales
    clrf    ANSELH
    
    banksel TRISA ;Banco 01
    clrf    TRISA
    clrf    TRISC    ;Display multiplexados 7seg 
    clrf    TRISD    ;Alternancia de displays
    clrf    TRISE
    
    banksel PORTA ;Banco 00
    clrf    PORTA ;Comenzar contador binario en 0
    clrf    PORTC ;Comenzar displays en 0
    clrf    PORTD ;Comenzar la alternancia de displays en 0
    clrf    PORTE
    return
    
config_int:
    Banksel PORTA
    bsf	GIE	; Se habilitan las interrupciones globales
    bsf	PEIE	
    bsf	T0IE    ; Se habilitan la interrupción del TMR0
    bcf	T0IF    ; Se limpia la bandera
    Banksel TRISA
    bsf	TMR1IE	; Se habilitan la interrupción del TMR1 Registro PIE1
    bsf	TMR2IE	; Se habilitan la interrupción del TMR2 Registro PIE1
    Banksel PORTA
    bcf	TMR1IF  ; Se limpia la bandera Registro PIR1
    bcf	TMR2IF  ; Se limpia la bandera Registro PIR1
    return  
   
config_reloj:	; Configuración de reloj interno
    Banksel OSCCON  ; Acceder al Bank 1
    bsf	    IRCF2
    bcf	    IRCF1
    bcf	    IRCF0   ; Configuración del oscilador a 1MHz
    bsf	    SCS	    ; Seleccionar el reloj interno
    return
    
config_tmr0:
    Banksel TRISA   ; Acceder al Bank 1
    bcf	    T0CS    ; Seleccion entre reloj int. o ext. (Bit de OPTION_REG)
    bcf	    PSA	    ; Prescaler asignado a Timer0 (Bit de OPTION_REG)
    bcf	    PS2	    
    bcf	    PS1
    bcf	    PS0	    ; Bits para prescaler (1:2) (Bits de OPTION_REG)
    reiniciar_tmr0  ; Ir al reinicio del Timer0
    return

config_tmr1:
    Banksel PORTA  
    bsf	    TMR1ON
    bcf	    TMR1CS ; Seleccion del reloj interno
    bsf	    T1CKPS0
    bsf	    T1CKPS1 ; Prescaler a 1:8
    reiniciar_tmr1
    return 
    
config_tmr2:
    banksel PORTA
    bsf TMR2ON 
    
    bsf TOUTPS3
    bsf TOUTPS2
    bsf TOUTPS1
    bsf TOUTPS0
    
    bsf T2CKPS1
    bsf TOUTPS0
 
    reiniciar_tmr2
    return  
end