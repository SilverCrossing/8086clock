;====================================================================
; Main.asm file generated by New Project wizard
;
; Created:   周五 1月 12 2024
; Processor: 8086
; Compiler:  MASM32
;
; Before starting simulation set Internal Memory Size 
; in the 8086 model properties to 0x10000
;====================================================================

;====================================================================
;Warning: 这边的代码为了方便读，是处理过的，在修改注释变得更可读的时候很可能
;		  无意间修改了某些代码，可能出现这边代码无法正常运行的情况
;====================================================================
STACKS SEGMENT STACK
	DD 256 DUP (?)
STACKS ENDS

CTRL_PORT EQU 0106H   ; 控制端口
A_PORT EQU 0100H   ; A端口
B_PORT EQU 0102H   ; B端口
C_PORT EQU 0104H   ; C端口
COUNT EQU 0206H   ; 计数器端口
COUNT0 EQU 0200H   ; 计数器0端口
COUNT1 EQU 0202H   ; 计数器1端口
INTR EQU 0304H   ; 中断端口
INTR1 EQU 0306H   ; 中断1端口
DCOUNT EQU 6   ; 数据个数为6

DATA SEGMENT
    LEDTAB DB 3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH, 77H, 7CH, 39H, 5EH, 79H, 71H, 77H, 7CH, 39H, 5EH, 79H, 71H   ; 数码管显示表，依次对应从0~9该点亮的段
    BUF DB 0, 0, 0, 0, 0, 0   ; 缓冲区，用来储存要显示的六位数
    BUFF DB 20 DUP(?)   ; 另一个缓冲区
    STARTBUFF DB 0, 0, 0, 0, 0, 0   ; 储存开始时间的六位数
    STOPBUFF DB 0, 0, 0, 0, 0, 0   ; 储存结束时间的六位数
    DAT1 DB 0
    DAT2 DB 0 
    DAT3 DB 1
    DAT4 DB 0
	FT DB 1   ; 判断是否首次按下暂停
DATA ENDS

CODE SEGMENT               
	ASSUME CS:CODE, DS:DATA
START: CLI   ; 关闭中断
	PUSH DS   ; 保存DS寄存器的值
	MOV SI, 2*4   ; SI = 8，指向中断向量表的第四项
	MOV AL, 1
	MOV FT, AL
	MOV AL, 0
	MOV AX, 0
	MOV DS, AX   ; 指向中断向量表的段地址
	MOV [SI], OFFSET INTB   ; 将INTB的偏移地址存入中断向量表的第四项
	MOV 2[SI], SEG INTB   ; 将INTB的段地址存入中断向量表的第四项
	POP DS   ; 恢复DS寄存器的值
	MOV AL, 00010011B   ; AL = 00010011B，设置中断控制器的工作方式
	MOV DX, INTR
	OUT DX, AL   ; 将AL的值输出到中断端口
	MOV AL, 00000010B   ; AL = 00000010B，设置中断1的屏蔽位
	MOV DX, INTR1
	OUT DX, AL   ; 将AL的值输出到中断1端口
	MOV AL, 00000001B   ; AL = 00000001B，设置中断1的触发方式
	MOV DX, INTR1
	OUT DX, AL   ; 将AL的值输出到中断1端口
	STI   ; 开启中断
	MOV AX, DATA
	MOV DS, AX
	MOV AL, 00110111B   ; AL = 00110111B，设置8253定时器的工作方式
	MOV DX, COUNT
	OUT DX, AL   ; 将AL的值输出到计数器端口
	MOV DX, COUNT0
	MOV AX, 0500H   ; AX = 0500H，设置计数器0的计数值
	OUT DX, AL   ; 将AX的低字节输出到计数器0端口
	MOV AL, AH   ; AL = AH，将AX的高字节赋给AL
	OUT DX, AL   ; 将AL的值输出到计数器0端口
	
	MOV AL, 01110111B   ; AL = 01110111B，设置8253定时器的工作方式       
	MOV DX, COUNT
	OUT DX, AL   ; 将AL的值输出到计数器端口
	MOV DX, COUNT1
	MOV AX, 50H   ; AX=50H，设置计数器1的计数值
	OUT DX, AL
	MOV AL, AH
	OUT DX, AL   ; 将AL的值输出到计数器1端口
	MOV AL, 10000001B   ; AL = 10000001B，设置8255并口的工作方式
	MOV DX, CTRL_PORT
	OUT DX, AL   ; 将AL的值输出到控制端口
	CALL SAVESTOP


