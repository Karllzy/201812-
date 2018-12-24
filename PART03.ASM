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
;------------------------------------------
;定义一些常量
    PwdWaitT1 EQU 200       ;输入密码的等待时长(200x5ms = 1s) 
    PwdWaitT2 EQU 4         ;输入密码的等待时长（3x1s = 3s)
    ScreenWaitT EQU 60      ;屏幕刷新周期，可在0~255中选择（1最小1x5ms，0最大256x5ms）
    LEDWaitT EQU 30         ;LED刷新周期，可在0~255中选择（1最小1x5ms，0最大256x5ms）
    
    T0COUNTH EQU 0EEH
    T0COUNTL EQU 00H        ;定时器0的常量延时位5ms(0.005S)
    T1COUNT EQU 0F6H

;------------------------------------------
;字形码
    TAB:    DB 0C0H, 0F9H, 0A4H, 0B0H, 99H,92H, 82H, 0F8H, 80H, 90H, 0FFH, 0C7H
;------------------------------------------
;定义一些变量
    ;数组们
    PWD EQU 18H     ;18H~1BH的4位数据,密码起始点
    TPWD EQU 1CH    ;1CH~1FH的4位数据，尝试及显示密码点
    ;字节们
    SHUMA1 EQU 17H  ;数码管1号
    SHUMA2 EQU 16H  ;数码管2号
    UPT EQU 15H     ;屏幕刷新周期
    LEDT EQU 14H    ;LED亮灭的周期
    TryWaitT1 EQU 13H ;输入密码等待周期1
    TryWaitT2 EQU 12H ;输入密码等待周期2
    FailTimes EQU 11H ;记录失败的次数
    ;位们
    ScreenState EQU 00H ;屏幕亮灭状态
    LockState   EQU 01H ;密码锁当前锁定状态
    TryState    EQU 02H ;密码锁是否在尝试解锁状态
;-----------------------------------------


;-----------------------------------------
START:
    
    MOV TH1, #T1COUNT
    MOV TL1, #T1COUNT
    LCALL InitTimer0    ;开启定时器0
    
    SETB ClockBus       ;屏幕时钟线拉高
    SETB DataBus        ;屏幕数据线拉高

    MOV UPT, #ScreenWaitT   ;初始化屏幕周期 
    MOV LEDT, #LEDWaitT     ;初始化LED周期
    MOV FailTimes, #0       ;初始化失败次数为0

    LCALL UPDATE        ;刷新一下屏幕
    CLR LED1            ;点亮指示灯表示运行中
    CLR ScreenState     ;灭掉屏幕
    CLR LockState       ;把锁打开
    CLR TryState        ;没有处在尝试解锁的状态

MAIN:
    JNB BUTTON1, K1
    JNB BUTTON2, K2
    JNB BUTTON3, K3
    JNB BUTTON4, K4   
    AJMP MAIN

;-------------------------------------
k1:
        CLR LED2                   
        LCALL DELAY10MS
        JB  BUTTON1, MAIN            
    LOPK1:JNB BUTTON1, LOPK1
        SETB LED2    
        JB TryState, Trying1
        JB LockState, LOCK1
    Trying1:
        MOV A, SHUMA2
        CJNE A, #0, NotNull
        MOV SHUMA2, #0AH
    NotNull:
        DEC SHUMA2
 
    LOCK1:
        LCALL UPDATE
        LJMP MAIN 
;-------------------------------------
k2:
        CLR LED3                   
        LCALL DELAY10MS
        JB  BUTTON2, MAIN           
    LOPK2:JNB BUTTON2, LOPK2
        SETB LED3
        JB TryState, Trying2
        JB LockState, LOCK2
    Trying2:
        MOV A, SHUMA2
        CJNE A, #9, NotFull
        MOV SHUMA2, #0FFH
    NotFull:
        INC SHUMA2
 
    LOCK2:
        LCALL UPDATE
        LJMP MAIN 
;-------------------------------------
k3:
        CLR LED2                   
        LCALL DELAY10MS
        JB  BUTTON3, MAIN            
    LOPK3:JNB BUTTON3, LOPK3
        SETB LED2
        JB TryState, Trying3
        JB LockState, LOCK3
    Trying3:
        LCALL K3FUNC    
    LOCK3:
        LCALL UPDATE
        LJMP MAIN
;-------------------------------------
k4:
        CLR LED3                   
        LCALL DELAY10MS
        JB  BUTTON4, MAIN            
    LOPK4:JNB BUTTON4, LOPK4           
        SETB LED3

        JB LockState, LOCK4         ;若果处在锁定状态，查看是否处于尝试状态
        LCALL save                  ;开锁状态则存储密码并锁上
        JMP  OVERK4

    LOCK4:
        JB TryState, CHECKPWD       ;若已在尝试状态，跳转进行密码检查
        LCALL GOTO2                 ;若处在锁定状态打开尝试状态
        JMP OVERK4                   

    CHECKPWD:
       LCALL CheckPassword          ;若处在锁定状态且处在尝试状态

    OVERK4:
        LCALL UPDATE
        LJMP MAIN    
