;-------------------------------------------------------------------------------
; Encabezado
;-------------------------------------------------------------------------------
; Archivo: Proyecto1
; Dispositivo: PIC16f887
; Autor: Jefry Carrasco
; Descripción: 
; Sistema de 3 semaforos para el control de vias con configuración de tiempo
; en verde de forma independiente para cada semanforo
; Hardware: 
; 8 Leds en PORTA
; 1 Led en PORTB
; 3 Leds en PORTE
; 4 Display 7 segmentos MPX2 en PORTC
; 8 transistores en el PORTD
; 3 Push Buttoms en el PORTB
; Creado: 15 marzo, 2021
; Modificado: 6 abril, 2021   

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
    Banksel PORTA	; Acceder al Bank 0
    movlw   6		; Cargar valor de registro W, valor inicial del tmr0
    ; t_deseado=(4*t_oscilación)(256-TMR0)(Preescaler)
    movwf   TMR0	; Mover el valor de W a TMR0 por interrupción
    bcf	    T0IF	; Limpiar bandera de interrupción por overflow	
    endm
    
reiniciar_tmr1 macro	; Reinicio de Timer1
    Banksel PORTA	; Acceder al Bank 0
    movlw   0x85	; Cargar valor de registro W, valor inicial del tmr1
    movwf   TMR1H	; Mover el valor de W a TMR1H
    movlw   0xEE	; Cargar valor de registro W, valor inicial del tmr1
    movwf   TMR1L	; Mover el valor de W a TMR1L
    bcf	    TMR1IF	; Limpiar bandera de interrupción por overflow	
    endm
 
reiniciar_tmr2 macro	; Reinicio de Timer2
    Banksel PORTA	; Acceder al Bank 0
    movlw   0xFF	; Cargar valor de registro W, valor inicial del tmr2
    movwf   PR2		; Mover el valor de W a PR2
    bcf	    TMR2IF	; Limpiar bandera de interrupción por overflow	
    endm
    
;-------------------------------------------------------------------------------
; Variables a utilizar
;-------------------------------------------------------------------------------
PSECT udata_bank0  ; Variables en banco 0
    ; Para el multiplexado
    flag:	    DS 1
    ; Para el tiempo de los semaforos
    t_s1glob:	    DS 1    
    t_s2glob:	    DS 1
    t_s3glob:	    DS 1
    t_s1:	    DS 1    
    t_s2:	    DS 1
    t_s3:	    DS 1
    t_ind:	    DS 1
    t_s1_temp:	    DS 1     
    t_s2_temp:	    DS 1
    t_s3_temp:	    DS 1
    t_ind_temp:	    DS 1
    temporal1:	    DS 1
    temporal2:	    DS 1
    temporal3:	    DS 1
    ;Para preparar los diplays
    nibble_s1:	    DS 2	
    nibble_s2:	    DS 2
    nibble_s3:	    DS 2
    nibble_ind:	    DS 2
    display_s1:	    DS 2
    display_s2:	    DS 2
    display_s3:	    DS 2
    display_ind:    DS 2
    distemp_s1:	    DS 2
    distemp_s2:	    DS 2
    distemp_s3:	    DS 2
    distemp_ind:    DS 2
    unidades_s1:    DS 1
    unidades_s2:    DS 1
    unidades_s3:    DS 1
    unidades_ind:   DS 1
    decenas_s1:	    DS 1
    decenas_s2:	    DS 1
    decenas_s3:	    DS 1
    decenas_ind:    DS 1
    unidadesf_s1:   DS 1
    unidadesf_s2:   DS 1
    unidadesf_s3:   DS 1
    unidadesf_ind:  DS 1
    decenasf_s1:    DS 1
    decenasf_s2:    DS 1
    decenasf_s3:    DS 1
    decenasf_ind:   DS 1
    ; Para la rutina principal de los semaforos
    estados:	    DS 1
    estados1:	    DS 1
    contador:	    DS 1
    ;Para el menú
    modo:	    DS 1
    rebote:	    DS 1
    aceptar:	    DS 1

    
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
    btfsc   T0IF	; Testear la bandera de interrupción del TMR0
    call    int_tmr0	; Ir a la subrutina del TMR0
    btfsc   TMR1IF	; Testear la bandera de interrupción del TMR1
    call    int_tmr1	; Ir a la subrutina del TMR1
    btfsc   TMR2IF	; Testear la bandera de interrupción del TMR2
    call    int_tmr2	; Ir a la subrutina del TMR2
    btfsc   RBIF	; Si está encendida la bandera, entonces 
    call    seleccion_modo
    
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
   