; 定义一个标签BACK，用来跳转
BACK: MOV DX, C_PORT
	IN AL, DX   ; 将C端口的值输入到AL寄存器
	TEST AL, 00000010B   ; 测试AL的第1位，即C端口的第1位，是否为1
	JZ B2   ; 如果为1，跳转到B2标签，表示要清零

; 定义一个标签AGAIN，用来循环
AGAIN: MOV DX, C_PORT
	IN AL, DX   ; 将C端口的值输入到AL寄存器
	TEST AL, 00000001B   ; 测试AL的第0位，即C端口的第0位，是否为1
	JZ B1   ; 如果为1，跳转到B1中转程序，表示要暂停
	MOV CX,6


SHOWTIME: MOV DX, C_PORT
	IN AL, DX   ; 将C端口的值输入到AL寄存器
	TEST AL, 00001000B   ; 测试AL的第3位，即C端口的第3位，是否为1
	JNZ B3   ; 如果不为1，跳转到B3标签，表示要显示最近一次的计数结果

AD6: INC SI
	LOOP AD6
	MOV AL, 00000000B
	MOV DX, C_PORT
	OUT DX, AL   ; 将AL的值输出到C端口，清空C端口的值

	MOV AL, DAT1
	CMP AL, 100   ; 比较0.01秒和100的大小
	JZ A1   ; 如果相等，跳转到A1标签，表示0.01秒数满100
	MOV BL, 10
	DIV BL
	MOV BUF, AH
	MOV BUF+1, AL
	CALL DISPLAY_DEC
	INC DAT1   ; 增加0.01秒数
	JMP BACK

A1: MOV DAT1, 0   ; DAT1 = 0，满100*10毫秒，对DAT1清零
	MOV AL, 1
	MOV FT, AL   ; FT置1，设为开始暂停情况（也就是说这个需要计时满一秒才能保存）
	MOV AL, 0
	MOV AH, 0
	MOV BUF, AH
	MOV BUF+1, AL
	CALL DISPLAY_DEC
	INC DAT2   ; 增加秒数
	MOV AL, DAT2
	CMP AL, 60   ; 比较秒数和60的大小
	JZ A2   ; 如果相等，跳转到A2标签，表示秒数满60
	MOV BL, 10
	DIV BL
	MOV BUF+2, AH
	MOV BUF+3, AL
	CALL DISPLAY_DEC
	MOV CX,60
	LOOP AGAIN

A2: MOV DAT2, 0   ; DAT2=0，满60分，对DAT2清零
	MOV AL,0
	MOV AH,0
	MOV BUF+2, AH
	MOV BUF+3, AL
	CALL DISPLAY_DEC
	MOV AL, DAT3
	CMP AL, 60   ; 比较分数和60的大小
	JZ A3   ; 如果相等，跳转到A2标签，表示分数满60
	MOV BL,10
	DIV BL
	MOV BUF+4,AH
	MOV BUF+5,AL
	CALL DISPLAY_DEC
	MOV CX, 60
	DEC CX
	JZ BACK


; 定义一个标签A3，用来处理分的进位
A3: INC DAT3
	JMP BACK

; 定义一个标签B1，用来处理暂停的情况
B1: CALL DISPLAY_DEC   ; 调用DISPLAY_DEC子程序，显示当前的计时器
	MOV AL, 01110000B   ; AL = 01110000B，对8253送GATE1控制信号，暂停计数器1
	MOV DX, C_PORT
	OUT DX, AL   ; 将AL的值输出到C端口
	CALL STORAGE   ; 调用STORAGE子程序，保存当前的计数值
	CALL DELAY
	CMP FT, 1   ; 判断是否是首次按下暂停
	JZ B4
	JMP BACK

; 定义一个标签B2，用来处理清零的情况
B2: MOV DX, C_PORT
	IN AL, DX   ; 将C端口的值输入到AL寄存器
	TEST AL, 00000100B   ; 测试AL的第2位，即C端口的第2位，是否为1
	JNZ LI   ; C端口第2位如果不为1，跳转到LI标签，表示要输入数据
	CALL DISPLAY   ; 调用DISPLAY子程序，显示当前的计时器
	CALL DISPLAY_DEC   ; 调用DISPLAY_DEC子程序，显示当前的计时器
	MOV CX, 1
	JZ NEXT2
	MOV SI, 6
	DEC CX
