;term3digb
;primeira versao com o sensor de temperatura
    
    LIST p=16F628A
    #include <p16F628A.inc>

; CONFIG
;Configuration Register CP=1 Code Protection OFF CPD=1 Data Memory Protection OFF 
;LVP=0 RB4/PGM is Digital I/O HV on MCLR for Programming Boren=1 Reset Enabled MCLRE=1 RA5 é Master Clear Enabled FOSC2=1
;PWRTE = 0 Power Up Timer Enabled WDTE=0 Watch Dog Timer Disabled FOSC1=0 FOSC0=1
;FOSC2 FOSC1 FOSC0 = 1 0 0 = 4 Mhz Internal Oscillator e pinos RA7 e RA6 liberados para digital
; __config 0x3F70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

 
 
GPR_VAR	UDATA 0x20
milh    RES 1           ;Conversor vai de 0 a 1023 porem mostra apenas cent, dez e un	
cent	RES 1		;BCD Centena, RB3..RB0 contem valor da centena em BCD de 0 a 9, (RA2=1, RA1=0 e RA0=0) acende somente o digito centena
dez	RES 1		;BCD Dezena, RB3..RB0 contem valor da dezena em BCD de 0 a 9, (RA2=0, RA1=1 e RA0=0) acende somente o digito da dezena
un	RES 1		;BCD Unidade RB3..RB0 contem valor da unidade em BCD de 0 a 9, (RA2=0, RA1=0, RA0=1) acende somente o digito da unidade
decimo  RES 1           ;0=0, 1=0.25, 2=0.5, 3=0.75
burnin  RES 1           ;=1, problema no termopar  
pt_digit RES 1		;assume valor 1, 2 ou 3 acendendo o digito da unidade quando for =1, dezena se =2 e centena se =3
                        ;incrementado pela interrupcao do timer0 a cada 0,006656 s
cntd	RES 1		;deve ser carregado com 150 para chamar a medicao de temperatura, 
			;controlado pela interrupcao do timer 0
aux	RES 1		;variavel auxiliar
aux1    RES 1           ;variavel auxiliar
aux2    RES 1           ;variavel auxiliar
ptrn     RES 1           ;ponteiro para inicializador de tabela
temph	RES 1		;byte mais alto da temperatura de 12 bits
templ	RES 1		;byte mais baixo da temperatura de 12 bits			
w_temp RES 1            ;W temporario para salvar contexto
status_temp RES 1	;status temporario para salvar contexto

DATAEE    CODE  0x2100
 ;48 valores tabela de 16 numeros de 3 algaritmos taboada de 64 com 3 digitos
 DE 0x00,0x00,0x00,0x00,0x06,0x04,0x01,0x02,0x08,0x01,0x09,0x02
 DE 0x02,0x05,0x06,0x03,0x02,0x00,0x03,0x08,0x04,0x04,0x04,0x08
 DE 0x05,0x01,0x02,0x05,0x07,0x06,0x06,0x04,0x00,0x07,0x00,0x04
 DE 0x07,0x06,0x08,0x08,0x03,0x02,0x08,0x09,0x06,0x09,0x06,0x00
 
RES_VECT  CODE    0x0000            ; processor reset vector
 GOTO    START                      ; go to beginning of program

ISR       CODE    0x0004           ; interrupt vector location
 ;Rotina de interrupcao para tratar timer0 vai ser executada a cada 0,006656 s

 ;Salva contexto
 movwf w_temp		;salva w no registro temporario w_temp
 movf STATUS, W		;poe status em W
 movwf status_temp	;salva status em status_temp
 ;acende o proximo digito
 call INCRDIG
 ;testa se vai incrementar o numero BCD
 decfsz cntd
 goto ISR1
 ;cntd eh zero, chama a leitura de temperatura
 call LETEMP
 ;converte 12 bits de temperatura binaria de temph templ em BCD
 call CONVTEMP
 ;recarrega cntd com 150 para voltar a contar um segundo
 movlw d'150'
 movwf cntd