;-------------------------------------------------------------------------------
; Sub rutinas para interrupciones
;-------------------------------------------------------------------------------
seleccion_modo:
    bcf	    RBIF
    btfsc   PORTB, 0 
    call    cambio_modo
    btfsc   modo, 0
    goto    modo1
    btfsc   modo, 1
    goto    modo2
    btfsc   modo, 2
    goto    modo3
    btfsc   modo, 3
    goto    modo4
    btfsc   modo, 4
    goto    modo5
    return
 
cambio_modo:
    movlw   0x1
    btfsc   modo, 4
    goto    cambio
    movlw   0x10
    btfsc   modo, 3
    goto    cambio
    movlw   0x8
    btfsc   modo, 2
    goto    cambio
    movlw   0x4
    btfsc   modo, 1
    goto    cambio
    movlw   0x2
    btfsc   modo, 0
    goto    cambio
    
cambio:
    movwf   modo
    return
    
modo1:
    clrf    PORTB
    movlw   0
    movwf   t_ind
    call    display_indicador
    return
    
modo2:
    btfsc   PORTB, 1
    goto    inc_temporal3
    btfsc   PORTB, 2
    goto    dec_temporal3
    clrf    PORTB
    bsf	    PORTB, 6
    movf    temporal3, W
    movwf   t_ind
    call    display_indicador
    return
    
inc_temporal3:
    movf temporal3, W
    sublw 21
    btfsc   rebote, 0
    goto    $+4
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    incf  temporal3, F
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    bsf	  rebote, 0
    btfss STATUS, 2 ;si ZERO es 1 entonces mueve el valor de 10 a la variable
    goto $+3
    movlw 10
    movwf temporal3
    return
    
dec_temporal3:
    movf temporal3, W
    sublw 9
    btfsc   rebote, 1
    goto    $+4
    btfss STATUS, 2
    decf temporal3, F
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    bsf	  rebote, 1
    btfss STATUS, 2
    goto $+3
    movlw 20
    movwf temporal3
    return
    
modo3:
    btfsc   PORTB, 1
    goto    inc_temporal1
    btfsc   PORTB, 2
    goto    dec_temporal1
    clrf    PORTB
    bsf	    PORTB, 4
    movf    temporal1, W
    movwf   t_ind
    call    display_indicador
    return
    
inc_temporal1:
    movf temporal1, W
    sublw 21
    btfsc   rebote, 0
    goto    $+4
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    incf  temporal1, F
    btfss STATUS, 2 ;si ZERO es 1 entonces mueve el valor de 10 a la variable
    bsf	  rebote, 0
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    goto $+3
    movlw 10
    movwf temporal1
    return
    
dec_temporal1:
    movf temporal1, W
    sublw 9
    btfsc   rebote, 1
    goto    $+4
    btfss STATUS, 2
    decf temporal1, F
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    bsf	  rebote, 1
    btfss STATUS, 2
    goto $+3
    movlw 20
    movwf temporal1
    return

modo4:
    btfsc   PORTB, 1
    goto    acceder
    btfsc   PORTB, 2
    goto    cancelar
    clrf    PORTB
    bsf	    PORTB, 4
    bsf	    PORTB, 5
    bsf	    PORTB, 6
    movlw   0
    movwf   t_ind
    call    display_indicador
    return
    