NEXT2: CALL DELAY
	JMP BACK

; 定义一个标签B3，用来处理最近一次计时结果的情况
B3:MOV DX, C_PORT
   IN AL, DX   ; 将C端口的值输入到AL寄存器
   CALL DISPLAYTIME
   CALL DISPLAY_DEC
   CALL DELAY
   JMP BACK

; 定义一个标签B4，用来处理开始暂停时保存结果
B4:CALL SAVESTOP
	PUSH AX
	MOV AL, 0
	MOV FT, AL   ; FT置零，表示此时已经不是开始暂停
	POP AX
	JMP BACK

; 定义一个标签LI，用来处理输入的情况
LI: 
	; 清空BUF缓冲区
	MOV BUF, 0
	MOV BUF+1, 0
	MOV BUF+2, 0
	MOV BUF+3, 0
	MOV BUF+4, 0
	MOV BUF+5, 0
	MOV DAT2, 0
	MOV DAT3, 1     
	CALL DISPLAY_DEC   ; 调用DISPLAY_DEC子程序，显示00:00:00
	;MOV BX,1000
	;JZ BACK
	MOV AL,10110000B   ; AL = 10110000B，对8253送GATE0控制信号，启动计数器0
	MOV DX,C_PORT
	OUT DX,AL   ; 将AL的值输出到C端口
	CALL DELAY
	;DEC BX
	JMP BACK


; 定义一个子程序DISPLAY_DEC，用来显示十进制数
DISPLAY_DEC PROC         
DA:     
	MOV DI, 2   ; DI = 2，用来控制循环次数
DISPAGAIN1:
	MOV BL, BUF   ; BL = BUF，取BUF缓冲区中的第1个字节，即毫秒的十位
	MOV BH, 0
	LEA SI, LEDTAB
	MOV AL, [BX][SI]   ; 从数码表中取出对应的段码
	NOT AL   ; 共阳，将AL的值取反，使得1表示亮，0表示灭
	MOV DX, A_PORT
	OUT DX, AL   ; 将AL的值输出到A端口，用数码管显示个位
	MOV AL, 11100000B   ; AL = 11100000B，设置位选，使得最右边的数码管点亮
	MOV AH, 0
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY

	MOV AL, 0H   ; AL = 0H，清屏，使得所有数码管熄灭
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY1
	CALL DELAY1
	LEA SI, LEDTAB
	MOV BL, BUF+1
	MOV BH, 0
	MOV AL, [BX][SI]   ; 从数码表中取出对应的段码
	NOT AL   ; 共阳，将AL的值取反，使得1表示亮，0表示灭
	MOV DX, A_PORT
	OUT DX, AL   ; 将AL的值输出到A端口，用数码管显示十位
	MOV AL, 11010000B   ; AL = 11010000B，设置位选，使得第二个数码管点亮
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY

	MOV AL, 0H   ; AL = 0H，清屏，使得所有数码管熄灭
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY1
	LEA SI, LEDTAB
	MOV BL, BUF+2
	MOV BH, 0
	MOV AL, [BX][SI]   ; 从数码表中取出对应的段码
	NOT AL	; 共阳，将AL的值取反，使得1表示亮，0表示灭
	MOV DX, A_PORT
	OUT DX, AL   ; 将AL的值输出到A端口，用数码管显示分个位
	MOV AL, 11001000B   ; AL=11001000B，设置位选，使得第三个数码管点亮
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY

	MOV AL, 0H   ; AL=0H，清屏，使得所有数码管熄灭
    MOV DX, B_PORT
    OUT DX, AL   ; 将AL的值输出到B端口，控制位选
    CALL DELAY1
    CALL DELAY1
    LEA SI, LEDTAB
    MOV BL, BUF+3
    MOV BH, 0
    MOV AL, [BX][SI]   ; 从数码表中取出对应的段码
	NOT AL	; 共阳，将AL的值取反，使得1表示亮，0表示灭
    MOV DX, A_PORT
    OUT DX, AL   ; 将AL的值输出到A端口，用数码管显示秒十位
    MOV AL, 11000100B   ; AL=11000100B，设置位选，使得第四个数码管点亮
    MOV DX, B_PORT
    OUT DX, AL   ; 将AL的值输出到B端口，控制位选
    CALL DELAY

    MOV AL, 0H   ; AL = 0H，清屏，使得所有数码管熄灭
    MOV DX, B_PORT
    OUT DX, AL   ; 将AL的值输出到B端口，控制位选
    CALL DELAY1
    LEA SI, LEDTAB
    MOV BL, BUF+4
    MOV BH, 0
    MOV AL, [BX][SI]   ; 从数码表中取出对应的段码
    NOT AL	; 共阳，将AL的值取反，使得1表示亮，0表示灭
    MOV DX, A_PORT
    OUT DX, AL   ; 将AL的值输出到A端口，用数码管显示分个位
	MOV AL, 11000010B   ; AL=11000010B，设置位选，使得第五个数码管点亮
    MOV DX, B_PORT
    OUT DX, AL   ; 将AL的值输出到B端口，控制位选
    CALL DELAY
	
	MOV AL, 0H   ; AL=0H，清屏，使得所有数码管熄灭
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY1
	CALL DELAY1
	LEA SI, LEDTAB
	MOV BL, BUF+5
	MOV BH, 0
	MOV AL, [BX][SI]   ; 从数码表中取出对应的段码
	NOT AL   ; 共阳，将AL的值取反，使得1表示亮，0表示灭
	MOV DX, A_PORT
	OUT DX, AL   ; 将AL的值输出到A端口，用数码管显示分十位	
	MOV AL, 11000001B   ; AL=11000001B，设置位选，使得第六个数码管点亮
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY

	MOV AL, 0H   ; AL=0H，清屏，使得所有数码管熄灭
	MOV DX, B_PORT
	OUT DX, AL   ; 将AL的值输出到B端口，控制位选
	CALL DELAY1

	DEC DI
	JNZ DISPAGAIN1   ; 如果DI不为0，跳转到DISPAGAIN1标签，继续显示
	RET
