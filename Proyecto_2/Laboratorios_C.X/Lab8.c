//******************************************************************************
//  Encabezado
//******************************************************************************
/* Archivo: Lab8
 * Dispositivo: PIC16f887
 * Autor: Jefry Carrasco
 * Descripción: 
 * Convertidor ADC de dos potenciometros, los valores se despliegan en leds
 * bargraf, uno de los valores se despliega en display 7seg
 * Hardware: 
 * 1 Display 7seg MPX4 en PORTA
 * 3 transistores en PORTB
 * 1 led bargraf en PORTC
 * 1 led bargraf en PORTD
 * 2 potenciometros en PORTE
 * Creado: 19 de abril, 2021
 * Modificado: 20 abril, 2021 */  

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
#define _XTAL_FREQ 4000000  // Libreria para delay
#define reset_tmr0 236      // Valor para el TMR0

//******************************************************************************
// Variables
//******************************************************************************
char tab7seg[10]={0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x67};
char var_temp;      
char unidades = 0;  
char decenas = 0;
char decenas_res = 0;
char centenas = 0;
char unidad_display = 0;
char decena_display = 0;
char centena_display = 0;
char cont = 0;

//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup();               // Configuraciones del PIC
void config_io();           // Configurar entradas y salidas
void config_reloj();        // Configurar reloj
void config_adc();          // Configurar módulo ADC
void config_int_enable();   // Enable interrupciones
void config_timer0();       // Configurar TMR0
void display7seg();         // Convertir valor binario a decimal

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
         display7seg();    //Conversión binario a decimal
         
         if(ADCON0bits.GO == 0){        // Cambio de canal
             if(ADCON0bits.CHS == 6)
                 ADCON0bits.CHS = 5;
             else
                 ADCON0bits.CHS = 6;
             __delay_us(50);
             ADCON0bits.GO = 1;
         }
    }
    return;
}

//******************************************************************************
// Interrupciones
//******************************************************************************
void __interrupt() isr(void){
    if (INTCONbits.T0IF){               // Interrupcion de TMR0
        PORTB = 0x00;                   // Apagar multiplexado
        if(cont == 0){
            PORTA = unidad_display;     // Cargar unidades al display
            PORTBbits.RB0 = 1;          // Multiplexado
            cont = 1;                   // Ir a decenas
        }
        else if(cont == 1){
            PORTA = decena_display;     // Cargar decenas al display
            PORTBbits.RB1 = 1;          // Multiplexado
            cont = 2;                   // Ir a centenas
        }
        else {
            PORTA = centena_display;    // Cargar decenas al display
            PORTBbits.RB2 = 1;          // Multiplexado
            cont = 0;                   // Ir a unidades
        }
        TMR0 = reset_tmr0;              // Reiniciar del TMR0
        INTCONbits.T0IF = 0;            // Limpiar bandera de TMR0
    }
    
    if(PIR1bits.ADIF){                  // Interrupción del ADC
        if(ADCON0bits.CHS == 5)
            PORTC = ADRESH;             // Cargar valor de ADRESH a PORTC
        else
            PORTD = ADRESH;             // Cargar valor de ADRESH a PORTD
        PIR1bits.ADIF = 0;              // Se limpia la bandera del ADC
    }
    return;
}

//******************************************************************************
// Configuraciones
//******************************************************************************
void setup(){
    config_io();
    config_reloj();
    config_adc();
    config_timer0();
    config_int_enable();
    return;
}

void config_io(){
    ANSELH = 0x60;  // Se habilitan RE0 y RE1
    ANSEL = 0x00;
    
    TRISA = 0x00;   // Displays 7seg
    TRISB = 0x00;   // Transistores
    TRISC = 0x00;   // Valores digitales del POT1
    TRISD = 0x00;   // Valores digitales del POT2
    TRISE = 0x03;   // Entradas analógicas
    
    PORTA = 0x00;   // Limpiar los puertos
    PORTB = 0x00;
    PORTC = 0x00;
    PORTD = 0x00;
    return;
}

void config_reloj(){
    OSCCONbits.IRCF2 = 1;   // Frecuencia de 4MHz 
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS = 1;     // Habilitar reloj interno
    return;
}

void config_adc() {
    ADCON1bits.ADFM = 0;    // Justifiación a la izquierda
    ADCON1bits.VCFG0 = 0;   // Voltaje de referencia Vss y Vdd
    ADCON1bits.VCFG1 = 0;   
    
    ADCON0bits.ADCS = 1;    // ADC clokc Fosc/8
    ADCON0bits.CHS = 5;     // Canal 5 selecionado
    __delay_us(100);
    ADCON0bits.ADON = 1;    // Enecender módulo ADC
    return;
}

void config_int_enable(){    
    INTCONbits.GIE = 1;     // Se habilitan las interrupciones globales
    INTCONbits.PEIE = 1;    // Se habilitan las interrupciones perifericas
    PIE1bits.ADIE = 1;      // Se habilita la interrupcion del ADC
    PIR1bits.ADIF = 0;      // Se limpia la bandera del ADC
    INTCONbits.T0IE = 1;    // Se habilitan la interrupción del TMR0
    INTCONbits.T0IF = 0;    // Se limpia la bandera del TMR0
    return;
}

void config_timer0(){
    OPTION_REGbits.T0CS = 0;// Selecciona el reloj interno
    OPTION_REGbits.PSA = 0; // El prescaler seleccionado para el TMR0
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1; // Prescaler a 1:256
    TMR0 = reset_tmr0;
    INTCONbits.T0IF = 0;    // Se limpia la bandera
    return;
}

//******************************************************************************
// Funciones
//******************************************************************************
void display7seg(){
    var_temp = PORTD;           // Se carga el valor del POT2      
    centenas = var_temp/100;    // Obtener centenas
    decenas_res = var_temp%100; // Almacenar el residuo
    decenas = decenas_res/10;   // Obtener decenas
    unidades = var_temp%10;     // Obtener unidades 
    unidad_display = tab7seg[unidades]; //Conversión de tabla 
    decena_display = tab7seg[decenas];
    centena_display = tab7seg[centenas];
    return;
}
