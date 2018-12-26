    ORG 0000H
    LJMP START
    ORG 000BH
    LJMP T0INT

;------------------------------------------
;定义IO口
    DataBus EQU P3.5
    ClockBus EQU P3.4

;------------------------------------------
;字形码
    TAB:    DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H, 0FFH, 0C7H
;------------------------------------------
;定义一些常量
    T0COUNTH EQU 4CH
    T0COUNTL EQU 00H        ;定时器0的常量延时位5ms(0.005S)
;-----------------------------------------

START:
    MOV A, #0
    LCALL UPDATE_SPEC
    LCALL InitTimer0

LOOP:AJMP LOOP
;----------------------------------------

;---------------------------------------
;T0的中断子程序
;----------------------------------------
T0INT:
        LCALL InitTimer0
        INC A
        CJNE A, #100, NEXT
        MOV A, #0
    NEXT:
        LCALL UPDATE_SPEC
    RETI
;----------------------------------------

;-------------------------------------
; 特殊的屏幕刷新函数用于两个数码管的显示控制
;输入：需要显示的0~100间的数字放入ACC
;输出: NONE
;-------------------------------------
UPDATE_SPEC:
    push ACC

    MOV B, #10
    DIV AB
    LCALL DISPLAY
    MOV A, B
    LCALL DISPLAY

    POP ACC
    RET
;-------------------------------------


;-------------------------------------
; DISPLAY函数用于单个数码管的显示控制
;输入：需要显示的数字编码放入A
;输出: NONE
;-------------------------------------
DISPLAY:
        PUSH DPL 
        PUSH DPH 
        PUSH 04H

        MOV DPTR, #TAB
        MOVC A, @A+DPTR
        MOV R4, #8
    DIS:
        RLC A
        MOV DataBus, C
        CLR ClockBus
        NOP
        NOP
        NOP
        SETB ClockBus
        DJNZ R4, DIS

        POP 04H
        POP DPH
        POP DPL      
        RET
;-------------------------------------


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
