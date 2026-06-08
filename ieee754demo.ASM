;Universal Decoder IEEE754 for <TYPE> Float (single precission) UINT32 (without sign format)
;Beta 0.16 DEMO
real4 dd 0.965436
initst dd (1),0
two dd (2),0
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
.if [probe] < 7fh
mov [corector], 4
sub [corector], al
.endif
cmp byte[step],98h 
jne @f
jmp .printer
@@:
mov edx, [real4]    
mov ecx, 23
.mantis:
dec ecx
bt dx, 00
jnc @f
inc [bcount]        
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
mov ecx, [step]
mov eax, [expo]
.if eax <> 0
.trim:
shr ebx, 1
dec eax
cmp eax, 0
jne .trim
.endif
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
mov eax, [tmp]
sub al,1
mov ebx, 3
xor edx, edx
div  ebx
mov [getzero], al
.endif
.if [tmp] <= 3
mov eax, [tmp]
sub eax, [tmp]
mov [getzero], al
.endif
	       
mov edx, 24	       
mov ebx, [revbx]
mov ecx, [expo]
mov [micoun], cl
.cosolide:
mov [countst], ecx
.if [probe] < 7fh
mov ecx, 1
.endif
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
.if edx <> 24
  .if [probe] < 7fh
  bt bx, 00
  jc @f
  shr ebx, 1	       
  jmp .skipp
  @@:
  .endif
.endif
shr ebx, 1
.endif
mov [mres], 1
.solide:                		 
mov [two], 2
mov eax, 2
.if ecx = 0
dec eax
dec [two]
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
mov [razriad+ebx*4],eax
.endif
.if [probe] < 7fh
mov eax, [mres]
mov [tmp],10
mul [tmp]
div [two]
mov [mres],eax
mov [razriad+ebx*4], eax
.endif
mov ebx, [savbx]
mov edx, [savdx]
.if [countst] > 0
dec [countst]		      
.endif
cmp [countst],0
jne .solide
.if edx <> 24             
  .if [probe] >= 7fh
     add [razriad+24*4],eax 
  .endif
.endif
.skipp:
dec edx
.if cl > 0
dec ecx
.if [probe] >= 7fh
jmp .cosolide
.endif
.endif
.if [probe] >= 7fh
 .if cl = 0
   .if [pointer] > 0
    jmp .cosolide
  .endif
 .endif
.endif
cmp [revbx],0    
jne @f
mov [getzero], 0
jmp .printer
@@:
.render:
mov [two], 2
mov ecx, [step] 	 
.if [probe] < 7fh
.if [razriad+24*4] <> 0
 mov eax, [razriad+24*4]
 mov [tmp], 10000
 mul [tmp]
 mov [razriad+24*4], eax
.corr:
mov [tmp],10
mul [tmp]
mov [razriad+24*4], eax
dec [corector]
cmp [corector], 0
jne .corr
 .endif
mov eax, [expo]
add ecx, eax
.endif
mov ebx, [real4]
mov eax, [expo]
mov eax, 1
.if [probe] < 7fh
mov [initst],2
.endif
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
.if [probe] < 7fh
add ecx, [expo]
.endif
mov eax, 1
xor edx, edx
mov [initst],2
.if [probe] < 7fh
push ecx
mov ecx, [expo]
inc ecx
.lexpo:
mul [initst]
loop .lexpo
pop ecx
.endif
.exponent:
mul [initst]
loop .exponent
mov [razriad+23*4],00000000h 		
mov ecx, 7 			
mov [step], eax
mov eax, 10
mul [akb]
xor edx, edx
.repeate:			
.if eax <> 0
xor edx, edx
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
xor eax, eax
.if [probe] < 7fh
mov  eax, [razriad+24*4]
add  [razriad+23*4], eax
mov  [razriad+24*4],0
.endif
xor eax, eax
pusha
        lea eax, [razriad+24*4] 	     
        mov [stp], esp
        mov ebp, esp
        push eax
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
        cinvoke printf, <'%d',13,10>, dword[eax]
        mov esp, [stp]
        mov ebp, esp
popa
jmp .ext
.ext:
                cinvoke system,<"pause">
                cinvoke exit,0
;-=XCoded by DEN=- 2021 (Telegram: @Quriositer)
section '.bss' data readable writable
micoun db (0),0
probe db (0),0
minus db (0),0
getzero db (0),0
bcount db (0),0
corector db (0),0
tmp dd (0),0
mres dd (0),0
pointer  dd (00000000h),0
countst  dd (00000000h),0
expo     dd (00000000h),0
step dd  (00000000h),0
akb  dd  (00000000h),0
stp  dd  (00000000h),0
savbx dd (00000000h),0
revbx dd (00000000h),0
savdx dd (00000000h),0
razriad  dd  24 dup (00000000h),0