acceder:
    clrf    PORTA
    clrf    PORTB
    clrf    estados
    clrf    estados1
    movlw   0x3
    movwf   t_s1
    movwf   t_s2
    movwf   t_s3
    movlw   0x80
    movwf   estados1
    movlw   0x1
    movwf   estados
    return
    
cancelar:
    movf    t_s1glob, W
    movwf   temporal1
    movf    t_s2glob, W
    movwf   temporal2
    movf    t_s3glob, W
    movwf   temporal3
    return
    
modo5:
    btfsc   PORTB, 1
    goto    inc_temporal2
    btfsc   PORTB, 2
    goto    dec_temporal2
    clrf    PORTB
    bsf	    PORTB, 5
    movf    temporal2, W
    movwf   t_ind
    call    display_indicador
    return
    
inc_temporal2:
    movf temporal2, W
    sublw 21
    btfsc   rebote, 0
    goto    $+4
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    incf  temporal2, F
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    bsf	  rebote, 0
    btfss STATUS, 2 ;si ZERO es 1 entonces mueve el valor de 10 a la variable
    goto $+3
    movlw 10
    movwf temporal2
    return
    
dec_temporal2:
    movf temporal2, W
    sublw 9
    btfsc   rebote, 1
    goto    $+4
    btfss STATUS, 2
    decf temporal2, F
    btfss STATUS, 2 ;si ZERO es 0 entonces incrementa 
    bsf	  rebote, 1
    btfss STATUS, 2
    goto $+3
    movlw 20
    movwf temporal2
    return
    
int_tmr2:
    reiniciar_tmr2
    incf    contador
    return
    
int_tmr1:
    reiniciar_tmr1
    decf    t_s1
    decf    t_s2
    decf    t_s3
    return
    
int_tmr0:
    reiniciar_tmr0		; Reiniciar el TMR0
    clrf    PORTD		; Limpiar los displays
    btfsc   flag, 0		; Revisa el bit de la bandera que 
    goto    display_unidades_s1	; enciende el semaforo 1 unidades
    btfsc   flag, 1		; Revisa el bit de la bandera que 
    goto    display_decenas_s1	; enciende el semaforo 1 decenas
    btfsc   flag, 2		; Revisa el bit de la bandera que 
    goto    display_unidades_s2	; enciende el semaforo 2 unidades
    btfsc   flag, 3		; Revisa el bit de la bandera que 
    goto    display_decenas_s2	; enciende el semaforo 2 decenas
    btfsc   flag, 4		; Revisa el bit de la bandera que 
    goto    display_unidades_s3	; enciende el semaforo 3 unidades
    btfsc   flag, 5		; Revisa el bit de la bandera que 
    goto    display_decenas_s3	; enciende el semaforo 3 decenas
    btfsc   flag, 6		; Revisa el bit de la bandera que 
    goto    display_unidades_ind; enciende el semaforo 3 unidades
    btfsc   flag, 7		; Revisa el bit de la bandera que 
    goto    display_decenas_ind	; enciende el semaforo 3 decenas
    
display_unidades_s1:
    movf    unidadesf_s1, W	; El primer byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 0		; Seleccionar unidades
    movlw   0x2			; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
display_decenas_s1:
    movf    decenasf_s1, W	; El segundo byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 1		; Seleccionar decenas
    movlw   0x4			; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
display_unidades_s2:
    movf    unidadesf_s2, W	; El primer byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 2		; Seleccionar unidades
    movlw   0x8			; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
display_decenas_s2:
    movf    decenasf_s2, W	; El segundo byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 3		; Seleccionar decenas
    movlw   0x10		; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
display_unidades_s3:
    movf    unidadesf_s3, W	; El primer byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 4		; Seleccionar unidades
    movlw   0x20		; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
