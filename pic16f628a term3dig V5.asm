;term3dig_d
;versao lendo o modulo
;sem interrupcao nem timer    
;limite de leitura de temperatura em 255 Graus    
    
    LIST p=16F628A
    #include <p16F628A.inc>

; CONFIG
;Configuration Register CP=1 Code Protection OFF CPD=1 Data Memory Protection OFF 
;LVP=0 RB4/PGM is Digital I/O HV on MCLR for Programming Boren=1 Reset Enabled MCLRE=1 RA5 é Master Clear Enabled FOSC2=1
;PWRTE = 0 Power Up Timer Enabled WDTE=0 Watch Dog Timer Disabled FOSC1=0 FOSC0=1
;FOSC2 FOSC1 FOSC0 = 1 0 0 = 4 Mhz Internal Oscillator e pinos RA7 liberado para digital
    ; CONFIG
; __config 0x3F71
 __CONFIG _FOSC_INTOSCCLK & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF


GPR_VAR	UDATA 0x20
cent	RES 1		;BCD Centena, RB3..RB0 contem valor da centena em BCD de 0 a 9, (RA2=1, RA1=0 e RA0=0) acende somente o digito centena
dez	RES 1		;BCD Dezena, RB3..RB0 contem valor da dezena em BCD de 0 a 9, (RA2=0, RA1=1 e RA0=0) acende somente o digito da dezena
un	RES 1		;BCD Unidade RB3..RB0 contem valor da unidade em BCD de 0 a 9, (RA2=0, RA1=0, RA0=1) acende somente o digito da unidade
decimo  RES 1           ;0=0, 1=0.25, 2=0.5, 3=0.75
burnout RES 1           ;=1, problema no termopar  
pt_digit RES 1		;assume valor 1, 2 ou 3 acendendo o digito da unidade quando for =1, dezena se =2 e centena se =3
                        ;incrementado pela interrupcao do timer0 a cada 0,006656 s
aux     RES 1
aux1    RES 1
cntrc   RES 1		;Contador de tempo
cntrb   RES 1		;Contador de tempo
cntra   RES 1		;Contador de tempo
templ	RES 1		;byte mais baixo da temperatura de 10 bits			

RES_VECT  CODE    0x0000            ; processor reset vector
 GOTO    START                      ; go to beginning of program

MAIN_PROG CODE                      ; let linker place main program

START
 clrf PORTA
 ;desliga comparadores para habilitar os pinos de PORTA para sinais digitais
 movlw 7
 movwf CMCON
 ;seleciona Banco 1 para mexer na configuracao dos bits da PORTA
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; 1 = input, 0 = output 
 movlw b'00000000' ;Tudo saida
 movwf TRISA
 ; Select Bank 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ;inicializa as saidas de dados da PORTA, RA4(CS)=1 e RA3(CK)=0
 movlw b'00010000'
 movwf PORTA
 ; Inicializa PORTB como saida, RB5 entrada
 ; 1 = input, 0 = output 
 clrf PORTB
 ;seleciona Banco 1 para mexer na configuracao dos bits da PORTB
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; 1 = input, 0 = output
 movlw b'00100000'
 movwf TRISB
 ; Select Bank 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ; Ponteiro de digito inicia apontando para unidade, limpar pt_digit para que quando chamar a rotina
 ; pt_digit va para 1, indicando unidade
 clrf pt_digit
 movlw d'60'
 movwf cntrc
 ;Limpa os valores
 clrf templ
 clrf burnout
 clrf decimo
 
LOOP
 movlw d'10'
 movwf cntra
 movlw d'10'
 movwf cntrb
LOOP1
 decfsz cntra,1
 goto LOOP1
 decfsz cntrb,1
 goto LOOP1
 bsf PORTA, 7;pisca beacon
 call INCRDIG
 bcf PORTA, 7
 decfsz cntrc,1
 goto LOOP
 call LETEMP
 call CONVTEMP
 movlw d'60'
 movwf cntrc
 goto LOOP
 
LETEMP
 ;faz a leitura do sensor de temperatura e armazena resultado em templ, decimo e burnout
 clrf templ
 clrf decimo
 clrf burnout
 bcf PORTA, 4	;abaixa CS
 call retarda
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Ignora bit 15
 call retarda
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 14=temph bit 1
 call retarda
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 13=temph bit 0
 call retarda
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 12=templ bit 7
 call retarda
 btfss PORTB, 5
 goto LETEMP03
 bsf templ,7
LETEMP03
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 11=templ bit 6
 call retarda
 btfss PORTB, 5
 goto LETEMP04
 bsf templ,6
LETEMP04
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 10=templ bit 5
 call retarda
 btfss PORTB, 5
 goto LETEMP05
 bsf templ,5
LETEMP05
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 09=templ bit 4
 call retarda
 btfss PORTB, 5
 goto LETEMP06
 bsf templ,4
