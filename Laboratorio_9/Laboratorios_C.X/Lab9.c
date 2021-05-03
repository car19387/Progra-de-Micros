//******************************************************************************
//  Encabezado
//******************************************************************************
/* Archivo: Lab9
 * Dispositivo: PIC16f887
 * Autor: Jefry Carrasco
 * Descripción: 
 * Convertidor ADC de dos potenciometros, los valores se utilizan para 
 * contrlar dos servomotores
 * Hardware: 
 * 1 PIC16F887
 * 2 potenciometros en PORTE
 * 2 Servomotores en RC1 y RC2
 * Creado: 26 de abril, 2021
 * Modificado: 2 de mayo, 2021 */  

//******************************************************************************
// Librerías incluidas
//******************************************************************************
#include <xc.h>

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
#define _XTAL_FREQ 8000000  // Libreria para delay

//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup();               // Configuraciones del PIC
void config_io();           // Configurar entradas y salidas
void config_reloj();        // Configurar reloj
void config_adc();          // Configurar módulo ADC
void config_pwm();          // Configurar PWM
void config_int_enable();   // Enable interrupciones

//******************************************************************************
// Main
//******************************************************************************
void main(void) {
    setup();            // Ir a las configuraciones
    ADCON0bits.GO = 1;  // Iniciar ADC
    
    //**************************************************************************
    // Loop principal
    //**************************************************************************
    while(1){
        if(ADCON0bits.GO == 0){         // Si la bandera del ADC se bajó
            if (ADCON0bits.CHS == 0){   // Si está en el canal 0
                ADCON0bits.CHS = 1;     // Entonces pasa al canal 1
            }  
            else {                      // Si no está en el canal 0
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
            PORTB = ADRESH;             // Guardar valor de conversión en PORTB
            CCPR1L = (PORTB>>1) + 128;  // Valores válidos entre 128 y 250
            CCP1CONbits.DC1B1 = PORTBbits.RB0;  //Bits menos significativos
            CCP1CONbits.DC1B0 = ADRESL>>7;
        }
        
        else {                          // Si está en el canal 0
            PORTB = ADRESH;             // Guardar valor de conversión en PORTB
            CCPR2L = (PORTB>>1) + 128;  // Valores válidos entre 128 y 250
            CCP2CONbits.DC2B1 = PORTBbits.RB0;  //Bits menos significativos
            CCP2CONbits.DC2B0 = ADRESL>>7;
        }
        
        PIR1bits.ADIF = 0;              // Limpiar la bandera de ADC
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
    config_pwm();
    config_int_enable();
    return;
}

void config_io() {
    ANSELH = 0x00;  // Pines digitales
    ANSEL = 0x03;   // Primeros dos pines con entradas analógicas
    
    TRISA = 0x03;   // Para entrada de los potenciometros
    TRISB = 0x00;   //¨Para almacenar valor
    TRISC = 0x00;   // Para servos
               
    PORTA = 0x00;   // Se limpian los puertos    
    PORTB = 0x00;
    PORTC = 0x00;
}
 
void config_reloj() {
    OSCCONbits.IRCF2 = 1;   //Frecuencia a 8MHZ
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS = 1;     // Habilitar reloj interno
}
    
void config_adc() {   
    ADCON1bits.ADFM = 0;    // Justifiación a la izquierda
    ADCON1bits.VCFG0 = 0;   // Voltaje de referencia Vss y Vdd
    ADCON1bits.VCFG1 = 0;   
    
    ADCON0bits.ADCS = 2;    // ADC clokc Fosc/32
    ADCON0bits.CHS = 0;     // Canal 0 selecionado
    __delay_us(50);
    ADCON0bits.ADON = 1;    // Enecender módulo ADC
}

void config_pwm() { 
    PR2 = 250;              // Valor inicial de PR2
    CCP1CONbits.P1M = 0;    // PWM bits de salida
    CCP1CONbits.CCP1M = 0b00001100; // Se habilita PWM   
    CCP2CONbits.CCP2M = 0b00001100;   
    
    CCPR1L = 0x0F; 
    CCPR2L = 0x0F;
    CCP1CONbits.DC1B = 0;   // Bits menos significativos del Duty Cycle
    CCP2CONbits.DC2B1 = 0;
    CCP2CONbits.DC2B0 = 0;
    
    PIR1bits.TMR2IF = 0;    // Se limpia la bandera
    T2CONbits.T2CKPS1 = 1;  // Prescaler de 16
    T2CONbits.T2CKPS0 = 1;
    T2CONbits.TMR2ON = 1;   // Se enciende el TMR2
    
    while (!PIR1bits.TMR2IF); // Se espera una interrupción
    PIR1bits.TMR2IF = 0;
}

void config_int_enable() {   
    INTCONbits.GIE = 1;     // Se habilitan las interrupciones globales
    INTCONbits.PEIE = 1;    // Se habilitan las interrupciones perifericas
    PIE1bits.ADIE = 1;      // Se habilita la interrupcion del ADC
    PIR1bits.ADIF = 0;      // Se limpia la bandera del ADC
}