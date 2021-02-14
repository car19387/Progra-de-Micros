;Archivo: Lab2
;Dispositivo: PIC16f887
;Autor:	Jefry Carrasco
;Programa: Sumador de 4 bits
;Hardware: Leds en el puerto A, C y D, 
;pushButtoms en el puerto B
;Creado: 9 febrero, 2021
;Modificado: 13 febrero, 2021   

#include "pic16f887.inc"
    
;configuración
CONFIG FOSC=XT ;Configurar oscilador externo
CONFIG WDTE=OFF ;Reinicio repetitivo del PIC desactivado
CONFIG PWRTE=ON ;Espera de 72ms al iniciar
CONFIG MCLRE=OFF ;MCLR se utiliza como I/O
CONFIG CP=OFF ;Sin proteccion de codigo
CONFIG CPD=OFF ;Sin proteccion de datos

CONFIG BOREN=OFF ;Sin reinicio si el voltaje cae debajo de 4V durante un período de 100us o más
CONFIG IESO=OFF ;Esto permite que el dispositivo cambie entre relojes internos y externos
CONFIG FCMEN=OFF ;Cambio de reloj externo a interno en caso de fallo 
CONFIG LVP=ON ;Programaciòn en bajo voltaje permitida

CONFIG WRT=OFF ;Protecciòn de autoescritura por el programa desactivado
CONFIG BOR4V=BOR40V ;Reinicio abajo de 4V, (BOR21v=2.1V)
    
;vector reset
PSECT resVect, class=CODE, abs, delta=2
ORG 00h ;Posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main

;config de microcontrolador
PSECT code, delta=2, abs
ORG 100h ;Posición para el código

main:
    bsf	    STATUS, 5  ; Configurar bit 5 de STATUS como 1
    bsf	    STATUS, 6  ; COnfigurar bit 6 de STATUS como 1
    ;Alternativa 
    ;Banksel  ANSEL        Banco 11
    ;ANSEL y ANSELH están en el mismo banco por lo que se pueden configurar ambos
    
    clrf    ANSEL  ; Apagar los analógicos
    clrf    ANSELH  ; Apagar los analógicos
    
    bsf	    STATUS, 5 ; Configurar bit 5 de STATUS como 1
    bcf	    STATUS, 6 ; Configurar bit 6 de STATUS como 0
    ;Alternativa 
    ;Banksel TRISA        Banco 01
    ;TRISA, TRISB, TRISC, TRISD están en el mismo banco por lo que se pueden congigurar todos
    
    clrf    TRISA  ; Puerto A como salida
    movlw   0xFF   ; Colocar 1111 1111 en W
    movwf   TRISB  ; Puerto B como entrada
    clrf    TRISC  ; Puerto C como salida
    clrf    TRISD  ; Puerto D como salida
    
    bcf	    STATUS, 5 ; Configurar bit 5 de STATUS como 0
    bcf	    STATUS, 6 ; Configurar bit 6 de STATUS como 0
    ;Alternativa
    ;Banksel PORTA       Banco 00
    
    movlw   0x0	; Colocar 0x0 en W, apagar todas las salidas
    movwf   PORTA
    movwf   PORTC
    movwf   PORTD
    
;principal loop
loop:
    btfss   PORTB, 0	;Si PB1+ es 0 entra a subrutina
    call    inc_contador1  ;Entrar a subrutina incrementar contador 1
    
    btfss   PORTB, 1	;Si PB1- es 0 entra a subrutina
    call    dec_contador1  ;Entrar a subrutina decrementar contador 1
    
    btfss   PORTB, 2	;Si PB2+ es 0 entra a subrutina
    call    inc_contador2  ;Entrar a subrutina incrementar contador 2
    
    btfss   PORTB, 3	;Si PB2- es 0 entra a subrutina
    call    dec_contador2  ;Entrar a subrutina decrementar contador 2
    
    btfss   PORTB, 4	;Si Resultado es 0 entra a subrutina
    call    Resultado	   ;Entrar a subrutina resultado de suma de contadores
    goto    loop    ;Regresar al inicio del loop

;sub rutina
inc_contador1:
    btfss   PORTB, 0  ; Antirebote
    goto    $-1
    incf    PORTA, 1  ; Incremento
    movlw   0x0	      ; Valor para apagar los 4 bits
    btfsc   PORTA, 4  ; Si sucede 0001 0000
    movwf   PORTA     ; Entonces vuelve el PORT A xx00 0000
    return

dec_contador1:
    btfss   PORTB, 1  ; Antirebote
    goto    $-1
    decf    PORTA, 1  ; Decremento
    movlw   0xF       ; Valor para enceder los 4 bits
    btfsc   PORTA, 5  ; Si sucede xx10 0000
    movwf   PORTA     ; Entonces vuelve el PORT A xx00 1111
    return

inc_contador2:
    btfss   PORTB, 2  ; Antirebote
    goto    $-1
    incf    PORTC, 1  ; Incremento
    movlw   0x0       ; Valor para apagar los 4 bits
    btfsc   PORTC, 4  ; Si sucede 0001 0000
    movwf   PORTC     ; Entonces vuelve el PORTC 0000 0000
    return

dec_contador2:
    btfss   PORTB, 3  ; Antirebote
    goto    $-1
    decf    PORTC, 1  ; Decremento
    movlw   0xF       ; Valor para encender los 4 bits
    btfsc   PORTC, 7  ; Si sucede 1000 0000
    movwf   PORTC     ; Entonces vuelve el PORTC 0000 1111
    return

Resultado:
    btfss   PORTB, 4  ; Antirebote
    goto    $-1
    movf    PORTA, W  ; Mover valor de PORTA a W
    addwf   PORTC, 0  ; Suma de W(PORTA) con PORTC, 
    movwf   PORTD     ; Mueve el valor de la suma al PORTD
    return
    
end