LETEMP06
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 08=templ bit 3
 call retarda
 btfss PORTB, 5
 goto LETEMP07
 bsf templ,3
LETEMP07
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 07=templ bit 2
 call retarda
 btfss PORTB, 5
 goto LETEMP08
 bsf templ,2
LETEMP08
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 06=templ bit 1
 call retarda
 btfss PORTB, 5
 goto LETEMP09
 bsf templ,1
LETEMP09
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 05=templ bit 0
 call retarda
 btfss PORTB, 5
 goto LETEMP10
 bsf templ,0
LETEMP10
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 04=decimo bit 1
 call retarda
 btfss PORTB, 5
 goto LETEMP11
 bsf decimo,1
LETEMP11
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 03=decimo bit 0
 call retarda
 btfss PORTB, 5
 goto LETEMP12
 bsf decimo,0
LETEMP12
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Desce clock Bit 02=burnout
 call retarda
 btfss PORTB, 5
 goto LETEMP13
 bsf burnout,0
LETEMP13 
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Ignora bit 1
 call retarda
 bsf PORTA, 3	;Sobe clock
 call retarda
 bcf PORTA, 3	;Ignora bit 0
 call retarda
 bsf PORTA, 4	;levanta CS
 call retarda
 return 

CONVTEMP
 ;Metodo estupido de fazer a conversao binario BCD
 clrf un
 clrf dez
 clrf cent
 ;Testa temperatura zero. Se sim, pula fora
 movlw 0x00
 addwf templ, W
 btfsc STATUS, Z
 return;volta se for zero
 movf templ, W
 movwf aux
CONVTEMP5
 decfsz aux, 1
 goto CONVTEMP6
 goto CONVTEMP7
CONVTEMP6
 call SOMAUM
 goto CONVTEMP5
CONVTEMP7; acabou de converter 
 call SOMAUM
 return
 
SOMAUM
 incf un
 movf un, W
 sublw d'10'
 btfss STATUS, Z
 goto L1
 clrf un
 incf dez
L1
 movf dez, W
 sublw d'10'
 btfss STATUS, Z
 goto L2
 clrf dez
 incf cent
L2
 movf cent, W
 sublw d'10'
 btfss STATUS, Z
 return
 clrf cent
 clrf dez
 clrf un
 return
 
INCRDIG
 ;Incrementa o visualizador de digito deixando o resultado em pt_digit.
 ;limpa BCD
 movlw b'11110000'
 andwf PORTB, 1
 ;desliga display
 movlw b'11111000'
 andwf PORTA, 1
 incf pt_digit, 1
 ;Testa se pt_digit eh 2. Carrega 2 em W e subtrai de pt_digit, mantendo resultado em W
 movlw 0x02
 subwf pt_digit, W
 btfss STATUS, Z
 ;se o valor de pt_digit for diferente de 2 vai para adiante
 goto INCRDIG1
 ;pt_digit eh 2, carrega dezena no decodificador. Para isso, limpa os 4 bits menos significativos de PORTB 
 ;fazendo and na portb e guardando o resultado em portb
 ;agora carrega dezena em W 
 movf dez, W
 ;soma com portb para carregar o digito, mantendo a soma em portb
 addwf PORTB, 1
 ;ativa o display da dezena
 bsf PORTA, 1
 return
INCRDIG1
 ;Testa se pt_digit eh 3. Carrega 3 em W e subtrai de pt_digit, mantendo resultado em W
 movlw 0x03
 subwf pt_digit, W
 btfss STATUS, Z
 ;se o valor de pt_digit for diferente de 3 so pode ser 1, vai adiante
 goto INCRDIG2
 ;pt_digit eh 3, carrega centena no decodificador. Para isso, limpa os 4 bits menos significativos de PORTB 
 ;fazendo and na portb e guardando o resultado em portb
 ;agora carrega centena em W 
 movf cent, W
 ;soma com portb para carregar o digito, mantendo a soma em portb
 addwf PORTB, 1
 ;ativa o display da centena
 bsf PORTA, 2
 ;Se pt_digit em 3, tem que voltar para 1. Para isso zera-se pt_digit para que no proximo incremento ele fique em 1
 clrf pt_digit
 return
INCRDIG2
 ;agora pt_digit so pode ser 1, mostra a unidade no decodificador. Para isso, limpa os 4 bits menos significativos de PORTB 
 ;fazendo and na portb e guardando o resultado em portb
 ;agora carrega unidade em W 
 movf un, W
 ;soma com portb para carregar o digito, mantendo a soma em portb
 addwf PORTB, 1
 ;ativa o display da unidade
 bsf PORTA, 0
 return
 
retarda
 movlw d'10'
 movwf aux1
retarda1 
 decfsz aux1
 goto retarda1
 return
 
 END