display_decenas_s3:
    movf    decenasf_s3, W	; El segundo byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 5		; Seleccionar decenas
    movlw   0x40		; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
display_unidades_ind:
    movf    unidadesf_ind, W	; El primer byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 6		; Seleccionar unidades
    movlw   0x80		; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
display_decenas_ind:
    movf    decenasf_ind, W	; El segundo byte de display va al registro W
    movwf   PORTC		; Colocar el valor en el PORTC
    bsf	    PORTD, 7		; Seleccionar decenas
    movlw   0x1			; Preparar para siguiente display
    movwf   flag
    goto    siguiente_display	; para que se encienda el sigiente display
    
siguiente_display:
    nop
    return
    
;-------------------------------------------------------------------------------
; Configuración del microcontrolador
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 120h ;Posición para el código

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
    call    config_io		; Configurar entradas y salidas
    call    config_reloj	; Configurar el reloj (oscilador)
    call    config_tmr0		; Configurar el registro de TMR0
    call    config_tmr1		; Configurar el registro de TMR1
    call    config_tmr2		; Configurar el registro de TMR2
    call    config_int		; Configuración de las interrupciones
    call    config_ioc
    call    tiempo_semaforos	; Cargan los valores iniciales
        
loop: 
    call    display_semaforo1	; Preparar el dato decimal del display del s1
    call    display_semaforo2	; Preparar el dato decimal del display del s2
    call    display_semaforo3	; Preparar el dato decimal del display del s3
    btfss   PORTB, 1
    bcf	    rebote, 0
    btfss   PORTB, 1
    bcf	    rebote, 1
    
    btfss   estados, 0
    call    alistar_semaforo1
    btfsc   estados, 1
    call    semaforo1_verde
    btfsc   estados, 2
    call    semaforo1_intermitente
    btfsc   estados, 3
    call    semaforo1_amarillo
    
    btfsc   estados, 4
    call    alistar_semaforo2
    btfsc   estados, 5
    call    semaforo2_verde
    btfsc   estados, 6
    call    semaforo2_intermitente
    btfsc   estados, 7
    call    semaforo2_amarillo
    
    btfsc   estados1, 0
    call    alistar_semaforo3
    btfsc   estados1, 1
    call    semaforo3_verde
    btfsc   estados1, 2
    call    semaforo3_intermitente
    btfsc   estados1, 3
    call    semaforo3_amarillo
    
    btfsc   estados1, 7
    call    estado_cero
    
    goto    loop
  
;-------------------------------------------------------------------------------
; Subrutinas para loop principal
;-------------------------------------------------------------------------------    
alistar_semaforo1:
    clrf    PORTA
    bcf	    PORTB, 3
    movf    t_s1glob, W
    movwf   t_s1
    movwf   t_s2
    addwf   t_s2glob, W
    movwf   t_s3
    movlw   0x3
    movwf   estados
    goto    siguiente_estado
    
semaforo1_verde:
    bcf	    PORTA, 0
    bcf	    PORTA, 7
    bsf	    PORTA, 2
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    movlw   6
    subwf   t_s1, W
    movlw   0x5
    btfsc   STATUS, 2
    movwf   estados
    goto    siguiente_estado

semaforo1_intermitente:
    btfsc   contador, 1
    bcf	    PORTA, 2
    btfss   contador, 1
    bsf	    PORTA, 2
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    movlw   3
    subwf   t_s1, W
    movlw   0x9
    btfsc   STATUS, 2
    movwf   estados  
    goto    siguiente_estado

semaforo1_amarillo:
    bsf	    PORTA, 1
    bcf	    PORTA, 2
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    movlw   0
    subwf   t_s1, W
    movlw   0x11
    btfsc   STATUS, 2
    movwf   estados
    goto    siguiente_estado

