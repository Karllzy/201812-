    ORG 0000H
    LJMP START
    ORG 000BH
    LJMP T0INT
;------------------------------------------
;定义一些IO口
    LED1 EQU P1.0
    LED2 EQU P1.1
    LED3 EQU P1.2
;------------------------------------------

;------------------------------------------
;定义一些常量
    T0COUNTH EQU 0EEH
    T0COUNTL EQU 00H        ;定时器0的常量延时位5ms(0.005S)
    LED_T   EQU 100
;------------------------------------------

;------------------------------------------
;定义变量
    LED_conunter EQU 14H       ;控制LED的计时周期
;------------------------------------------


START:
    MOV LED_conunter, #LED_T
    LCALL InitTimer0
MAIN:AJMP MAIN


;------------------------------------------
;初始化和启动定时器0
;------------------------------------------
InitTimer0:
    MOV TMOD, #01H
    MOV TH0, #T0COUNTH  ;装入初值
    MOV TL0, #T0COUNTL
    SETB EA             ;打开总开关
    SETB ET0            ;T0中断使能
    SETB TR0            ;T0计时开始
    RET
;------------------------------------------


;-------------------------------------------
T0INT:
        PUSH DPH
        PUSH DPL

        LCALL InitTimer0

        DJNZ LED_conunter, next 
        MOV A,P1
        CPL A
        MOV P1, A
        MOV LED_conunter, #LED_T
    next:
        POP DPL
        POP DPH
        RETI
;--------------------------------------------

