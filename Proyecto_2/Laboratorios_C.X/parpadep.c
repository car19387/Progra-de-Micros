//******************************************************************************
//  Encabezado
//******************************************************************************
/* Archivo: Proyecto2
 * Dispositivo: PIC16f887
 * Autor: Jefry Carrasco
 * Descripción: 
 * Grua controlada por potenciometros y foto resistencias con interfaz gráfica 
 * para el control de actuadores y visualización de valores.
 * Hardware: 
 * 1 PIC16F887
 * 1 Virtual Terminal
 * 4 Servomotores
 * 2 Leds
 * 1 Motor DC
 * 1 Modulo puente H
 * 4 Push buttoms
 * 1 Fotoresistencia
 * 5 Potenciometros
 * Creado: 17 de mayo, 2021
 * Modificado:  de mayo, 2021 */  

//******************************************************************************
// Librerías incluidas
//******************************************************************************
#include <xc.h>                 // Librería XC8
#include <string.h>             // Libreria para manipular cadena de caracteres

//******************************************************************************
// Configuración de PIC16f887
//******************************************************************************

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = ON       // Power-up Timer Enable bit (PWRT enabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

//******************************************************************************
// Directivas del preprocesador
//******************************************************************************
#define _XTAL_FREQ 1000000      // Frecuencia del reloj a 1MHz

//******************************************************************************
// Variables
//******************************************************************************
char tab7seg[10]={0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39};
unsigned char val_motordc = 0;
unsigned char val_leds = 0;
unsigned char val_giro = 0;
unsigned char val_articulacion_base = 0;
unsigned char val_articulacion_codo = 0;
unsigned char val_pinza = 0;
char bandera = 1;
char menu = 0;
char indicador = 0;
unsigned char contador = 0;

//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void printf(char *var);         // Función para imprimir texto en terminal
void printval(char valor);      // Función para imprimir valores en terminal
void setup();                   // Configuraciones del PIC
void config_io();               // Configurar entradas y salidas
void config_reloj();            // Configurar reloj
void config_adc();              // Configurar módulo ADC
void config_serial();           // Configurar comunicación serial
void config_pwm();              // Configurar PWM
void config_TMR0();             // Configurar TMR0
void config_TMR2();             // Configurar TMR2
void config_int_enable();       // Enable interrupciones

//******************************************************************************
// Main
//******************************************************************************
void main(void) {
    setup();                    // Ir a las configuraciones
    ADCON0bits.GO = 1;          // Iniciar ADC
    TXREG = 12;                 // Limpiar consola
    
    //**************************************************************************
    // Loop principal
    //**************************************************************************
    while(1){
        if (PIR1bits.TXIF) {                // Interrupción TXREG empty
             if (bandera == 1) {             // Si la bandera esta encendida
                TXREG = 12;                 // Limpiar consola
                printf("Que opcion desea ejecutar?");   // Imprimir texto
                TXREG = 13;                             // Salto de línea
                printf("1) Desplegar el valor de los potenciometros");
                TXREG = 13;                             // Salto de línea
                printf("2) Modificar el valor de los actuadores");
                TXREG = 13;                             // Salto de línea
                printf("3) Guardar una posicion");
                TXREG = 13;                             // Salto de línea
                printf("4) Ejecutar una posicion");
                TXREG = 13;                             // Salto de línea
                TXREG = 13;                             // Salto de línea
                printf("Nota: Para salir de cualquier opcion presionar SPACE");
                TXREG = 13;                             // Salto de línea
                bandera = 0;                            // Apagar bandera
            }
            
            if (menu == 49) {                   // Si presiona 1
                indicador = 1;                  // Levantar bandera de indicador
                printf("Val art base: ");       // Imprimir etiqueta
                printval(val_articulacion_base);// Imprimir valor     
                printf("    Val art codo: ");   // Imprimir etiqueta
                printval(val_articulacion_codo);// Imprimir valor
                printf("    Val pinza: ");      // Imprimir etiqueta
                printval(val_pinza);            // Imprimir valor
                printf("    Val giro: ");       // Imprimir etiqueta
                printval(val_giro);             // Imprimir valor 
                printf("    Val leds: ");       // Imprimir etiqueta
                printval(val_leds);             // Imprimir valor
                printf("    Val motor: ");      // Imprimir etiqueta
                printval(val_motordc);          // Imprimir valor
                printf(" ");                    // Imprimir etiqueta
                TXREG = 13;                     // Agrega una nueva línea
                
            }
            
            if (menu == 50) {                   // Si presiona 2
                indicador = 1;
                printf("estoy en 2");
            }
            
            if (menu == 51) {                   // Si presiona 3
                indicador = 1;
                printf("estoy en 3");
            }
            
            if (menu == 52) {                   // Si presiona 4
                indicador = 1;
                printf("estoy en 4");
            }
        }
        
        if(ADCON0bits.GO == 0){         // Si la bandera del ADC se bajó   
            if (ADCON0bits.CHS == 5){   // Si está en el canal 5
                ADCON0bits.CHS = 6;     // Entonces pasa al canal 0
            }
            
            if (ADCON0bits.CHS == 4){   // Si está en el canal 4
                ADCON0bits.CHS = 5;     // Entonces pasa al canal 5
            }
            
            if (ADCON0bits.CHS == 3){   // Si está en el canal 3
                ADCON0bits.CHS = 4;     // Entonces pasa al canal 4
            }
            
            if (ADCON0bits.CHS == 2){   // Si está en el canal 2
                ADCON0bits.CHS = 3;     // Entonces pasa al canal 3
            }
            
            if (ADCON0bits.CHS == 1){   // Si está en el canal 1
                ADCON0bits.CHS = 2;     // Entonces pasa al canal 2
            }
            
            if (ADCON0bits.CHS == 0){   // Si está en el canal 0
                ADCON0bits.CHS = 1;     // Entonces pasa al canal 1
            }
            
            if (ADCON0bits.CHS == 6){   // Si está en el canal 6
                ADCON0bits.CHS = 0;     // Entonces pasa al canal 0
            }
            
            __delay_us(50);             //Delay para sample and hold
            ADCON0bits.GO = 1;          //Levantar bandera para conversión ADC
        }
    }
    return;
}

