    ORG 0000H
    LJMP MAIN

;-----------------------------------------
;定义一些IO口
    LED1 EQU P1.0
    LED2 EQU P1.1
    LED3 EQU P1.2
    BUTTON1 EQU P2.0
    BUTTON2 EQU P2.1
    BUTTON3 EQU P2.2
    BUTTON4 EQU P2.3

MAIN:
    JNB BUTTON1, K1
    JNB BUTTON2, K2
    JNB BUTTON3, K3
    JNB BUTTON4, K4
    AJMP MAIN
;-------------------------------------------
K1:
        LCALL DELAY10MS
        JB  BUTTON1, MAIN
    LOPK1:JNB BUTTON1, LOPK1
        CLR LED1
        LJMP MAIN
;-------------------------------------------


;-------------------------------------------
K2:
        LCALL DELAY10MS
        JB  BUTTON2, MAIN
    LOPK2:JNB BUTTON2, LOPK2
        CLR LED2
        LJMP MAIN
;-------------------------------------------


;-------------------------------------------
K3:
        LCALL DELAY10MS
        JB  BUTTON3, MAIN
    LOPK3:JNB BUTTON3, LOPK3
        CLR LED3
        LJMP MAIN
;-------------------------------------------

;-------------------------------------------
K4:
        LCALL DELAY10MS
        JB  BUTTON4, MAIN
    LOPK4:JNB BUTTON4, LOPK4
        SETB LED3
        SETB LED2
        SETB LED1
        LJMP MAIN
;-------------------------------------------


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
