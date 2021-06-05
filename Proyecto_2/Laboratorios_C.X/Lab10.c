//******************************************************************************
//  Encabezado
//******************************************************************************
/* Archivo: Lab10
 * Dispositivo: PIC16f887
 * Autor: Jefry Carrasco
 * Descripción: 
 * Comunicación serial entre el PIC y terminal virtual, desde la terminal se
 * seleccional lo que realizarpa el PIC
 * Hardware: 
 * 1 PIC16F887
 * 1 Virtual Terminal
 * 16 Resistencias de 220
 * 16 Leds
 * Creado: 3 de mayo, 2021
 * Modificado: 4 de mayo, 2021 */  

//******************************************************************************
// Librerías incluidas
//******************************************************************************
#include <xc.h>                 // Librería XC8

//******************************************************************************
// Configuración de PIC16f887
//******************************************************************************

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT enabled)
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
char menu[96]={0x42,0x54,0x52,0x4F,0x50,0x20,0x72,0x61,0x69,0x62,0x6D,0x61,0x43,
0x20,0x29,0x33,0x28,0x0D,0x41,0x54,0x52,0x4F,0x50,0x20,0x72,0x61,0x69,0x62,0x6D,
0x61,0x43,0x20,0x29,0x32,0x28,0x0D,0x73,0x65,0x72,0x65,0x74,0x63,0x61,0x72,0x61,
0x63,0x20,0x65,0x64,0x20,0x61,0x6E,0x65,0x64,0x61,0x63,0x20,0x72,0x61,0x67,0x65,
0x6C,0x70,0x73,0x65,0x44,0x20,0x29,0x31,0x28,0x0D,0x72,0x61,0x74,0x75,0x63,0x65,
0x6A,0x65,0x20,0x61,0x65,0x73,0x65,0x64,0x20,0x6E,0x6F,0x69,0x63,0x63,0x61,0x20,
0x65,0x75,0x51};    // Texto del menú

char cadena[30]={0x2E,0x2E,0x2E,0x66,0x65,0x64,0x63,0x62,0x61,0x0D,0x73,0x65,
0x72,0x65,0x74,0x63,0x61,0x72,0x61,0x63,0x20,0x65,0x64,0x20,0x61,0x6E,0x65,0x64,
0x61,0x43};   //Cadena de la parte1

char puertoA[32]={0x41,0x54,0x52,0x4F,0x50,0x20,0x6E,0x65,0x20,0x72,0x65,0x74,
0x63,0x61,0x72,0x61,0x63,0x20,0x6F,0x76,0x65,0x75,0x6E,0x20,0x72,0x61,0x73,0x65,
0x72,0x67,0x6E,0x49};   // Menú de PORTA

char puertoB[32]={0x42,0x54,0x52,0x4F,0x50,0x20,0x6E,0x65,0x20,0x72,0x65,0x74,
0x63,0x61,0x72,0x61,0x63,0x20,0x6F,0x76,0x65,0x75,0x6E,0x20,0x72,0x61,0x73,0x65,
0x72,0x67,0x6E,0x49};   // Menú de PORTB

char caso = 1;      // Bandera para menú principal
char puntm = 96;    // Puntero para menú principal
char punt1 = 30;    // Puntero para cadena de texto
char punt2 = 32;    // Puntero para menú de PORTA
char punt3 = 32;    // Puntero para menú de PORTB

//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup();                   // Configuraciones del PIC
void config_io();               // Configurar entradas y salidas
void config_reloj();            // Configurar reloj
void config_serial();           // Configurar comunicación serial
void config_int_enable();       // Enable interrupciones

//******************************************************************************
// Main
//******************************************************************************
void main(void) {
    setup();                    // Ir a las configuraciones
    
    //**************************************************************************
    // Loop principal
    //**************************************************************************
    while(1){

        if (PIR1bits.TXIF) {                // Interrupción TXREG empty
            
            if (caso == 1 ){                // Si la bandera del menú se levanta
                TXREG = 12;                 // Limpiar consola
                while(puntm > 0){           // Ciclo para escribir el menú princ
                    puntm = puntm-1;        // Cambio de letra
                    TXREG = menu[puntm];    // Escritura de texto
                    __delay_ms(1);          // Delay para transmisión
                }
                caso = 0;                   // Baja la bandera del menú princ
                puntm = 96;                 // Restaurar puntero
            }
        }
    }
    return;
}

