    ORG 0000H
    LJMP START

    DataBus EQU P3.5
    ClockBus EQU P3.4

;------------------------------------------
;字形码
    TAB:    DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H, 0FFH, 0C7H
;------------------------------------------


;-----------------------------------------
START:
    MOV A, #0
NEXT:
    LCALL UPDATE_SPEC
    LCALL DELAY50MS
    INC A
    CJNE A, #100, NEXT
    LJMP START
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


;-------------------------------------
;延时50MS，@11.0592MHz
;-------------------------------------
DELAY50MS:			
        NOP
        NOP
        NOP
        PUSH 30H
        PUSH 31H
        PUSH 32H
        MOV 30H,#2
        MOV 31H,#175
        MOV 32H,#72
    INDEL50:
        DJNZ 32H,INDEL50
        DJNZ 31H,INDEL50
        DJNZ 30H,INDEL50
        POP 32H
        POP 31H
        POP 30H
        RET
;--------------------------------------