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
cent	RES 1		;BCD Centena, RB3..RB0 contem valor da centena em BCD de 0 a 9, (RA2=1, RA1=0 e RA0=0) acende somente o digito centena
dez	RES 1		;BCD Dezena, RB3..RB0 contem valor da dezena em BCD de 0 a 9, (RA2=0, RA1=1 e RA0=0) acende somente o digito da dezena
un	RES 1		;BCD Unidade RB3..RB0 contem valor da unidade em BCD de 0 a 9, (RA2=0, RA1=0, RA0=1) acende somente o digito da unidade
pt_digit RES 1		;assume valor 1, 2 ou 3 acendendo o digito da unidade quando for =1, dezena se =2 e centena se =3
                        ;incrementado pela interrupcao do timer0 a cada 0,006656 s
cntd	RES 1		;contador de delay para incrementar o numero formado por cent dez un de 000 a 999.
                        ;deve ser carregado com 75 para incrementar o numero no display a cada meio segundo, controlado pela interrupcao do timer 0
                        ;75 vezes 0,006656s da 0,4992 s
w_temp RES 1            ;W temporario para salvar contexto
status_temp RES 1	;status temporario para salvar contexto
 
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
 ;cntd eh zero, incrementa o numero BCD
 call INCRNUM
 ;recarrega cntd com 75 para voltar a contar mais meio segundo
 ;Carrega cntd com 25 para ser decrementado a cada interrupcao do timer 0
 movlw d'75'
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
 ;inicializa as saidas de dados da PORTA
 clrf PORTA
 ;desliga comparadores para habilitar os pinos de PORTA para sinais digitais
 movlw 7
 movwf CMCON
 ;seleciona Banco 1 para mexer na configuracao dos bits da PORTA
 BCF STATUS, RP1 
 BSF STATUS, RP0
 ; 1 = input, 0 = output 
 movlw b'00000000' ;RA0,1,2,3,4,6,7 RA5=MCLR ou VPP
 movwf TRISA
 ; Select Bank 0
 BCF STATUS, RP1 
 BCF STATUS, RP0
 ; Inicializa PORTB
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
 ; Parte do numero zero no display
 CLRF cent
 CLRF dez
 CLRF un
 ; Ponteiro de digito inicia apontando para unidade, limpar pt_digit para que quando chamar a rotina
 ; pt_digit va para 1, indicando unidade
 CLRF pt_digit
 ;Carrega cntd com 25 para ser decrementado a cada interrupcao do timer 0
 movlw d'75'
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
 
INCRNUM
 ;Incrementa a variavel un(idade) e deixa o resultado no registro un
 incf un, 1
 ;Testa se a unidade chegou a 10, carregando 10 em W e subtraindo de un deixando resultado em W
 ;Se un diferente de 10, retorna
 movlw 0x0a
 subwf un, W
 btfss STATUS, Z
 return
 ;Un igual a dez, zera un(idade), incrementa dez(ena) deixando resultado no registro dez
 ;testa se a dez(ena) chegou a 10, carregando 10 em W e subtraindo de dez deixando resultado em W
 ;Se dez diferente de 10, retorna 
 clrf un
 incf dez, 1
 movlw 0x0a
 subwf dez, W
 btfss STATUS, Z
 return
 ;Dez igual a dez, zera dez(ena), incrementa cent(ena) deixando resultado no registro cent
 ;testa se a cent(ena) chegou a 10, carregando 10 em W e subtraindo de dez deixando resultado em W
 ;Se cent diferente de 10, retorna
 clrf dez
 incf cent, 1
 movlw 0x0a
 subwf cent, W
 btfss STATUS, Z
 return
 ;Chegou ao final, contagem 999, volta un dez cent para zero
 clrf cent
 clrf dez
 clrf un
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
 
 END