alistar_semaforo2:
    clrf    PORTA
    bcf	    PORTB, 3
    movf    t_s2glob, W
    movwf   t_s2
    movwf   t_s3
    addwf   t_s3glob, W
    movwf   t_s1
    movlw   0x21
    movwf   estados
    goto    siguiente_estado
    
semaforo2_verde:
    bsf	    PORTA, 0
    bsf	    PORTA, 5
    bsf	    PORTA, 6
    movlw   6
    subwf   t_s2, W
    movlw   0x41
    btfsc   STATUS, 2
    movwf   estados
    goto    siguiente_estado

semaforo2_intermitente:
    btfsc   contador, 1
    bcf	    PORTA, 5
    btfss   contador, 1
    bsf	    PORTA, 5
    bsf	    PORTA, 0
    bsf	    PORTA, 6
    movlw   3
    subwf   t_s2, W
    movlw   0x81
    btfsc   STATUS, 2
    movwf   estados  
    goto    siguiente_estado

semaforo2_amarillo:
    bsf	    PORTA, 0
    bsf	    PORTA, 4
    bcf	    PORTA, 5
    bsf	    PORTA, 6
    movlw   0
    subwf   t_s2, W
    movlw   0x1
    btfsc   STATUS, 2
    movwf   estados
    movlw   0
    subwf   t_s2, W
    movlw   0x1
    btfsc   STATUS, 2
    movwf   estados1
    goto    siguiente_estado
    
alistar_semaforo3:
    clrf    PORTA
    bcf	    PORTB, 3
    movf    t_s3glob, W
    movwf   t_s1
    movwf   t_s3
    addwf   t_s2glob, W
    movwf   t_s2
    movlw   0x2
    movwf   estados1
    goto    siguiente_estado
    
semaforo3_verde:
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    bsf	    PORTB, 3
    movlw   6
    subwf   t_s3, W
    movlw   0x4
    btfsc   STATUS, 2
    movwf   estados1
    goto    siguiente_estado

semaforo3_intermitente:
    btfsc   contador, 1
    bcf	    PORTB, 3
    btfss   contador, 1
    bsf	    PORTB, 3
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    movlw   3
    subwf   t_s3, W
    movlw   0x8
    btfsc   STATUS, 2
    movwf   estados1  
    goto    siguiente_estado

semaforo3_amarillo:
    bcf	    PORTB, 3
    bsf	    PORTA, 0
    bsf	    PORTA, 7
    bsf	    PORTA, 3
    movlw   0
    subwf   t_s3, W
    movlw   0x0
    btfsc   STATUS, 2
    movwf   estados1
    movlw   0
    subwf   t_s3, W
    movlw   0x0
    btfsc   STATUS, 2
    movwf   estados
    goto    siguiente_estado

estado_cero:
    bsf	    PORTA, 0
    bsf	    PORTA, 3
    bsf	    PORTA, 6
    movlw   0
    subwf   t_s3, W
    movlw   0x0
    btfsc   STATUS, 2
    goto    retorno
    goto    siguiente_estado
    
retorno:
    movf    temporal1, W
    movwf   t_s1glob
    movf    temporal2, W
    movwf   t_s2glob
    movf    temporal3, W
    movwf   t_s3glob
    movlw   0x0
    movwf   estados1
    movlw   0x0
    movwf   estados
    goto    siguiente_estado
    
siguiente_estado:
    nop
    return