ISR1 
 ;prepara novamente as condicoes para a proxima interrupcao
 ;Carrega Timer0 Preload com valor 151. Com isso quando ele chegar a 255 terao se passado 104 ciclos de 1Mhz/64
 movlw d'151'
 movwf TMR0
 ;Toda vez que carregar Timer0 Preload tem que reescrever Option Register porque o Preload zera o Option Register e fode suas opcoes
 ;Bit 7=1 Sem Pull up Bit 6=X Bit 5=0 Clock Interno Bit 4=X Bit 3=0 Prescaler pro Timer Bits 2,1,0 = 101 Prescaler=64
  ;Select Bank 1
 BCF STATUS, RP1 
 BSF STATUS, RP0
 movlw b'10000101'
 movwf OPTION_REG
 ; Select Bank 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ;Limpa o overflow do Timer 0 em T0IF
 bcf INTCON, 2
 ;restaura contexto
 movf status_temp, W	;restaura status
 movwf STATUS
 swapf w_temp, f		;troca os nibbles de wtemp e deixa resultado em w_temp
 swapf w_temp, W		;troca os nibbles de wtemp e deixa resultado em w
 ;Fim da interrupcao
 RETFIE

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
 clrf milh
 clrf cent
 clrf dez
 clrf un
 ; Ponteiro de digito inicia apontando para unidade, limpar pt_digit para que quando chamar a rotina
 ; pt_digit va para 1, indicando unidade
 clrf pt_digit
 ;Carrega cntd com 150 para ser decrementado a cada interrupcao do timer 0
 movlw d'150'
 movwf cntd
 ;Carrega Timer0 Preload com valor 151. Com isso quando ele chegar a 255 terao se passado 104 ciclos de 1Mhz/64
 movlw d'151'
 movwf TMR0
 ;Toda vez que carregar Timer0 Preload tem que reescrever Option Register porque o Preload zera o Option Register e fode suas opcoes
 ;Bit 7=1 Sem Pull up Bit 6=X Bit 5=0 Clock Interno Bit 4=X Bit 3=0 Prescaler pro Timer Bits 2,1,0 = 101 Prescaler=64
 ;Select Bank 1
 BCF STATUS, RP1 
 BSF STATUS, RP0
 movlw b'10000101'
 movwf OPTION_REG
 ; Select Bank 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ;Habilita interrupcao Global
 bsf INTCON, GIE
 ;Habilita todas as interrupcoes mascaraveis
 bsf INTCON, PEIE
 ;habilita a interrupcao do Timer0
 bsf INTCON, T0IE
 ;limpa o flag da interrupcao do Timer 0
 bcf INTCON, T0IF 
 
LOOP
 ;Laço eterno pois o programa ira operar somente com interrupcoes. Pode ate colocar em halt para poupar energia
 goto LOOP
 
LETEMP
 ;faz a leitura do sensor de temperatura e armazena os resultados em cent dez un
 ;na primeira versao o formato le apenas o valor inteiro da temperatura sem apagar zeros a esquerda
 clrf temph	;limpa destinos
 clrf templ
 clrf decimo
 clrf burnin
 bcf PORTA, 4	;abaixa CS
 nop
 nop
 nop
 nop
 movlw 0x04
 movwf aux2
 call LETEMPH;Bit 15=descartar
 movlw 0x02
 movwf aux2
 call LETEMPH;Bit 14=bit 1 TEMPH=Bit 9 temperatura
 movlw 0x01
 movwf aux2
 call LETEMPH;Bit 13=bit 0 TEMPH=Bit 8 temperatura
 movlw 0x80
 movwf aux2
 call LETEMPL;Bit 12=bit 7 TEMPL=Bit 7 temperatura
 movlw 0x40
 movwf aux2
 call LETEMPL;Bit 11=bit 6 TEMPL=Bit 6 temperatura
 movlw 0x20
 movwf aux2
 call LETEMPL;Bit 10=bit 5 TEMPL=Bit 5 temperatura
 movlw 0x10
 movwf aux2
 call LETEMPL;Bit 09=bit 4 TEMPL=Bit 4 temperatura
 movlw 0x08
 movwf aux2
 call LETEMPL;Bit 08=bit 3 TEMPL=Bit 3 temperatura
 movlw 0x04
 movwf aux2
 call LETEMPL;Bit 07=bit 2 TEMPL=Bit 2 temperatura
 movlw 0x02
 movwf aux2
 call LETEMPL;Bit 06=bit 1 TEMPL=Bit 1 temperatura
 movlw 0x01
 movwf aux2
 call LETEMPL;Bit 05=bit 0 TEMPL=Bit 0 temperatura
 movlw 0x02
 movwf aux2
 call LEDECIMO;Bit 04=bit 1 DECIMO=Bit 1 decimo de temperatura
 movlw 0x01
 movwf aux2
 call LEDECIMO;Bit 03=bit 0 DECIMO=Bit 0 decimo da temperatura
 call LEBURNIN;Bit 2 Burnin, 1 e 0 descarta
 bsf PORTA, 4	;levanta CS
 nop
 nop
 nop
 nop
 return 

CONVTEMP
 ;Metodo estupido de fazer a conversao binario BCD
 clrf un
 clrf dez
 clrf cent
 clrf milh
 clrf ptrn
 movf temph, W
 movwf aux
 rlf aux, 1
 rlf aux, 1
 movf aux, W
 andlw b'00001100'
 movwf aux1
 movf templ, W
 movwf aux
 rlf aux, 1
 rlf aux, 1
 rlf aux, 1
 movf aux, W
 andlw b'00000011'
 addwf aux1, 1
 movf aux1, W
 btfsc STATUS, Z
 goto L02
 movlw d'3'
L01 
 addwf ptrn, 1
 decfsz aux1, 1
 goto L01
