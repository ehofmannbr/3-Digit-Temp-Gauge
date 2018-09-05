;term3dig_a Teste de Displays
    
    LIST p=16F628A
    #include <p16F628A.inc>

; __config 0x3F71
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

GPR_VAR	UDATA 0x20
 
RES_VECT  CODE    0x0000            ; processor reset vector
 GOTO    START                      ; go to beginning of program

MAIN_PROG CODE                      ; let linker place main program

START
 ;inicializa as saidas de dados da PORTA
 clrf PORTA
 ;desliga comparadores para habilitar os pinos de PORTA para sinais digitais
 movlw 7
 movwf CMCON
 ;seleciona Banco 1 para mexer na configuracao dos bits da PORTA
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; 1 = input, 0 = output 
 movlw b'10000000' ;RA0,1,2,3,4,6 saidas, RA7 entrada, RA5=MCLR ou VPP
 movwf TRISA
 ; Select Bank 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ; Inicializa PORTB como saida
 ; 1 = input, 0 = output 
 clrf PORTB
 ;seleciona Banco 1 para mexer na configuracao dos bits da PORTB
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; 1 = input, 0 = output 
 clrf TRISB
 bsf TRISB, 5
 ; Select Bank 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
LOOP
 movlw b'00000010'
 movwf PORTB
 movlw b'00000100'
 movwf PORTA
 goto LOOP
 
 
 
 
 END