display_semaforo1:	
    movf    t_s1, 0	    ; Mueve el tiempo de s1 a W
    andlw   0x0F	    ; Usa los 4 bits menos significativos
    movwf   nibble_s1	    ; Mueve el valor de la variable a nibble
    swapf   t_s1, 0	    ; Cambia los bytes de la variable var
    andlw   0x0F	    ; Solamente toma los primeros 4 bits de la variable
    movwf   nibble_s1+1	    ; Mueve el tiempo de s1 al segundo byte de nibble

    movf    nibble_s1, 0    ; Mueve el valor del primer nibble a W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_s1	    ; Se guarda el primer byte de nibble en el primer byte display
    movf    nibble_s1+1,0   ; Mueve el valor del segundo nibble al registro W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_s1+1    ; Se guarda el segundo byte de nibble en el segundo byte display
    
    movf    t_s1, 0	    ; Mueve el valor del contador al registro W
    movwf   t_s1_temp	    ; Mueve el valor a una variable temporal
    
    clrf    unidades_s1	    ; Se limpian las variables a utilizar 
    clrf    decenas_s1
    
    movlw 10		    ; Revisión decenas
    subwf t_s1_temp,1	    ; Se restan 10 a la variable temporal
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    incf decenas_s1, 1	    ; Si C=1 entonces es menor a 10 y no incrementa la variable
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    goto $-4
    addwf t_s1_temp,1	    ; Se regresa la variable temporal a su valor original
    
    movf t_s1_temp, 0	    ; Se mueve lo restante en la variable temporal a la
    movwf unidades_s1	    ; variable de unidades
    
    clrf    unidadesf_s1    ; Se limpian las variables
    clrf    decenasf_s1
    
    movf    decenas_s1, 0
    call    tabla
    movwf   decenasf_s1
    
    movf    unidades_s1, 0
    call    tabla
    movwf   unidadesf_s1
    
    return 
    
display_semaforo2:
    movf    t_s2, 0	    ; Mueve el valor de la variable al registro W
    andlw   0x0F	    ; Solamente toma los primeros 4 bits de la variable
    movwf   nibble_s2	    ; Mueve el valor de la variable a nibble
    swapf   t_s2, 0	    ; Cambia los bytes de la variable var
    andlw   0x0F	    ; Solamente toma los primeros 4 bits de la variable
    movwf   nibble_s2+1	    ; Mueve el valor de la variable al segundo byte de nibble

    movf    nibble_s2, 0    ; Mueve el valor del primer nibble al registro W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_s2	    ; Se guarda el primer byte de nibble en el primer byte display
    movf    nibble_s2+1,0   ; Mueve el valor del segundo nibble al registro W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_s2+1    ; Se guarda el segundo byte de nibble en el segundo byte display
    
    movf    t_s2, 0	    ; Mueve el valor del contador al registro W
    movwf   t_s2_temp	    ; Mueve el valor a una variable temporal
    
    clrf    unidades_s2	    ; Se limpian las variables a utilizar 
    clrf    decenas_s2
    
    movlw 10		    ; Revisión decenas
    subwf t_s2_temp,1	    ; Se restan 10 a la variable temporal
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    incf decenas_s2, 1	    ; Si C=1 entonces es menor a 10 y no incrementa la variable
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    goto $-4
    addwf t_s2_temp,1	    ; Se regresa la variable temporal a su valor original
    
    movf t_s2_temp, 0	    ; Se mueve lo restante en la variable temporal a la
    movwf unidades_s2	    ; variable de unidades
    
    clrf    unidadesf_s2    ; Se limpian las variables
    clrf    decenasf_s2
    
    movf    decenas_s2, 0
    call    tabla
    movwf   decenasf_s2
    
    movf    unidades_s2, 0
    call    tabla
    movwf   unidadesf_s2
    
    return 
    
