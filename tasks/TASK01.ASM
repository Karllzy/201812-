    ORG 0000H
    LJMP MAIN

;-----------------------------------------
;定义一些IO口
    LED1 EQU P1.0
    LED2 EQU P1.1
    LED3 EQU P1.2
;-----------------------------------------


;-----------------------------------------
;主程序
MAIN:
    CLR LED1
    LCALL DELAY500MS
    SETB LED1
    CLR LED2
    LCALL DELAY500MS
    SETB LED2
    CLR LED3
    LCALL DELAY500MS
    SETB LED3
    AJMP MAIN
;------------------------------------------


;------------------------------------------
;超级长的延时函数           @11.0592MHz
DELAY500MS:			
        NOP
        NOP
        NOP
        PUSH 30H
        PUSH 31H
        PUSH 32H
        MOV 30H,#17
        MOV 31H,#208
        MOV 32H,#24
    NEXT:
        DJNZ 32H,NEXT
        DJNZ 31H,NEXT
        DJNZ 30H,NEXT
        POP 32H
        POP 31H
        POP 30H
        RET
;------------------------------------------