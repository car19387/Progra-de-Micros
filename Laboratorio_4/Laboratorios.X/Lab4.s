;-------------------------------------------------------------------------------
; Encabezado
;-------------------------------------------------------------------------------
; Archivo: Lab4
; Dispositivo: PIC16f887
; Autor: Jefry Carrasco
; Descripción: 
; Contador binario de 4bits en PORTA controlado por interrupciones
; Display 7seg en PORTC controlado por contador binario
; Display 7seg en PORTD con delay de 1s por TMR0
; Hardware: 
; 4 Leds en PORTA
; 1 Display 7 segmentos en PORTC
; 1 Display 7 segmentos en PORTD
; 2 PushButtoms en el puerto B
; Creado: 22 febrero, 2021
; Modificado:  febrero, 2021   

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
CONFIG WDTE=OFF	; WatchDogTimer desactivado
CONFIG PWRTE=ON	; Espera de 72ms al iniciar
CONFIG MCLRE=OFF    ; MCLR se utiliza como I/O
CONFIG CP=OFF	; Sin proteccion de codigo
CONFIG CPD=OFF	; Sin proteccion de datos

CONFIG BOREN=OFF    ; Sin reinicio si Volt. cae debajo de 4V durante 100us o más
CONFIG IESO=OFF	; Cambio entre relojes internos y externos desactivado
CONFIG FCMEN=OFF    ; Cambio de reloj externo a interno por fallo desactivado
CONFIG LVP=ON	; Programaciòn en bajo voltaje permitida

; CONFIG2
CONFIG WRT=OFF	; Protección de autoescritura por el programa desactivado
CONFIG BOR4V=BOR40V ; Reinicio abajo de 4V, (BOR21v=2.1V)

;-------------------------------------------------------------------------------
; MACROS
;-------------------------------------------------------------------------------
reiniciar_tmr0 macro	; Reinicio de Timer0
    Banksel PORTA   ; Acceder al Bank 0
    movlw   61	    ; Cargar valor de registro W
    ; t_deseado=(4*t_oscilación)(256-TMR0)(Preescaler)
    movwf   TMR0    ; Mover el valor de W a TMR0 por interrupción
    bcf	    T0IF    ; Bit de interrupción por overflow (Bit de INTCON)	
    endm

;-------------------------------------------------------------------------------
; Variables a utilizar
;-------------------------------------------------------------------------------
PSECT udata_shr
    cont:	DS 1
    display:	DS 1
    conversion:	DS  1
    w_temp:	DS 1
    status_temp:    DS 1

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
    movlw   w_temp
    swapf   STATUS, W
    movwf   status_temp
    
isr:
    btfsc   T0IF
    call    int_t0
    btfsc   RBIF
    call    int_iocb
    
pop:
    swapf   status_temp, w
    movwf   STATUS
    swapf   w_temp, f
    swapf   w_temp, w
    retfie

;-------------------------------------------------------------------------------
; Vector de interrupción
;-------------------------------------------------------------------------------
int_iocb:
    Banksel PORTA
    btfss   PORTB, 1
    incf    PORTA
    btfss   PORTB, 0
    decf    PORTA
    movf    PORTA, w
    movwf   conversion
    call    Tabla   ; Ingresar a la tabla
    movwf   PORTC   ; Mover el valor que devolvió la tabla hacia el PORTC
    
    bcf	    RBIF 
    return
    
int_t0:
    reiniciar_tmr0
    incf    cont
    movf    cont, w
    sublw   20
    btfss   ZERO
    goto    return_tmr0
    clrf    cont
    incf    display, 1	; Aumentar valor del display 7seg 
    movf    display, W	; Cargar el valor del display al registro W
    call    Tabla   ; Ingresar a la tabla
    movwf   PORTD   ; Mover el valor que devolvió la tabla hacia el PORTC
return_tmr0:
    return
   
;-------------------------------------------------------------------------------
; Configuración del microcontrolador
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 100h
Tabla:
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
; Main
;-------------------------------------------------------------------------------
main:
    call    config_io	    ;Configurar entradas y salidas
    call    config_reloj    ;Configurar el reloj (oscilador)
    call    config_tmr0	    ;Configurar el registro de TMR0
    call    config_iocrb
    call    config_int_enable

;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------
loop:
    
    goto    loop
    
;-------------------------------------------------------------------------------
; Subrutinas
;-------------------------------------------------------------------------------

config_io:  ; Configuración de puertos
    Banksel ANSEL   ; Acceder al Bank 3
    clrf    ANSEL   ; Apagar entradas analógicas
    clrf    ANSELH  ; Apagar entradas analógicas

    Banksel TRISA   ; Acceder al Bank 1
    movlw   0xF0    ; Solo usar los 4 bits menos significativos como salida
    movwf   TRISA   ; Configurar PORTA como salida (4 bits menos significativos)
    clrf    TRISC   ; Configurar PORTC como salida
    clrf    TRISD   ; Configurar PORTD como salida
    bsf	    TRISB, 1
    bsf	    TRISB, 0
    bcf	    OPTION_REG, 7
    bsf	    WPUB, 1
    bsf	    WPUB, 0
    
    
    Banksel PORTC   ; Acceder al Bank 0
    movlw   0x3F    ; Cargar "00111111"B a W
    clrf    PORTA
    movwf   PORTC   ; Iniciar el PORTC en 0
    movwf   PORTD   ; Apagar los bits del PORTD
    clrf    PORTE   ; Apagar los bits del PORTE
    return
    
config_reloj:	; Configuración de reloj interno
    Banksel OSCCON  ; Acceder al Bank 1
    bsf	    IRCF2
    bsf	    IRCF1
    bcf	    IRCF0   ; Configuración del oscilador a 4MHz
    bsf	    SCS	    ; Seleccionar el reloj interno
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

config_int_enable:
    bsf	    GIE
    bsf	    T0IE
    bcf	    T0IF
    bsf	    RBIE
    bcf	    RBIF
    return

config_iocrb:
    Banksel TRISA
    bsf	    IOCB, 1
    bsf	    IOCB, 0
    
    Banksel PORTA
    movf    PORTB, w
    bcf	    RBIF
    return
    
end