display_semaforo3:
    movf    t_s3, 0	    ; Mueve el valor de la variable al registro W
    andlw   0x0F	    ; Solamente toma los primeros 4 bits de la variable
    movwf   nibble_s3	    ; Mueve el valor de la variable a nibble
    swapf   t_s3, 0	    ; Cambia los bytes de la variable var
    andlw   0x0F	    ; Solamente toma los primeros 4 bits de la variable
    movwf   nibble_s3+1	    ; Mueve el valor de la variable al segundo byte de nibble

    movf    nibble_s3, 0    ; Mueve el valor del primer nibble al registro W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_s3	    ; Se guarda el primer byte de nibble en el primer byte display
    movf    nibble_s3+1,0   ; Mueve el valor del segundo nibble al registro W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_s3+1    ; Se guarda el segundo byte de nibble en el segundo byte display
    
    
    movf    t_s3, 0	    ; Mueve el valor del contador al registro W
    movwf   t_s3_temp	    ; Mueve el valor a una variable temporal
    
    clrf    unidades_s3	    ; Se limpian las variables a utilizar 
    clrf    decenas_s3
    
    movlw 10		    ; Revisión decenas
    subwf t_s3_temp,1	    ; Se restan 10 a la variable temporal
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    incf decenas_s3, 1	    ; Si C=1 entonces es menor a 10 y no incrementa la variable
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    goto $-4
    addwf t_s3_temp,1	    ; Se regresa la variable temporal a su valor original
    
    movf t_s3_temp, 0	    ; Se mueve lo restante en la variable temporal a la
    movwf unidades_s3	    ; variable de unidades
    
    clrf    unidadesf_s3    ; Se limpian las variables
    clrf    decenasf_s3
    
    movf    decenas_s3, 0
    call    tabla
    movwf   decenasf_s3
    
    movf    unidades_s3, 0
    call    tabla
    movwf   unidadesf_s3
    
    return 
    
display_indicador:
    movf    t_ind, 0	    ; Mueve el valor de la variable al registro W
    andlw   0x0F	    ; Solamente toma los primeros 4 bits de la variable
    movwf   nibble_ind	    ; Mueve el valor de la variable a nibble
    swapf   t_ind, 0	    ; Cambia los bytes de la variable var
    andlw   0x0F	    ; Solamente toma los primeros 4 bits de la variable
    movwf   nibble_ind+1    ; Mueve el valor de la variable al segundo byte de nibble

    movf    nibble_ind, 0   ; Mueve el valor del primer nibble al registro W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_ind	    ; Se guarda el primer byte de nibble en el primer byte display
    movf    nibble_ind+1,0  ; Mueve el valor del segundo nibble al registro W
    call    tabla	    ; Conversion del nibble para el display
    movwf   display_ind+1   ; Se guarda el segundo byte de nibble en el segundo byte display
    
    
    movf    t_ind, 0	    ; Mueve el valor del contador al registro W
    movwf   t_ind_temp	    ; Mueve el valor a una variable temporal
    
    clrf    unidades_ind	    ; Se limpian las variables a utilizar 
    clrf    decenas_ind
    
    movlw 10		    ; Revisión decenas
    subwf t_ind_temp,1	    ; Se restan 10 a la variable temporal
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    incf decenas_ind, 1	    ; Si C=1 entonces es menor a 10 y no incrementa la variable
    btfsc STATUS, 0	    ; Revisión de la bandera de Carry
    goto $-4
    addwf t_ind_temp,1	    ; Se regresa la variable temporal a su valor original
    
    movf t_ind_temp, 0	    ; Se mueve lo restante en la variable temporal a la
    movwf unidades_ind	    ; variable de unidades
    
    clrf    unidadesf_ind    ; Se limpian las variables
    clrf    decenasf_ind
    
    movf    decenas_ind, 0
    call    tabla
    movwf   decenasf_ind
    
    movf    unidades_ind, 0
    call    tabla
    movwf   unidadesf_ind
    
    return 

;-------------------------------------------------------------------------------
; Subrutinas de configuración
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL   ; Acceder al Bank 3
    clrf    ANSEL   ; Selección de pines digitales
    clrf    ANSELH  ; Selección de pines digitales
    
    banksel TRISA   ; Acceder al Bank 1
    clrf    TRISA   ; Luces de semaforos
    clrf    TRISC   ; Display 7seg 
    clrf    TRISD   ; Multiplexado de displays
    clrf    TRISE   ; Luces indicadoras
    
    bsf	    TRISB, 0	; Push button modo
    bsf	    TRISB, 1	; Push button incremento 
    bsf	    TRISB, 2	; Push button decremento 
    bcf	    TRISB, 3
    bcf	    TRISB, 4
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    
    banksel PORTA   ; Acceder al Bank 3
    clrf    PORTA   ; Comenzar luces del semaforo apagado
    clrf    PORTB
    clrf    PORTC   ; Comenzar displays apagados
    clrf    PORTD   ; Comenzar el multiplexado apagado
    clrf    PORTE   ; Comenzar luces de indicadores apagados
    return
    
