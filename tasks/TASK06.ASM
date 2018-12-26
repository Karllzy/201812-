;任务六中74LS244的地址:
;即RD和P2.7需要置为00才能使得（1G非）和（2G非）都为低电平
;读取方式1：使用片外RAM（MOVX）自动使得RD置为电平则P2.7=0,其余为1即可
;           可知在这种方式下，其地址为7FFFH
;读取方式2：把RD非看作是IO口（P3.7），直接使用MOV指令，CLR P2.7, CLR P3.7, MOV A, P0
;本程序中使用读取方式1
;本程序的要求是16进制转换为10进制
;但拨码开关仅支持2进制，故本程序仅将2进制转化为10进制

    ORG 0000H
    LJMP MAIN

;------------------------------------------
;定义一些IO口
    LED1 EQU P1.0
    LED2 EQU P1.1
    LED3 EQU P1.2
    BUTTON1 EQU P2.0
    BUTTON2 EQU P2.1
    BUTTON3 EQU P2.2
    BUTTON4 EQU P2.3
    DataBus EQU P3.5
    ClockBus EQU P3.4
;------------------------------------------
;字形码
    TAB:    DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H, 0FFH, 0C7H
;------------------------------------------


;------------------------------------------
;主程序
;------------------------------------------
MAIN:
    SETB LED1
    JNB BUTTON1, k1
    AJMP MAIN
;----------------------------------------


;-------------------------------------
k1:
        CLR LED1
        LCALL DELAY10MS
        JB  BUTTON1, MAIN
    LOPK1:JNB BUTTON1, LOPK1
        SETB LED1

        LCALL ReadSwitchMod1
        LCALL UPDATE_SPEC

        LJMP MAIN
;-------------------------------------------

;-------------------------------------
;读入拨码开关的数值
;输入：NONE
;输出: 读入的数-->ACC
;-------------------------------------
ReadSwitchMod1:
    PUSH DPL
    PUSH DPH

    MOV DPTR, #7FFFH
    MOVX A, @DPTR

    POP DPH
    POP DPL
    RET
;-----------------------------------------


;-------------------------------------
;读入拨码开关的数值
;输入：NONE
;输出: 读入的数-->ACC
;-------------------------------------
ReadSwitchMod2:
    PUSH DPL
    PUSH DPH

    CLR P3.7
    CLR P2.7

    MOV A, P0

    SETB P3.7
    SETB P2.7

    POP DPH
    POP DPL
    RET
;-----------------------------------------


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


;-------------------------------------
;延时10MS,用于等待人手消去按钮抖动
;-------------------------------------
DELAY10MS:
        push 07H
        PUSH 06H
        PUSH 05H

        MOV R7,#01H
    DL1:
        MOV R6,#26H
    DL0:
        MOV R5,#82H
        DJNZ R5,$
        DJNZ R6,DL0
        DJNZ R7,DL1
        
        POP 05H
        POP 06H
        POP 07H
        RET
;-------------------------------------