//******************************************************************************
// Interrupciones
//******************************************************************************
void __interrupt() isr(void) {
    if (PIR1bits.RCIF) {                    // Interrupción RCREG full        
        if (RCREG == 49){                   // Si presiona 1
            TXREG = 12;                     // Limpiar consola
            while(punt1 > 0){               // Ciclo para cadena de texto
                punt1 = punt1-1;            // Cambio de letra
                TXREG = cadena[punt1];      // Escritura de texto
                __delay_ms(1);              // Delay para transmisión
            }
            __delay_ms(3000);               // Delay para mostrar texto
            caso = 1;                       // Levantar bandera de menú princ
            punt1 = 30;                     // Restarura puntero
        }
        
        if (RCREG == 50){                   // Si presiona 2
            TXREG = 12;                     // Limpiar consola
            while(punt2 > 0){               // Ciclo para menú de PORTA
                punt2 = punt2-1;            // Cambio de letra
                TXREG = puertoA[punt2];     // Escritura de texto
                __delay_ms(1);              // Delay para transmisión
            }
            TXREG = 0x0D;                   // Salto de linea
            RCREG = 0x01;                   // Se escribe 0x01 en RCREG    
            while(RCREG != 0){              // Ciclo para menú de PORTB
                if(RCREG != 1){             // Si RCREG no es 0x01
                    TXREG = RCREG;          // Copiar RCREG a consola
                    PORTA = RCREG;          // Copiar RCREG a PORTA
                    __delay_ms(1500);       // Delay para transmisión
                    RCREG = 0;              // Poner RCREG en 0 para salir
                }       
            }
            caso = 1;                       // Levantar bandera de menú princ
            punt2 = 32;                     // Restaurar puntero
        }
        
        if (RCREG == 51){                   // Si presiona 3
            TXREG = 12;                     // Limpiar consola
            while(punt3 > 0){               // Ciclo para menú de PORTB
                punt3 = punt3-1;            // Cambio de letra
                TXREG = puertoB[punt3];     // Escritura de texto
                __delay_ms(1);              // Delay para transmisión
                }
            TXREG = 0x0D;                   // Salto de linea
            RCREG = 0x01;                   // Se escribe 0x01 en RCREG
            while(RCREG != 0){              // Ciclo para menú de PORTB
                if(RCREG != 1){             // Si RCREG no es 0x01
                    TXREG = RCREG;          // Copiar RCREG a consola
                    PORTB = RCREG;          // Copiar RCREG a PORTB
                    __delay_ms(1500);       // Delay para transmisión
                    RCREG = 0;              // Poner RCREG en 0 para salir
                    }       
                }
            caso = 1;                       // Levantar bandera de menú princ
            punt3 = 32;                     // Restaurar puntero
        }
    }
    return;
}

//******************************************************************************
// Configuraciones
//******************************************************************************
void setup() {
    config_io();
    config_reloj();
    config_serial();
    config_int_enable();
    return;
}

void config_io() {
    ANSELH = 0x00;  // Todos los pines digitales
    ANSEL = 0x00;   // 
    
    TRISA = 0x00;   // Para valor de la terminal
    TRISB = 0x00; 
               
    PORTA = 0x00;   // Se limpian los puertos
    PORTB = 0x00;
}
 
void config_reloj() {
    OSCCONbits.IRCF2 = 1;   //Frecuencia a 1MHZ
    OSCCONbits.IRCF1 = 0;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS = 1;     // Habilitar reloj interno
}
    
void config_serial() {   
    TXSTAbits.SYNC = 0;     // Comunicación asincrona
    TXSTAbits.BRGH = 1;     // High Speed
    
    BAUDCTLbits.BRG16 = 1;  // 16 baud rate en uso
    
    SPBRG = 25;             // Valor para Baud Rate
    SPBRGH = 0;             
    
    RCSTAbits.SPEN = 1;     // Se habilita TX y RX
    RCSTAbits.RX9 = 0;      // 8 bits de recepción
    RCSTAbits.CREN = 1;     // Se habilita recibimiento continuo
    TXSTAbits.TXEN = 1;     // Se habilita la transimisión
}

void config_int_enable() {   
    INTCONbits.GIE = 1;     // Se habilitan las interrupciones globales
    INTCONbits.PEIE = 1;    // Se habilitan las interrupciones perifericas
    PIE1bits.RCIE = 1;      // Se habilita la interrupción de RCREG
    PIR1bits.RCIF = 0;      // Se apaga la bandera te RCREG
}