DISPLAY_DEC ENDP

; 定义一个子程序DELAY，用来延迟一段较长的时间
DELAY PROC
	MOV CX, 1DH
	LOOP $
	RET
DELAY ENDP


; 定义一个子程序DELAY1，用来延迟一段较短的时间
DELAY1 PROC
	MOV CX,3H
	LOOP $
	RET
DELAY1 ENDP


; 定义一个子程序STORAGE，用来保存BUF缓冲区中的六位数到BUFF数组中
STORAGE PROC
	; 入栈，保护原先内容
	PUSH AX
	PUSH BX
	PUSH CX
	
	; 将本次计数结果存入BUFF中
	MOV AL, BUF
	MOV AH, BUF+1
	MOV BL, BUF+2
	MOV BH, BUF+3
	MOV CL, BUF+4
	MOV CH, BUF+5
	MOV BUFF[SI], AL
	MOV BUFF[SI+1], AH
	MOV BUFF[SI+2], BL
	MOV BUFF[SI+3], BH
	MOV BUFF[SI+4], CL
	MOV BUFF[SI+5], CH
	
	; 出栈，恢复原来的内容
	POP AX
	POP BX
	POP CX
	RET
STORAGE ENDP


; 定义一个子程序DISPLAY，用来显示BUFF数组中的六位数
DISPLAY PROC
	; 入栈，保护原先内容
	PUSH AX
	PUSH BX
	PUSH CX
	
	; 从BUFF中取出保存的数
	MOV AL, BUFF[SI]   ; AL = BUFF[SI]，取BUFF数组中的第SI个元素，即毫秒的十位
	MOV AH, BUFF[SI+1]   ; AH = BUFF[SI+1]，取BUFF数组中的第SI+1个元素，即毫秒的百位
	MOV BL, BUFF[SI+2]   ; BL = BUFF[SI+2]，取BUFF数组中的第SI+2个元素，即秒的个位
	MOV BH, BUFF[SI+3]   ; BH = BUFF[SI+3]，取BUFF数组中的第SI+3个元素，即秒的十位
	MOV CL, BUFF[SI+4]   ; CL = BUFF[SI+4]，取BUFF数组中的第SI+4个元素，即分的个位
	MOV CH, BUFF[SI+5]   ; CH = BUFF[SI+5]，取BUFF数组中的第SI+5个元素，即分的十位
	
	; 将数存入缓冲区BUF中
	MOV BUF, AL
	MOV BUF+1, AH
	MOV BUF+2, BL
	MOV BUF+3, BH
	MOV BUF+4, CL
	MOV BUF+5, CH
	
	; 出栈，恢复原来的内容
	POP AX
	POP BX
	POP CX
	RET
