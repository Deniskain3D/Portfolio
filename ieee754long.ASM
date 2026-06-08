
;Universal Decoder IEEE754 для <TYPE> Float (single precission) UINT32 (without sign format)
;Beta 0.15 DEMO

real4 dd 1.1
;===========================================================================================
;	       0	      0011 1111      (1)     001 0101 1100 0010 1000 1111	  1-st symbol between mantissa and exponent is hide and permanent equal 1 
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

bt eax, 31	
jnc @f
mov [minus],1
@@:

mov [pointer], 1


shr eax, 23
mov [probe], al 
sub eax, 7fh
jnc @f
neg eax
@@:
mov [expo], eax 

mov [step],23
sub [step], eax 
cmp byte[step],98h
jne @f
jmp .printer
;mov [step],23
;mov [expo],0	  
@@:



;===========================================================================================
mov edx, [real4]  
mov ecx, 23

.mantis:
dec ecx
bt dx, 00
jnc @f
bts ebx, 0	     
@@:
shr edx,1
rol ebx,1
cmp ecx, 0
jne .mantis
shr ebx,1


mov [revbx], ebx

mov ecx, [expo]
.if ecx > 0
.trimbx:
shr ebx,1
loop .trimbx
.endif

.if [probe] <> 7eh		       
xor eax, eax			       
mov ecx, [step] 		       
.zerocount:
bt ebx,0
jc .tod
inc [tmp]
shr ebx, 1
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
;===========================================================================================

mov edx, 24
mov ebx, [revbx]
mov ecx, [expo]
.cosolide:	   
mov [countst], ecx
.if cl = 81h
mov [countst],0
.endif

.if edx = 24
.if cl <> 81h
mov [razriad+24*4],1
.endif
.endif

.if ecx = 0
dec [pointer]	    
.endif

.if edx <> 24
bt bx, 00
jnc @f
mov [razriad+edx*4],1
@@:
shr ebx, 1	       
.endif

.solide:		
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
mul [razriad+ebx*4]	
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
dec [countst]		
.endif

cmp [countst],0
jne .solide

.if edx <> 24		
   add [razriad+24*4],eax 
.endif

dec edx

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
cmp [revbx],0	
je .printer

.render:

mov ecx, [step] 
mov ebx, [real4]
mov eax, [expo] 

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
add [akb], eax	
.nakopla:
loop .msumm


mov ecx, [step]
mov eax, 1
xor edx, edx
mov [initst],2

.exponent:
mul [initst]	
loop .exponent

mov ecx, 7			;precission not over 8 sym after point! (for 23 bit mantiss)
mov [step], eax
mov [razriad+23*4],00000000h		;init for float


mov eax, 10
mul [akb]
xor edx, edx

.repeate:	

.if eax <> 0
div [step]	
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
	lea eax, [razriad+24*4] 	
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
	lea eax, [razriad+23*4]
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
pointer  dd (00000000h),0
countst  dd (00000000h),0
expo	 dd (00000000h),0
step dd  (00000000h),0
akb  dd  (00000000h),0
stp  dd  (00000000h),0
savbx dd (00000000h),0
revbx dd (00000000h),0
savdx dd (00000000h),0
razriad  dd  24 dup (00000000h),0