;------------------------------------


;------------------------------------
;T0的中断子程序
;------------------------------------
T0INT:
        PUSH DPH
        PUSH DPL

        LCALL InitTimer0
        ;检查是否需要刷新LED
        DJNZ LEDT, NextScreen
        CPL LED1
        MOV LEDT, #LEDWaitT
    NextScreen:
        ;检查是否需要刷新屏幕
        DJNZ UPT, NextTrying
        LCALL UPDATE
        MOV UPT,#ScreenWaitT
    NextTrying:
        ;检查是否处于尝试状态
        JNB TryState, OVERINT0
        DJNZ TryWaitT1, OVERINT0
        MOV TryWaitT1, #PwdWaitT1
        DJNZ TryWaitT2, OVERINT0
        MOV TryWaitT2, #PwdWaitT2

        CLR TryState                
        ;关闭尝试密码状态

        MOV SHUMA1, #0BH
        mov SHUMA2, #0BH
        LCALL UPDATE
    OVERINT0:
        POP DPL 
        POP DPH
        RETI
;------------------------------------


;------------------------------------
; UPDATE函数用于刷新屏幕状态
;输入:NONE
;输出：None
;-------------------------------------
UPDATE:
        PUSH ACC
        CPL ScreenState
        MOV A, SHUMA1
        LCALL DISPLAY
        MOV A, SHUMA2
        JB TryState, TryingScreen
        JB LockState, TOLIGHT
    TryingScreen:
        JB ScreenState, TOLIGHT
        MOV A, #0AH
    TOLIGHT:
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
;延时10us
;-------------------------------------
DELAY10US:   
        MOV R6,#01H
    DL10:
        MOV R5,#01H
        DJNZ R5,$
        DJNZ R6,DL10
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


;-------------------------------------
;按钮3（*）的功能
;输入：SHUMA1, SHUMA2
;返回：空
;-------------------------------------
K3FUNC:
        PUSH DPH
        PUSH DPL
        PUSH ACC
        PUSH 00H 

        MOV A, SHUMA1           
        ADD A, #TPWD
        MOV R0, A               
        MOV @R0, SHUMA2         ;把当前的数码管2显示的数字送入TPWD
        
        MOV A, SHUMA1
        CJNE A, #3, NotFullShu1
        MOV SHUMA1, #0FFH
    NotFullShu1:
        INC SHUMA1              ;数码管1增长1位，若不到3则加1，到了3就到0

        MOV A, SHUMA1
        ADD A, #TPWD
        MOV R0, A
        MOV SHUMA2, @R0         ;把当前数码管1对应的密码值显示出来
        
        POP 00H 
        POP ACC
        POP DPL
        POP DPH
        RET
;-------------------------------------


;-------------------------------------
;按钮4（#）在状态0时的存储功能
;-------------------------------------
save:
        MOV R0, #PWD                ;目标地址
        MOV R1, #TPWD               ;数据源地址
        MOV R5, #4                  ;存储的字节数
    NextNumber:
        MOV A, @R1
        MOV @R0, A
        MOV A, #0
        MOV @R1, A                  ;把原本的数字消掉
        INC R0
        INC R1
        DJNZ R5, NextNumber
        SETB LockState              ;把锁锁上
        MOV TryWaitT1, #PwdWaitT1
        MOV TryWaitT2, #PwdWaitT2
        MOV SHUMA1, #0BH 
        MOV SHUMA2, #0BH            ;进入锁住的状态
        LCALL UPDATE
        RET
;-------------------------------------


;------------------------------------
;按钮4（#）在状态1时的迁移功能
;转移到状态2
;------------------------------------
GOTO2:
        SETB TryState               ;进入尝试状态
        MOV SHUMA1, #0H 
        MOV SHUMA2, #0H 
        LCALL UPDATE
        RET
;------------------------------------


;------------------------------------
;按钮4检验密码是否与存储密码相同
;------------------------------------
CheckPassword:
        MOV R0, #PWD
        MOV R1, #TPWD
        MOV R5, #4

    CHECKNEXT:
        MOV A, @R1
        MOV B, A
        MOV A, @R0
        CJNE A, B, FAILED
        INC R0
        INC R1
        DJNZ R5, CHECKNEXT
        ;4位都相等后认为解锁成功
        
        MOV SHUMA1, #00H
        MOV SHUMA2, #00H
        CLR TryState
        CLR LockState               ;进入解锁状态
        CLR BEEF
        MOV R5, #50
    CONTINUE:
        LCALL DELAY10MS
        DJNZ R5, CONTINUE

        SETB BEEF
        MOV FailTimes, #0           ;失败次数重置为0
        JMP OverCheck

    FAILED:
        INC FailTimes
        MOV A, FailTimes
        CLR C
        SUBB A, #3
        JNC NOT3
        CLR BEEF
    NOT3:
        CLR TryState
        MOV SHUMA1, #0BH 
        MOV SHUMA2, #0BH

    OverCheck:
        LCALL UPDATE
        RET

;------------------------------------


;------------------------------------
END