DISPLAY ENDP


; 定义一个子程序SAVESTART，用来保存最近一次启动/继续的结果
SAVESTOP PROC
	; 入栈，保护原先内容
	PUSH AX
	PUSH BX
	PUSH CX
	
	; 将上一次STOPBUFF存入STARTBUFF，因为上一次暂停就是这一次的开始
	MOV AL, STOPBUFF
	MOV AH, STOPBUFF+1
	MOV BL, STOPBUFF+2
	MOV BH, STOPBUFF+3
	MOV CL, STOPBUFF+4
	MOV CH, STOPBUFF+5
	MOV STARTBUFF, AL
	MOV STARTBUFF+1, AH
	MOV STARTBUFF+2, BL
	MOV STARTBUFF+3, BH
	MOV STARTBUFF+4, CL
	MOV STARTBUFF+5, CH
	
	; 将将本次计数存入STOPBUFF
	MOV AL, BUF
	MOV AH, BUF+1
	MOV BL, BUF+2
	MOV BH, BUF+3
	MOV CL, BUF+4
	MOV CH, BUF+5
	MOV STOPBUFF, AL
	MOV STOPBUFF+1, AH
	MOV STOPBUFF+2, BL
	MOV STOPBUFF+3, BH
	MOV STOPBUFF+4, CL
	MOV STOPBUFF+5, CH
	
	; 出栈，恢复原来的内容
	POP AX
	POP BX
	POP CX
	RET
SAVESTOP ENDP


; 定义一个子程序DISPLAYTIME，计算得到最近一次计数的结果
DISPLAYTIME PROC
	; 入栈，保护原先内容
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	LAHF   ; 保存原来的标志位
	MOV DH, AH
	
	; 对每位进行STOPBUFF-STARTBUFF得到最近一次计数结果，需要对结果进行修正，AND AX, AX用于重置标志位
	MOV AL, STOPBUFF
	MOV DL, STARTBUFF
	SUB AL, DL
	AND AX, AX
	DAS
	MOV BUF, AL
	MOV AL, STOPBUFF+1
	MOV DL, STARTBUFF+1
	SUB AL, DL
	AND AX, AX
	DAS
	MOV BUF+1, AL
	MOV AL, STOPBUFF+2
	MOV DL, STARTBUFF+2
	SUB AL, DL
	AND AX, AX
	DAS
	MOV BUF+2, AL
	MOV AL, STOPBUFF+3
	MOV DL, STARTBUFF+3
	SUB AL, DL
	AND AX, AX
	DAS
	MOV BUF+3, AL
	MOV AL, STOPBUFF+4
	MOV DL, STARTBUFF+4
	SUB AL, DL
	AND AX, AX
	DAS
	MOV BUF+4, AL
	MOV AL, STOPBUFF+5
	MOV DL, STARTBUFF+5
	SUB AL, DL
	AND AX, AX
	DAS
	MOV BUF+5, AL
	
	
	; 测试用，正式使用应注释掉
	;MOV AL, STOPBUFF
	;MOV AH, STOPBUFF+1
	;MOV BL, STOPBUFF+2
	;MOV BH, STOPBUFF+3
	;MOV CL, STOPBUFF+4
	;MOV CH, STOPBUFF+5
	
	MOV AH, DH
	SAHF   ; 恢复原来的标志位

	; 出栈，恢复原来的内容
	POP AX
	POP BX
	POP CX
	POP DX
	RET
DISPLAYTIME ENDP


; 定义一个子程序INTB，用来处理键盘中断
INTB PROC FAR
    PUSH AX
    PUSH BX
    PUSH CX
    MOV SI, 6
    MOV AL, 20H
    OUT 20H, AL
    POP CX
    POP BX
    POP AX
    IRET
INTB ENDP


CODE ENDS
END START
