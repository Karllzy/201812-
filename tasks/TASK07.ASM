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
    MOTOR   EQU P3.2
    BEEF    EQU P3.3
    DataBus EQU P3.5
    ClockBus EQU P3.4
;------------------------------------------


;------------------------------------------
;字形码
    TAB:    DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H, 0FFH, 0C7H
;------------------------------------------


;------------------------------------------
;定义一些常量
    T0COUNTH EQU 4CH
    T0COUNTL EQU 00H        ;定时器0的常量延时位50ms(0.05S)
    SECONDT  EQU 20         ;1秒需要计算20次中断 20x50ms = 1s
;--------------------------------------------


;---------------------------------------------
;定义一些变量
    SecondControl EQU 1FH   ;秒控制
    SetWaitTime   EQU 1EH   ;用户设定的需要等待多少秒
    SetRunTime    EQU 1DH   ;用户设定的需要运行多少秒后停止
    Timer         EQU 1CH   ;计时显示使用的变量
    motorState    EQU 00H   ;用于控制开关
;---------------------------------------------


;---------------------------------------------
START:
    MOV SetWaitTime, #5
    MOV SetRunTime, #1
    MOV SecondControl, #SECONDT 
    CLR motorState          ;开机时MOTOR为关闭状态
    
    SETB MOTOR
    SETB BEEF
MAIN:
    JNB BUTTON1, k1
    JNB BUTTON2, k2
    JNB BUTTON3, K3
    JNB BUTTON4, K4
    AJMP MAIN
;---------------------------------------------


;---------------------------------------------
;在此程序中K1的功能是显示等待启动的时间
;---------------------------------------------
k1:
        CLR LED2                   
        LCALL DELAY10MS
        JB  BUTTON1, MAIN            
    LOPK1:JNB BUTTON1, LOPK1
        SETB LED2   
        MOV A, SetWaitTime
        LCALL UPDATE_SPEC
        LJMP MAIN
;--------------------------------------------- 


;---------------------------------------------
;在此程序中K3的功能是显示运行的时间
;---------------------------------------------
k2:
        CLR LED3                   
        LCALL DELAY10MS
        JB  BUTTON2, MAIN            
    LOPK2:JNB BUTTON2, LOPK2
        SETB LED3   
        MOV A, SetRunTime
        LCALL UPDATE_SPEC
        LJMP MAIN
;---------------------------------------------


;---------------------------------------------
;在此程序中K3的功能是确认并开始运行
;---------------------------------------------
k3:
        CLR LED2                   
        LCALL DELAY10MS
        JB  BUTTON3, MAIN            
    LOPK3:JNB BUTTON3, LOPK3
        SETB LED2 
        MOV Timer, SetWaitTime
        LCALL UPDATE_SPEC
        LCALL InitTimer0
        LJMP MAIN
;---------------------------------------------


;---------------------------------------------
;在此程序中K3的功能是确认并开始运行
;---------------------------------------------
K4:
        CLR LED3  
        CLR MOTOR
        CLR BEEF                 
        LCALL DELAY10MS
        JB  BUTTON4, MAIN            
    LOPK4:JNB BUTTON4, LOPK4
        SETB LED3
        SETB MOTOR
        SETB BEEF
        LJMP MAIN
;---------------------------------------------


;----------------------------------------------
T0INT:
        LCALL InitTimer0
        CPL LED1
        DJNZ SecondControl, OVERTOINT
        MOV SecondControl, #SECONDT
        DJNZ Timer, notTime0
        ;到达了计时0点

        JB motorState, toClose
        ;看目前电机是否打开，若打开，则关闭并结束中断
        MOV Timer, SetRunTime
        CLR MOTOR
        CLR BEEF
        SETB motorState
        JMP notTime0
    toClose:
        SETB MOTOR
        SETB BEEF
        CLR motorState
        CLR ET0

    notTime0:
        MOV A, Timer
        LCALL UPDATE_SPEC
    OVERTOINT:
        RETI
;-------------------------------------


;-------------------------------------
;初始化和启动定时器0
;-------------------------------------
InitTimer0:
    MOV TMOD, #01H
    MOV TH0, #T0COUNTH  ;装入初值
    MOV TL0, #T0COUNTL
    SETB EA             ;打开总开关
    SETB ET0            ;T0中断使能
    SETB TR0            ;T0计时开始
    RET
;-------------------------------------


;-------------------------------------
;读入拨码开关的数值
;输入：NONE
;输出: 读入的数1-->ACC
;     读入的数2--->B
;-------------------------------------
ReadSwitchToAB:
    PUSH DPL
    PUSH DPH

    MOV DPTR, #7FFFH
    MOVX A, @DPTR
    MOV B, #16
    DIV AB

    POP DPH
    POP DPL
    RET
;-------------------------------------


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

