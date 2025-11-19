
;Universal Decoder IEEE754 для <TYPE> Float (одинарная точность) UINT32 (беззнаковый формат)
;Beta 0.15 DEMO
format PE console
entry start
include 'win32ax.inc'
section '.data' data readable writable
real4 dd 1.1
;===========================================================================================
;	       0	      0011 1111      (1)     001 0101 1100 0010 1000 1111	    1-й разряд между мантисой и порядком всегда скрыт и равен единице
;	       ^sign bit  Exponent^8bit   virt^ bit	  ^^^23 mantiss bit
initst dd (1),0
;formatStr db	'%d',0
;formatP db    '.%d',13,10,0
section '.text' code readable executable
start:
xor eax, eax
xor ebx, ebx
xor ecx, ecx
xor edx, edx

mov eax, [real4]

bt eax, 31	;анализируем наличие знака минус в закодированом числе
jnc @f
mov [minus],1
@@:

mov [pointer], 1
;1. Вычислим степень двойки скрытого разряда (который равен единице в нормализованом варианте)

shr eax, 23
mov [probe], al      ;Экспонента до вычета для анализа минусовой области BIAS экспоненты
sub eax, 7fh
jnc @f
neg eax
@@:
mov [expo], eax      ;Экспонента после вычета константы

mov [step],23
sub [step], eax      ;вычисляем степень двойки для деления мантиссы	 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<,
cmp byte[step],98h   ;это бы надо будет убрать и переписать системно в минусовой части
jne @f
jmp .printer
;mov [step],23
;mov [expo],0	      ;и это бы надо будет убрать и переписать системно в минусовой части
@@:



;===========================================================================================
mov edx, [real4]       ;загрузим float для создания битовой карты ниже
mov ecx, 23

.mantis:
dec ecx
bt dx, 00
jnc @f
bts ebx, 0	     ;если бит в al есть копируем его в ebx
@@:
shr edx,1
rol ebx,1
cmp ecx, 0
jne .mantis
shr ebx,1


;--------------------------------------------------------- ^^^ МАСКА КОРРЕКТНАЯ ^^^  ------
;Теперь имеем в ecx степень двойки (bias)
;	имеем в ebx перевернутую мантиссу 23 бит
mov [revbx], ebx
;---------------------------------- Подсчет нулевых разрядов ------------------------------
mov ecx, [expo]
.if ecx > 0
.trimbx:
shr ebx,1
loop .trimbx
.endif

.if [probe] <> 7eh		       ; \
xor eax, eax			       ; Раздел Неправильный  !!!!!!!!
mov ecx, [step] 		       ; /
.zerocount:
bt ebx,0
jc .tod
inc [tmp]
shr ebx, 1			       ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
loop .zerocount
.tod:


.if [tmp] > 3
mov al, [tmp]
mov ebx, 3
xor edx, edx
div  ebx
mov [getzero], al
.endif
.endif
;===========================================================================================	ДОСЮДА ВСЕ ПРАВИЛЬНО УЖЕ НЕ ТРОГАТЬ

;Проход  для спрятаного первого разряда:
		       ;(чистим edx перед умножением и делением!)
mov edx, 24	       ;23 счетчик разрядов + 1 с учетом скрытого разряда
mov ebx, [revbx]
mov ecx, [expo]      ;BIAS exponent multipler
.cosolide:	       ; ЦИКЛ СДВИГА НА РАЗРЯД
mov [countst], ecx
.if cl = 81h
mov [countst],0
.endif

.if edx = 24
.if cl <> 81h
mov [razriad+24*4],1   ; Инициализируем скрытый разряд Единицей
.endif
.endif

.if ecx = 0
dec [pointer]	       ; Флаг перехода на основную мантиссу со скрытого разряда
.endif

.if edx <> 24
bt bx, 00
jnc @f
mov [razriad+edx*4],1
@@:
shr ebx, 1	       ; Спозиционируем битовую маску для передачи текущего бита в мультиплаер
.endif

.solide:		 ; ЦИКЛ ИТЕРАЦИЙ В РАЗРЯДЕ ПО СЧЕТЧИКУ [countst]
mov eax, 2
.if ecx = 0
dec eax
.endif

.if cl = 81h
mov eax,0
mov ecx,0
.endif

mov [savbx], ebx
mov [savdx], edx
xchg edx, ebx
xor edx, edx

.if [probe] >= 7fh
mul [razriad+ebx*4]	 ; Умножаем бит на значение BIAS из указателя  << тут оно в EBX!
.endif

;int 3
.if [probe] < 7fh
xchg eax, [razriad+ebx*4]
imul eax, 10
div [razriad+ebx*4]
.endif

xchg ebx, edx
mov ebx, [savbx]
mov edx, [savdx]

mov [razriad+edx*4],eax

