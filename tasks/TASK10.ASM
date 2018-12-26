    ORG 0000H
    LJMP START
    ORG 000BH
    LJMP T0INT

;-----------------------------------------
;定义一些IO口
    LED1 EQU P1.0
    LED2 EQU P1.1
    LED3 EQU P1.2
    BUTTON1 EQU P2.0
    BUTTON2 EQU P2.1
    BUTTON3 EQU P2.2
    BUTTON4 EQU P2.3
    BEEF EQU P3.3
    DataBus EQU P3.5
    ClockBus EQU P3.4
;------------------------------------------
;字形码
    TAB:    DB 0C0H, 0F9H, 0A4H, 0B0H, 99H,92H, 82H, 0F8H, 80H, 90H, 0FFH, 0C7H
;------------------------------------------
;定义一些常量
    T0COUNTH EQU 0EEH
    T0COUNTL EQU 00H        ;定时器0的常量延时位5ms(0.005S)
    T1COUNT EQU 0F6H
    ScreenWaitT EQU 60      ;屏幕刷新周期，可在0~255中选择（1最小1x5ms，0最大256x5ms）
    LEDWaitT EQU 30         ;LED刷新周期，可在0~255中选择（1最小1x5ms，0最大256x5ms）
;------------------------------------------
;定义的一些变量
    SHUMA1 EQU 17H  ;数码管1号
    SHUMA2 EQU 16H  ;数码管2号
    UPT EQU 15H     ;屏幕刷新周期
    LEDT EQU 14H    ;LED亮灭的周期
    ;位们
    ScreenState BIT 00H ;屏幕亮灭状态
    SHAN1   BIT 01H     ;数码管1是否闪烁
    SHAN2   BIT 02H     ;数码管2是否闪烁
;-----------------------------------------
START:
    MOV SHUMA1, #0
    MOV SHUMA2, #0
    MOV UPT, #ScreenWaitT
    MOV LEDT, #LEDWaitT
    LCALL InitTimer0    ;开启定时器0
    CLR ScreenState
    SETB SHAN1          ;尝试着让数码管1闪动
    CLR SHAN2
    MAIN:
    JNB BUTTON1, K1
    JNB BUTTON2, K2
    JNB BUTTON3, K3
    JNB BUTTON4, K4   
    AJMP MAIN

;----------------------------------------
T0INT:
        PUSH DPH
        PUSH DPL
        LCALL InitTimer0
        ;检查是否需要刷新LED
        DJNZ LEDT, nextScreen
        CPL LED1
        MOV LEDT, #LEDWaitT
    nextScreen:
        ;检查是否需要刷新屏幕
        DJNZ UPT, overT0INT
        LCALL UPDATE
        MOV UPT, #ScreenWaitT
    overT0INT:
        POP DPL
        POP DPH
        RETI
;----------------------------------------


;-------------------------------------
;S键设定功能
;-------------------------------------
k1:
        CLR LED2                   
        LCALL DELAY10MS
        JB  BUTTON1, MAIN            
    LOPK1:JNB BUTTON1, LOPK1
        SETB LED2    

        LJMP MAIN
;-------------------------------------


;-------------------------------------
;R键，运行功能
;--------------------------------------
k2:
        CLR LED3                   
        LCALL DELAY10MS
        JB  BUTTON2, MAIN            
    LOPK2:JNB BUTTON2, LOPK2
        SETB LED3   
        

        LJMP MAIN
;-------------------------------------


;--------------------------------------
;左移键⬅，向左移动要设定的值
;-------------------------------------
k3:
        CLR LED2                   
        LCALL DELAY10MS
        JB  BUTTON3, MAIN            
    LOPK3:JNB BUTTON3, LOPK3
        SETB LED2    
        JB SHAN1, moveToJingTai
        JB SHAN2, moveToState1
        
        CLR SHAN1
        SETB SHAN2
        JMP OVERK3

    moveToState1:
        SETB SHAN1
        CLR SHAN2
        JMP OVERK3
    
    moveToJingTai:
        CLR SHAN1
        CLR SHAN2
        
    OVERK3:
        LCALL UPDATE
        LJMP MAIN
;-------------------------------------


;------------------------------------
;上移键↑，将设定值增加1
;-------------------------------------
k4:
        PUSH ACC
        CLR LED3                   
        LCALL DELAY10MS
        JB  BUTTON4, MAIN            
    LOPK4:JNB BUTTON4, LOPK4
        SETB LED3    
        JB SHAN1, modify1
        JB SHAN2, modify2
        JMP OVERK4
    modify1:
        MOV A, SHUMA1
        CJNE A, #9, not91
        MOV A, #0FFH
    not91:
        INC A
        MOV SHUMA1, A 
        JMP OVERK4
    modify2:
        MOV A, SHUMA2
        CJNE A, #9, not92
        MOV A, #0FFH
    not92:
        INC A
        MOV SHUMA2, A 
        JMP OVERK4
    OVERK4:
        POP ACC
        LCALL UPDATE
        LJMP MAIN
;------------------------------------


;------------------------------------
; UPDATE函数用于刷新屏幕状态
;输入:NONE
;输出：None
;-------------------------------------
UPDATE:
        PUSH ACC

        CPL ScreenState
        JNB ScreenState, ALLLIGHT
        JB SHAN1, SHANDONG1
        JNB SHAN2, ALLLIGHT
        MOV A, SHUMA1
        LCALL DISPLAY
        MOV A, #0AH 
        LCALL SHUMA2
        JMP OVERUPDATE
    SHANDONG1:
        MOV A, #0AH
        LCALL SHUMA1
        MOV A, SHUMA2
        LCALL DISPLAY
        JMP OVERUPDATE
    ALLLIGHT:
        MOV A, SHUMA1
        LCALL DISPLAY
        MOV A, SHUMA2
        LCALL DISPLAY
    OVERUPDATE:

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
        ;LCALL DELAY10US
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


;-------------------------------------
;初始化和启动定时器0
;-------------------------------------
InitTimer0:
    MOV TMOD, #21H
    MOV TH0, #T0COUNTH  ;装入初值
    MOV TL0, #T0COUNTL
    SETB EA             ;打开总开关
    SETB ET0            ;T0中断使能
    SETB TR0            ;T0计时开始
    RET
;-------------------------------------