//******************************************************************************
// Interrupciones
//******************************************************************************
void __interrupt() isr(void) {
    if (PIR1bits.ADIF) {                // Interrupción del ADC
        if(ADCON0bits.CHS == 0) {       // Si está en el canal 0
            val_articulacion_base = ADRESH; // Se carga valor
        }
        
        if(ADCON0bits.CHS == 1) {       // Si está en el canal 1
            val_articulacion_codo = ADRESH; // Se carga valor
        }
        
        if(ADCON0bits.CHS == 2) {       // Si está en el canal 2
            val_pinza = ADRESH;         // Se carga valor a val_pinza
        }
        
        if(ADCON0bits.CHS == 3) {       // Si está en el canal 3
            val_giro = ADRESH;          // Se carga valor a val_giro
        }
        
        if(ADCON0bits.CHS == 4) {       // Si está en el canal 4
            CCPR1L = ADRESH;            // Se carga valor a CCPR1L
            val_leds = ADRESH;          // Se carga valor a val_leds
        }
        
        if(ADCON0bits.CHS == 5) {       // Si está en el canal 5
            CCPR2L = ADRESH;            // Se carga valor a CCPR2L
            val_motordc = ADRESH;       // Se carga valor a val_motor
        }
        
        PIR1bits.ADIF = 0;              // Limpiar la bandera de ADC
    }
    
    if (PIR1bits.RCIF) {                // Bandera de comunicación entrante
        if (indicador == 0) {           // Si indicador esta bajo
            menu = RCREG;               // Se guarda com entrante en menu
            TXREG = 12;                 // Limpiar consola
        }
        
        if (RCREG == 32) {              // Si se preciona SPACE
            menu = 0;                   // Menu es 0
            bandera = 1;                // Se levanta bandera
            indicador = 0;              // Se apaga el indicador
            TXREG = 12;                 // Limpiar consola
        }
    }
    
    if (INTCONbits.T0IF) {
        TMR0 = 255-((val_leds>>1)+120);
        PORTBbits.RB4 = !PORTBbits.RB4;
        INTCONbits.T0IF = 0;
        
    }
    return;
}

//******************************************************************************
// Configuraciones
//******************************************************************************
void setup() {
    config_io();
    config_reloj();
    config_adc();
    config_serial();
    config_pwm();
    config_TMR0();
    config_TMR2();
    config_int_enable();
    return;
}

void config_io() {
    ANSELH = 0x00;                  // Pines digitales
    ANSEL = 0xFF;                   // AN0 - AN5 como analógicos
    
    TRISA = 0xFF;                   // Para entrada de los potenciometros
    TRISB = 0x00;                   // Para controlar servomotores
    TRISCbits.TRISC1 = 0;
    TRISCbits.TRISC2 = 0;
    TRISE = 0xFF;                   //¨Para entrada de los potenciometros
               
    PORTB = 0x00;                   // Se limpian los puertos
}
 