.if [countst] > 0
dec [countst]		      ;убавляем счетчик умножения eax
.endif

cmp [countst],0
jne .solide

.if edx <> 24		       ; ^^Связано со значением EDX перед .cosolide!!!
   add [razriad+24*4],eax     ;добавляем к основной константе! (а не к текущему значению EDX)
.endif

dec edx
;----------------------- Прыжок на алгоритм работы с целой частью, пока степень больше единицы

.if cl > 0
dec ecx
jmp .cosolide
.endif

.if cl = 0
  .if [pointer] > 0
  jmp .cosolide
  .endif
.endif
;------------------------
cmp [revbx],0		     ;Проверка на ноль в мантиссе и вообще в целом
je .printer

.render:

mov ecx, [step] 	 ;23 - минус экспонента: кол-во оставшихся итераций для float
mov ebx, [real4];[revbx];отреверсеный ebx без мантиссы
mov eax, [expo] 	 ;экспонента

;.if eax <> 0
;.trim:
;shr ebx, 1
;dec eax
;cmp eax, 0
;jne .trim
;.endif

mov eax, 1
.msumm:
mul [initst]
mov [initst],2
bt  ebx, 0
shr ebx,1
jnc .nakopla
add [akb], eax	  ;накопляем результат мантиссы для деления на [step] (степень двойки мантиссы за вычетом экспоненты)
.nakopla:
loop .msumm


;-----------------------------------Подпрограмма вычисления float части ---------------------
mov ecx, [step]
mov eax, 1
xor edx, edx
mov [initst],2

.exponent:
mul [initst]			;two constant
loop .exponent

mov ecx, 7			;точность не более 8! (для 23 бит)
mov [step], eax
mov [razriad+23*4],00000000h		;init for float


mov eax, 10
mul [akb]
xor edx, edx

.repeate:			;Глотает первые нули во флоат части !

.if eax <> 0
div [step]			;вычисляем float часть
add [razriad+23*4],eax
.endif

.if edx <> 0
mov eax, 10
mov ebx, edx
xor edx, edx
mul [razriad+23*4]
mov [razriad+23*4], eax
mov eax, ebx
xor edx, edx
mov ebx, 10
mul ebx
.endif
loop  .repeate




.printer:
.if [probe] < 7fh
mov eax, [razriad+24*4]
add  eax, [razriad+23*4]
mov  [razriad+23*4], eax
mov  [razriad+24*4],0
.endif

xor eax, eax
lahf
pusha
	;mov eax, [razriad+24*4]
	lea eax, [razriad+24*4] 	     ; ^^Связано со значением EDX перед .cosolide!!!
	mov [stp], esp
	mov ebp, esp
	push eax
	;push formatStr
	cinvoke printf, <'%d.'>, dword[eax]
	mov esp, [stp]
	mov ebp, esp
popa
pusha
.if [getzero] > 0
mov cl, [getzero]
.zeros:
pusha
	mov eax, 0
	mov [stp], esp
	mov ebp, esp
	cinvoke printf, <'*'>
	mov esp, [stp]
	mov ebp, esp
popa
loop .zeros
.endif
popa
pusha
	lea eax, [razriad+23*4] 	     ; ^^Связано со значением EDX перед .cosolide - 1 !!!
	mov [stp], esp
	mov ebp, esp
	;push eax
	;push formatP
	cinvoke printf, <'%d',13,10>, dword[eax]
	mov esp, [stp]
	mov ebp, esp
popa
jmp .ext
;----------------------------------------------------------------------------------------------
;.nextit:
;cmp edx, 0
;jnz .solide
.ext:
		cinvoke system,<"pause">
		cinvoke exit,0
;ret
;-=XCoded by DEN=- 2021 (Telegram: @Quriositer)
section '.bss' data readable writable
probe db (0),0
minus db (0),0
getzero db (0),0
tmp db (0),0
pointer  dd (00000000h),0		    ;Указатель на разряд
countst  dd (00000000h),0
expo	 dd (00000000h),0
step dd  (00000000h),0
akb  dd  (00000000h),0
stp  dd  (00000000h),0
savbx dd (00000000h),0
revbx dd (00000000h),0
savdx dd (00000000h),0
razriad  dd  24 dup (00000000h),0

section '.idata' import data readable ;сюда будем импортировать библиотеки и функции win32api
	library msvcrt, 	'msvcrt.dll'	 ;Псевдоним Библиотека функций

	import	msvcrt,\
		printf, 	'printf',\	 ;Псевдоним функция
		system, 	'system',\
		exit,		'exit';,\
	       ; free,		 'free',\
	       ; malloc,	 'malloc',\
	       ; memset,	 'memset'\
	       ; scanf, 	 'scanf',\	  ;Псевдоним функция
	       ; getch, 	 '_getch'	  ;Псевдоним функция