L02
 ;ponteiro ptrn tem endereco da tabela da inicializacao de m c d u
 movf ptrn, W
 ; Banco 1
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; Carrega ponteiro para EEPROM
 MOVWF EEADR
 ; Le EEPROM e guarda em W
 BSF EECON1, RD 
 MOVF EEDATA, W
 ; Volta pro Banco 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ;W contains cent
 movwf cent
 incf ptrn
 movf ptrn, W
 ; Banco 1
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; Carrega ponteiro para EEPROM
 MOVWF EEADR
 ; Le EEPROM e guarda em W
 BSF EECON1, RD 
 MOVF EEDATA, W
 ; Volta pro Banco 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ;W contains dez
 movwf dez
 incf ptrn
 movf ptrn, W
 ; Banco 1
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; Carrega ponteiro para EEPROM
 MOVWF EEADR
 ; Le EEPROM e guarda em W
 BSF EECON1, RD 
 MOVF EEDATA, W
 ; Volta pro Banco 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ;W contains un
 movwf un
 ;agora processa a soma dos 6 bits restantes
 movf templ, W
 movwf aux
 movlw b'00111111'
 andwf aux, 1
 btfsc STATUS, Z
 goto L04
L03
 call SOMAUM
 decfsz aux, 1
 goto L03
L04
 ;milh cent dez un tem numero temph templ convertido, 10 bits
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
 goto L3
 clrf cent
 incf milh
L3 
 return
 
INCRDIG
 ;Incrementa o visualizador de digito deixando o resultado em pt_digit.
 ;Eh chamado a cada 6,656 ms controlado pela interrupcao do timer 0
 incf pt_digit, 1
 ;Testa se pt_digit eh 2. Carrega 2 em W e subtrai de pt_digit, mantendo resultado em W
 movlw 0x02
 subwf pt_digit, W
 btfss STATUS, Z
 ;se o valor de pt_digit for diferente de 2 vai para adiante
 goto INCRDIG1
 ;pt_digit eh 2, carrega dezena no decodificador. Para isso, limpa os 4 bits menos significativos de PORTB 
 ;fazendo and na portb e guardando o resultado em portb
 movlw b'11110000'
 andwf PORTB, 1
 ;agora carrega dezena em W 
 movf dez, W
 ;soma com portb para carregar o digito, mantendo a soma em portb
 addwf PORTB, 1
 ;ativa o display da dezena
 movlw b'11111000'
 andwf PORTA, 1
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
 movlw b'11110000'
 andwf PORTB, 1
 ;agora carrega centena em W 
 movf cent, W
 ;soma com portb para carregar o digito, mantendo a soma em portb
 addwf PORTB, 1
 ;ativa o display da centena
 movlw b'11111000'
 andwf PORTA, 1
 bsf PORTA, 2
 ;Se pt_digit em 3, tem que voltar para 1. Para isso zera-se pt_digit para que no proximo incremento ele fique em 1
 clrf pt_digit
 return
INCRDIG2
 ;agora pt_digit so pode ser 1, mostra a unidade no decodificador. Para isso, limpa os 4 bits menos significativos de PORTB 
 ;fazendo and na portb e guardando o resultado em portb
 movlw b'11110000'
 andwf PORTB, 1
 ;agora carrega unidade em W 
 movf un, W
 ;soma com portb para carregar o digito, mantendo a soma em portb
 addwf PORTB, 1
 ;ativa o display da unidade
 movlw b'11111000'
 andwf PORTA, 1
 bsf PORTA, 0
 return
 
LETEMPH
 bsf PORTA, 3	;Sobe clock
 nop
 nop
 nop
 nop
 bcf PORTA, 3	;Desce clock
 nop
 nop
 nop
 nop
 btfsc PORTB, 5
 goto LETEMPH1
 return
LETEMPH1
 movf aux2, W
 addwf temph
 return

LETEMPL
 bsf PORTA, 3	;Sobe clock
 nop
 nop
 nop
 nop
 bcf PORTA, 3	;Desce clock
 nop
 nop
 nop
 nop
 btfsc PORTB, 5
 goto LETEMPL1
 return
LETEMPL1
 movf aux2, W
 addwf templ
 return
 
LEDECIMO
 bsf PORTA, 3	;Sobe clock
 nop
 nop
 nop
 nop
 bcf PORTA, 3	;Desce clock
 nop
 nop
 nop
 nop
 btfsc PORTB, 5
 goto LEDECIMO1
 return
LEDECIMO1
 movf aux2, W
 addwf decimo
 return
 
LEBURNIN
 bsf PORTA, 3	;Sobe clock
 nop
 nop
 nop
 nop
 bcf PORTA, 3	;Desce clock
 nop
 nop
 nop
 nop
 btfsc PORTB, 5
 goto LEBURNIN1
 goto LEBURNIN2
LEBURNIN1
 incf burnin
LEBURNIN2
 bsf PORTA, 3	;Sobe clock
 nop
 nop
 nop
 nop
 bcf PORTA, 3	;Desce clock
 nop
 nop
 nop
 nop
 bsf PORTA, 3	;Sobe clock
 nop
 nop
 nop
 nop
 bcf PORTA, 3	;Desce clock
 nop
 nop
 nop
 nop
 return 

 END