void config_reloj() {
    OSCCONbits.IRCF2 = 1;           //Frecuencia a 1MHZ
    OSCCONbits.IRCF1 = 0;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS = 1;             // Habilitar reloj interno
}
    
void config_adc() {   
    ADCON1bits.ADFM = 0;            // Justifiación a la izquierda
    ADCON1bits.VCFG0 = 0;           // Voltaje de referencia Vss y Vdd
    ADCON1bits.VCFG1 = 0;   
    
    ADCON0bits.ADCS = 2;            // ADC clokc perdiod (TAD) Fosc/32
    ADCON0bits.CHS = 0;             // Canal 0 selecionado (AN0)
    ADCON0bits.ADON = 1;            // Enecender módulo ADC
    __delay_us(50);
}

void config_serial() {   
    TXSTAbits.SYNC = 0;             // Comunicación asincrona
    TXSTAbits.BRGH = 1;             // High Speed
    
    BAUDCTLbits.BRG16 = 1;          // 16 baud rate en uso
    
    SPBRG = 25;                     // Valor para Baud Rate
    SPBRGH = 0;             
    
    RCSTAbits.SPEN = 1;             // Se habilita TX y RX
    RCSTAbits.RX9 = 0;              // 8 bits de recepción
    RCSTAbits.CREN = 1;             // Se habilita recibimiento continuo
    TXSTAbits.TXEN = 1;             // Se habilita la transimisión
}

void config_pwm() { 
    CCP1CONbits.P1M = 0;            // PWM single output
    CCP1CONbits.CCP1M = 0b1100;     // Se selecciona el modo PWM de CCP1  
    CCP2CONbits.CCP2M = 0b1100;     // Se selecciona el modo PWM de CCP2
    
    CCPR1L = 0x0F;                  // Valor inicial de CCPR1L
    CCPR2L = 0x0F;                  // Valor inicial de CCPR2L
    CCP1CONbits.DC1B = 0;           // Bits menos significativos del Duty Cycle
    CCP2CONbits.DC2B1 = 0;
    CCP2CONbits.DC2B0 = 0;
}

void config_TMR0() {
    OPTION_REGbits.T0CS = 0;    // Modo contador
    OPTION_REGbits.PSA = 0;     // Prescaler asignado a TMR0
    OPTION_REGbits.PS0 = 0;     // Bits para prescaler (1:2)
    OPTION_REGbits.PS1 = 0;
    OPTION_REGbits.PS2 = 0;
    TMR0 = 0;                   // Mover valor al registro TMR0
    INTCONbits.T0IF = 0;        // Se apaga la bandera de TMR0
}

void config_TMR2() {
    T2CONbits.T2CKPS1 = 1;          // Prescaler de 16
    T2CONbits.T2CKPS0 = 1;
    T2CONbits.TMR2ON = 1;           // Se enciende el TMR2
    PR2 = 250;                      // Valor inicial de PR2
    PIR1bits.TMR2IF = 0;            // Se limpia la bandera
    
    while (!PIR1bits.TMR2IF);       // Se espera una interrupción
    PIR1bits.TMR2IF = 0;            // Se limpia la bandera
}

void config_int_enable() {   
    INTCONbits.GIE = 1;             // Se habilitan las interrupciones globales
    INTCONbits.PEIE = 1;            // Se habilitan las interrupciones perifericas
    
    PIE1bits.ADIE = 1;              // Se habilita la interrupcion del ADC
    PIR1bits.ADIF = 0;              // Se limpia la bandera del ADC
    
    PIE1bits.RCIE = 1;              // Se habilita la interrupción de RCREG
    PIR1bits.RCIF = 0;              // Se apaga la bandera te RCREG
    
    INTCONbits.T0IE = 1;            // Se habilita la interrupción de TMR0
    INTCONbits.T0IF = 0;            // Se apaga la bandera de TMR0
}

void printf(char *var){
    for (int i = 0; i < strlen(var); i++) { // Ciclo FOR para transmición
        __delay_ms(1);          
        TXREG = var[i];             // Transmisión de caracteres a la terminal
    }
} 

void printval(char valor){
    char centenas = valor/100;      // Se obtiene el valor de centenas
    char decenas_temp = valor%100;  // El residuo se almacena en la var temporal
    char decenas = decenas_temp/10; // Se obtiene el valor de decenas
    char unidades = valor%10;       // Se obtiene el valor de unidades 
    TXREG = tab7seg[centenas];      // Transmitir unidades
    __delay_us(500);                
    TXREG = tab7seg[decenas];       // Transmitir decenas
    __delay_us(500);                 
    TXREG = tab7seg[unidades];      // Transmitir unidades
    __delay_us(500);   
}





