;-------------------------------------------------------------------------------
; Encabezado
;-------------------------------------------------------------------------------
; Archivo: Lab3
; Dispositivo: PIC16f887
; Autor: Jefry Carrasco
; Descripción: 
; Contador con delay (Timer0) en PORTC
; Display 7seg en PORTD controlado por 2 PushButtoms
; Hardware: 
; 4 Leds en PORTC
; 1 Display 7 segmentos en PORTD
; 2 PushButtoms en el puerto B
; Creado: 15 febrero, 2021
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
; Variables a utilizar
;-------------------------------------------------------------------------------
PSECT udata_shr
    display:	DS 1

;-------------------------------------------------------------------------------
; Vector reset
;-------------------------------------------------------------------------------
PSECT resVect, class=CODE, abs, delta=2
ORG 00h
resetVec:
    PAGESEL main
    goto main

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

;-------------------------------------------------------------------------------
; Loop principal
;-------------------------------------------------------------------------------
loop:
    btfss   PORTB, 0	;Si PB1+ es 0 entra a subrutina
    call    inc_contador  ;Entrar a subrutina incrementar contador 1
    btfss   PORTB, 1	;Si PB1- es 0 entra a subrutina
    call    dec_contador  ;Entrar a subrutina decrementar contador 1
    btfss   T0IF	; Revisar la bandera de interrupción
    goto    $-5
    call    reiniciar_tmr0  ; Ir al reinicio del Timer0
    incf    PORTD	; Incrementar el contador
    
    btfsc   PORTE, 0	; Si la alarma está activada se apaga
    bcf	    PORTE, 0	; Apagar led de la alarma
    call    alarma	; Entrar a la rutina de la alarma
    goto    loop
    
;-------------------------------------------------------------------------------
; Subrutinas
;-------------------------------------------------------------------------------

config_io:  ; Configuración de puertos
    Banksel ANSEL   ; Acceder al Bank 3
    clrf    ANSEL   ; Apagar entradas analógicas
    clrf    ANSELH  ; Apagar entradas analógicas

    Banksel TRISC   ; Acceder al Bank 1
    movlw   0xF0    ; Solo usar los 4 bits menos significativos como salida
    clrf    TRISC   ; Configurar PORTC como salida
    movwf   TRISD   ; Configurar PORTD como salida
    clrf    TRISE   ; Configurar PORTE como salida
    
    Banksel PORTC   ; Acceder al Bank 0
    movlw   0x3F    ; Cargar "00111111"B a W
    movwf   PORTC   ; Iniciar el PORTC en 0
    clrf    PORTD   ; Apagar los bits del PORTD
    clrf    PORTE   ; Apagar los bits del PORTE
    return

config_tmr0:	; Configuración de Timer0
    Banksel TRISA   ; Acceder al Bank 1
    bcf	    T0CS    ; Seleccion entre reloj int. o ext. (Bit de OPTION_REG)
    bcf	    PSA	    ; Prescaler asignado a Timer0 (Bit de OPTION_REG)
    bsf	    PS2	    
    bsf	    PS1
    bcf	    PS0	    ; Bits para prescaler (1:128) (Bits de OPTION_REG)
    Banksel PORTA   ; Acceder al Bank 0
    call    reiniciar_tmr0  ; Ir al reinicio del Timer0
    return

reiniciar_tmr0:	; Reinicio de Timer0
    movlw   12	; Cargar valor de registro W
    movwf   TMR0    ; Mover el valor de W a TMR0 por interrupción
    bcf	    T0IF    ; Bit de interrupción por overflow (Bit de INTCON)
    return
    
config_reloj:	; Configuración de reloj interno
    Banksel OSCCON  ; Acceder al Bank 1
    bcf	    IRCF2
    bsf	    IRCF1
    bcf	    IRCF0   ; Configuración del oscilador a 250kH
    bsf	    SCS	    ; Seleccionar el reloj interno para el sistema del reloj
    return

inc_contador:	; Incremento en el display 7seg
    btfss   PORTB, 0  ; Antirebote
    goto    $-1
    incf    display, 1	; Aumentar valor del display 7seg 
    movf    display, W	; Cargar el valor del display al registro W
    call    Tabla   ; Ingresar a la tabla
    movwf   PORTC   ; Mover el valor que devolvió la tabla hacia el PORTC
    ; (En el puerto C se encuentra conectado el Display 7seg)
    return
    
dec_contador:	; Decremento en el display 7seg
    btfss   PORTB, 1  ; Antirebote
    goto    $-1
    decf    display, 1	; Disminuir valor del display 7seg 
    movf    display, W	; Cargar el valor del display al registro W
    call    Tabla   ; Ingresar a la tabla
    movwf   PORTC   ; Mover el valor que devolvió la tabla hacia el PORTC
    ; (En el puerto C se encuentra conectado el Display 7seg)
    return

alarma:	    ; Alarma cuando el valor del Display sea igual al del contador 
    bcf	    STATUS, 2	; Se apaga la bandera de Zero 
    movwf   display, 0	; Se mueve el valor de contador display al registro W
    subwf   PORTD, 0	; Se resta con el valor del contador tmr0
    btfsc   STATUS, 2	; Revisar la bandera Zero en el registro STATUS
    bsf	    PORTE, 0	; Si se enciende Zero, se enciende la alarma
    btfsc   STATUS, 2	; Revisar la bandera Zero en el registro STATUS
    clrf    PORTD	; Si se enciende Zero, se reinicia la salida del tmr0
    btfsc   STATUS, 2	; Revisar la bandera Zero en el registro STATUS
    call    reiniciar_tmr0  ; Si está encendida la bandera, se reinicio el tmr0
    return
end