tiempo_semaforos:   ; Se cargan los valores iniciales de los semaforos
    movlw   10
    movwf   t_s1glob
    movwf   temporal1
    movlw   12
    movwf   t_s2glob
    movwf   temporal2
    movlw   15
    movwf   t_s3glob
    movwf   temporal3
    clrf    estados
    movlw   1
    movwf   modo
    movlw   0
    movwf   t_ind
    call    display_indicador
    
    
    return
    
config_int:
    Banksel PORTA   ; Acceder al Bank 0
    bsf	GIE	    ; Se habilitan las interrupciones globales
    bsf	PEIE	    ; Se habilitan las interrupciones perifericas
    bsf	RBIE	    ; Se habilita la interrupción de las resistencias pull-ups 
    bcf	RBIF	    ; Se limpia la bandera
    bsf	T0IE	    ; Se habilitan la interrupción del TMR0
    bcf	T0IF	    ; Se limpia la bandera
    
    Banksel TRISA   ; Acceder al Bank 1
    bsf	TMR1IE	    ; Se habilitan la interrupción del TMR1 Registro PIE1
    bsf	TMR2IE	    ; Se habilitan la interrupción del TMR2 Registro PIE1
    Banksel PORTA   ; Acceder al Bank 0
    
    bcf	TMR1IF	    ; Se limpia la bandera Registro PIR1
    bcf	TMR2IF	    ; Se limpia la bandera Registro PIR1
    return  
   
config_ioc:
    banksel TRISA
    bsf	    IOCB, 0 ;Se habilita el Interrupt on change de los pines
    bsf	    IOCB, 1
    bsf	    IOCB, 2    
    banksel PORTA
    movf    PORTB, 0 ; Termina condición de mismatch
    bcf	    RBIF     ; Se limpia la bandera
    return

config_reloj:	
    Banksel OSCCON  ; Acceder al Bank 1
    bsf	    IRCF2
    bcf	    IRCF1
    bcf	    IRCF0   ; Configuración del oscilador a 1MHz
    bsf	    SCS	    ; Seleccionar el reloj interno
    return
    
config_tmr0:
    Banksel TRISA   ; Acceder al Bank 1
    bcf	    T0CS    ; Tmr0 funciona con reloj interno
    bcf	    PSA	    ; Prescaler asignado a Timer0
    bcf	    PS2	    
    bcf	    PS1
    bcf	    PS0	    ; Prescaler de 1:2
    reiniciar_tmr0  ; Reiniciar conteo del tmr0
    return

config_tmr1:
    Banksel PORTA   ; Acceder al Bank 0
    bsf	    TMR1ON  ; Habilitar Timer1
    bcf	    TMR1CS  ; Selección del reloj interno
    bsf	    T1CKPS0
    bsf	    T1CKPS1 ; Prescaler de 1:8
    reiniciar_tmr1  ; Reiniciar conteo del tmr1
    return 
    
config_tmr2:
    banksel PORTA   ; Acceder al Bank 0
    bsf TMR2ON	    ; Timer2 is on
    bsf TOUTPS3	    ; Postscaler de 1:16
    bsf TOUTPS2
    bsf TOUTPS1
    bsf TOUTPS0
    bsf T2CKPS1	    ; Prescaler de 1:16
    bsf TOUTPS0
    reiniciar_tmr2  ; Reiniciar conteo del tmr2
    return  
end