       
section '.text' code readable executable

  start:
        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,100,0,DialogProc,0 
  exit:
        invoke  ExitProcess,0

proc DialogProc hwnddlg,msg,wparam,lparam
        push    ebx esi edi
        cmp     [msg],WM_COMMAND
        je      .wmcommand
        cmp     [msg],WM_CLOSE
        je      .wmclose
        xor     eax,eax
        jmp     .finish

  .wmcommand:

cmp  byte[ebp+10h], ID_TYPEA
jne @f
mov dword [ids],65h
@@:
cmp  byte[ebp+10h], ID_TYPEB
jne @f
mov dword [ids],66h
@@:


cmp  [wparam],BN_CLICKED + ID_D
        je      .copyD
cmp  [wparam],BN_CLICKED shl 16 + ID_C
        je      .copyC
cmp  [wparam],BN_CLICKED shl 16 + ID_B
        je      .copyB
cmp  [wparam],BN_CLICKED shl 16 + ID_A
        je      .copyA

        cmp     [wparam],BN_CLICKED shl 16 + IDCANCEL
        je      .wmclose
        cmp     [wparam],BN_CLICKED shl 16 + IDOK
        jne     .processed

           invoke  GetDlgItemText,[hwnddlg],ID_TYPEA, typea, 10   
           cmp dword[typea], 0x00000000
           je   .processed
           invoke  GetDlgItemText,[hwnddlg],ID_TYPEB, typeb, 10   
           cmp dword[typeb], 0x00000000
           je  .processed
           invoke  GetDlgItemText,[hwnddlg],ID_RESULT,result,20   

     mov     [style],MB_OK
        invoke  IsDlgButtonChecked,[hwnddlg],ID_ADD
        cmp     eax,BST_CHECKED
        je      .add_process
        invoke  IsDlgButtonChecked,[hwnddlg],ID_SUB
        cmp     eax,BST_CHECKED
        je      .sub_process
        invoke  IsDlgButtonChecked,[hwnddlg],ID_MUL
        cmp     eax,BST_CHECKED
        je      .mul_process
        invoke  IsDlgButtonChecked,[hwnddlg],ID_TOPMOST
        cmp     eax,BST_CHECKED
        je      .mod_process
        invoke  IsDlgButtonChecked,[hwnddlg],ID_DIV
        cmp     eax,BST_CHECKED
        je      .div_process
        jmp     .topmost_ok
.add_process:
   push eax ebx ecx edx edi esi
mov dword [operat], 00000000h
mov dword [operat], resaddf
mov dword [wozflag],00000000h
mov byte[minusa],0
mov byte[minusb],0
mov [minus],0
jmp .checkin
.wozratadd:

        cmp [minusa],01h
        jne @f
        neg eax
      @@:
        cmp [minusb],01h
        jne .norm
        neg ebx
        add eax, ebx
         bt eax,31
         jnc @f
         mov [minus],01h
         neg eax
     @@:
cmp [minusa],01h
 jne .prodolj
mov [minus],01h
        jmp .prodolj
      .norm:
        add eax, ebx
       bt eax,31
       jnc .prodolj
       mov [minus],01h
       neg eax
      .prodolj:

         call WriteNum             
         mov [sizes], cl           
         call ClearR               
         call HexcProc             
    pop esi edi edx ecx ebx eax    
    jmp .topmost_ok

.sub_process:
   push eax ebx ecx edx edi esi
mov dword [operat], 00000000h
mov dword [operat], ressubf
mov dword [wozflag],000001h
mov byte[minusa],0
mov byte[minusb],0
mov [minus],0
jmp .checkin
.wozratsub:

         cmp [minusa],01h
         jne @f
         neg eax
       @@:
         cmp [minusb],01h
         jne @f
        neg ebx                              
      @@:                                    
                call negcheck
                sub eax, ebx                         
      .prodoljs:                             
         bt eax, 31                
         jnc @f
         mov [minus],01h           
         neg eax
        @@:

         call WriteNum             
         mov [sizes], cl           
         call ClearR               
         call HexcProc             
    pop esi edi edx ecx ebx eax    
    jmp .topmost_ok

.mul_process:
   push eax ebx ecx edx edi esi
mov dword [operat], 00000000h
mov dword [operat], resmulf
mov dword [wozflag],000002h
mov byte[minusa],0
mov byte[minusb],0
mov [minus],0
jmp .checkin
.wozratmul:

        mov esi, minusa   
        mov edi, minusb   
        cmpsb             
        je @f             
        mov [minus],01h   
      @@:                 
         mul ebx          
         call WriteNum             
         mov [sizes], cl           
         call ClearR               
         call HexcProc             
    pop esi edi edx ecx ebx eax    
    jmp .topmost_ok

.div_process:
   push eax ebx ecx edx edi esi
mov dword [operat], 00000000h
mov dword [operat], resdivf
mov dword [wozflag],00000003h
mov byte[minusa],0
mov byte[minusb],0
mov [minus],0
jmp .checkin
.wozratdiv:

      call negcheck
      div ebx                      
      push ebx                    
      push edx
        mov   ebx, 10             
        mov   edi, integrer       
.bycle:
        inc   ecx                 
        xor   edx, edx            
        div   ebx                 
        push  edx                 
        or    eax,eax             
      jne .bycle                  
       mov byte[sizes],cl
.ite:
        pop   eax                 
        add   al, 0x30            
    stosb                         
        cmp   ecx, 1              
loop .ite                         
      pop edx              
      pop ebx              
      call .create_float           
.finita:
   pop esi edi edx ecx ebx eax
   jmp .topmost_ok
.copyA:
.if dword [result]<>0
invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memA,10     
invoke  SetDlgItemText,[hwnddlg],ID_A,fula
call ClearR
jmp     DialogProc.topmost_ok                          
.endif
.if dword [memA]<>0
invoke  SetDlgItemText,[hwnddlg],dword [ids],memA      
jmp     DialogProc.topmost_ok
.endif
invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memA,10     
jmp     DialogProc.topmost_ok
.copyB:
.if dword [result]<>0
invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memB,10     
invoke  SetDlgItemText,[hwnddlg],ID_B,fulb
call ClearR
jmp     DialogProc.topmost_ok                          
.endif
.if dword [memB]<>0
invoke  SetDlgItemText,[hwnddlg],[ids],memB            
jmp     DialogProc.topmost_ok
.endif
invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memB,10     
jmp     DialogProc.topmost_ok
.copyC:
mov ecx, 31
.clA:
mov [memA+ecx-1],00000000h                 
loop .clA
invoke  SetDlgItemText,[hwnddlg],ID_A,empa
jmp     DialogProc.processed                             
.copyD:
mov ecx, 31
.clB:
mov [memB+ecx-1],00000000h                 
loop .clB
invoke  SetDlgItemText,[hwnddlg],ID_B,empb
jmp     DialogProc.processed                             

.checkin:
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
call ClearRF
mov dword [Afloat], 00000000h 
mov dword [Bfloat], 00000000h 
mov byte[multa],00h
mov byte[multb],00h
call ClearN                    
mov byte[flajok], 00h

stdcall CheckFloat, dword typea
mov [multa], ecx
 stdcall ConvAB, dword typea, dword minusa
 mov dword [typea], edx        
 mov edx, 0
stdcall CreateFloat, dword typea, dword multa, dword Afloat, dword minusa
mov eax, 0                     
mov al, [flajok]               
push eax                       
mov [flajok],0
stdcall CheckFloat, dword typeb
mov [multb], ecx
pop eax                        
add [flajok], al
cmp byte[flajok],0             
je .gens                       
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
.if [wozflag] = 03h                
       mov ecx, sizeof.typeb       
       mov esi, typeb              
       mov eax, [esi]              
.nulfloa:                          
       cmp al,2Dh                  
       jne @f
       inc esi
       lodsb
     @@:
       cmp al, 00h                 
       je .pustotaa                
       cmp al, 30h 
       jne .estcyfra               
       lodsb                       
       loop .nulfloa               
.pustotaa:                         
        jne @f
        call ClearR
        invoke  SetDlgItemText,[hwnddlg],ID_RESULT,NaN
        jmp DialogProc.processed 
.estcyfra:                         
.endif                             
mov ecx,0                          
mov eax,0                          

call ClearRF
 stdcall ConvAB, dword typeb, dword minusb       
 mov dword [typeb], edx            
 mov edx, 0
 mov eax, 0
call ClearRTM
call ClearR
call ClearD
call ClearF      
mov edx,0

stdcall CreateFloat, dword typea, dword multa, dword Afloat, dword minusa
stdcall CreateFloat, dword typeb, dword multb, dword Bfloat, dword minusb
mov eax, [operat] 

call flload   
stdcall dispf, dword [operat]     
mov esi, decstr
mov edi, result                   

        .if [minus]<>0            
        mov byte [edi], '-'       
        add edi, 1                
        .endif
mov ecx, 22                       
rep movsb
pop esi edi edx ecx ebx eax       
jmp DialogProc.topmost_ok

.gens:
call ClearRTM
call ClearRF
call ClearN  
call ClearR
call ClearD
call ClearF  

        mov eax, dword[typea]
        push eax
        stdcall ConvAB, dword typeb, dword minusb
      
        xchg edx, ebx              
        xor edx, edx
        pop eax

cmp byte [wozflag],00h
je .wozratadd
cmp byte [wozflag],01h
je .wozratsub
cmp byte [wozflag],02h
je .wozratmul
        test    ebx, ebx            
        jnz @f
        call ClearR
        invoke  SetDlgItemText,[hwnddlg],ID_RESULT,NaN
        jmp DialogProc.processed 
@@:
cmp byte [wozflag],03h
je .wozratdiv
.create_float:
        call ClearF
        mov ecx, 0
     .fl:
        imul eax, edx, 10         
        or eax, eax               
       je .fle                    
        xor edx, edx              
        div ebx                   
 pushad
        mov   ebx, 10             
        lea   edi, [float+ecx]    
        xor   ecx, ecx
.cycle:
        inc   ecx                 
        xor   edx, edx            
        div   ebx                 
        push  edx                 
        or    eax,eax             
      jne .cycle                  
        mov [tmpd], cl            
.iter:  pop   eax                 
        add   al, 0x30            
    stosb                         
        cmp   ecx, 1              
      je @f                       
      dec ecx
      cmp   ecx, 0                
      jnz   .iter
     @@:
 popad
        xor eax,eax               
        inc ecx                   
        cmp ecx, 22               
        je .fle
        jmp .fl
      .fle:
        mov eax, dword[integrer]
        call WriteNum             
        mov [sizes], cl           

        call ClearRTM
        call ClearR               
        call HexcProc 

        mov esi, float
       @@:                        
        movsb
        mov eax, [esi]
        or eax, eax
        je @f
        jmp @b
       @@:

    jmp .finita

DialogProc.mod_process:
   push eax ebx ecx edx edi esi
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
        call ClearRTM
        call ClearN                

        stdcall ConvAB, dword typea, dword minusa
        xchg edx, eax
        push eax
        stdcall ConvAB, dword typeb, dword minusb
        xchg edx, ebx
        pop eax

        div ebx
        add dl, 30h
        call ClearR
        mov [result], edx
        pop esi edi edx ecx ebx eax   
 jmp DialogProc.topmost_ok

  DialogProc.topmost_ok:                                     
        invoke SetDlgItemText, [hwnddlg], ID_RESULT, result  
        
        jmp     DialogProc.processed
  DialogProc.wmclose:
        invoke  EndDialog,[hwnddlg],0
  DialogProc.processed:
        mov     eax,1
  DialogProc.finish:
        pop     edi esi ebx
        ret
endp
HexcProc:     
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
call ClearD
call ClearRTM
call ClearR

or dword[number],00000000h 
je .nulll
   finit
   fild qword[number]     

call ClearN               
   frndint
   fbstp tword[decstr]    
   ffree st               
   ffree st1              
   mov esi,dword decstr
   mov edi,dword number   

.bcdd:
   cmp dword[esi],0     
   jne @f               
   cmp dword[esi+4],0   
   jne @f               
   cmp dword[esi+8],0   
   je .comlete
  @@:
   inc ecx
   cld
   lodsb
   mov ah,al
   shr ah,4
   shl al,4
   shr al,4
   mov bx, 3030h
   or ax, bx
   stosw
   jmp .bcdd
  .comlete:

  mov esi, number       
  mov edi, tmpsult      
  add ecx, ecx          
  mov byte[sizes],cl    
  dec ecx               
  add edi, ecx          

  inc ecx               

 .iout:
  mov al, byte[esi]
  inc esi
  mov [edi],al
  dec edi               
  loop .iout

mov cl,[sizes]
mov esi, tmpsult
mov edi, result          
cmp byte[tmpsult],30h
jne @f
inc esi                         
dec ecx
@@:
.if [minus]<>0                  
        mov byte [edi], '-'     
        mov byte[minus],0
        inc edi                 
  .endif
.if dword[integrer]<>0         
mov ecx,0

      @@:
        cmp dword[integrer+ecx],0        
        jne .oper
        cmp dword[integrer+ecx+4],0      
        je @f
      .oper:
         mov eax, dword[integrer+ecx]
          
          mov [edi],eax
          inc ecx
          inc edi
         jmp @b
      @@:
        mov byte [edi], '.'
        add edi, 1

     call ClearINT
     ret          
  .endif


.form:
lodsb
stosb
loop .form         
ret
.nulll:

mov byte[result], 30h
ret
mdwordh2dec:
proc ConvAB typeab, mini             

xor eax, eax                    
        mov ecx, 0
        mov byte [tmp],00h
        mov esi, [typeab]
      .chk:
        lodsb
         cmp al,2Dh            
         je .flag
         sub al, 30h
         mov [tmp+ecx], al     

         jmp .prom
     .flag:
        mov eax,[mini]                   
        mov dword[eax],00000001h         

     .prom:
        or [esi], byte 00h
        je .nxt
        cmp byte [esi-1],2Dh
        je .chk
        inc ecx
        jmp .chk
      .nxt:
        mov [multipl], 10
        lea esi, [tmp+ecx]
        xor eax, eax
        mov ah, cl
        inc ah
        mov ecx, 1
        std
    .llop:
        or ah, 0
        je .cor
        lodsb
        mov byte [esi+1], 00h     
        mov bl, al
        imul ebx,ecx
        imul ecx, [multipl]
        add edx, ebx
        xor ebx, ebx
        dec ah
        jmp .llop
     .cor:
        cld
        mov eax,0
        mov ecx,0
      ret
     endp

proc CheckFloat typeab
   mov esi, [typeab]      
   mov edi, [typeab]      
   mov ecx,0              
   mov [tmp], 0           
.check:
   lodsb
   .if al <> '.'          
        stosb
        .endif
   .if al='.'
                mov [flajok],1               
                mov dword [tmp], ecx         
                sub cl, 1                    

        .endif
    inc ecx            
    or eax, 0
    jne .check
    sub cl, 1  
    
.if byte [flajok]=00h
         mov ecx, 00h  
         mov [tmp], cl 
        .endif
.if byte [flajok]=01h
         sub cl, byte[tmp] 
        .endif
    ret
endp

fpuinit:
FINIT
    ffree st0              
    ffree st1              
    mov word[cw],0000h
    mov word[cws],0000h
fstcw word [cws]
fstcw word [cw]
or word [cw], 0000001100000000b   
fldcw word [cw]
ret

proc CreateFloat typeab, multab, abfloat, minusab
call fpuinit
mov ecx,0
mov ecx, [multab]        
mov ecx, [ecx]
mov eax, [typeab]
FILD dword [eax]         
@@:
or ecx, 0
je @f
FIDIV dword  [delitel]   

loop @b
@@:
mov eax, [abfloat]
mov ebx, [minusab]
.if dword [ebx]=01h      
FCHS               
.endif             
FST dword   [eax]        
    ffree st                   
    ffree st1                  
fldcw word  [cws]        
mov eax, 0
mov ebx, 0
    ret
endp

flload:

call fpuinit
FLD dword   [Bfloat]     
FLD dword   [Afloat]     
mov eax, [operat]

.if eax = dword resaddf
FADD ST, ST1             
.endif
.if eax = dword ressubf
FSUB ST, ST1
.endif
.if eax = dword resmulf
FMUL ST, ST1
.endif
.if eax = dword resdivf
FDIV ST, ST1
.endif

FST dword [eax]          
    ffree st             
    ffree st1            
fldcw word [cws]         
mov eax, 0
ret
negcheck:
                mov esi, minusa
                mov edi, minusb
                cmpsb
                jne @f
                mov [minus],01h
                or [minusa], 0
                jnz @f
                mov [minus],0
       @@:
ret
WriteNum:   
        mov ecx, 0                 
        mov edi, number            
       @@:
        or eax,eax                 
        je @f
        stosb                      
        shr eax, 8                 
        inc ecx                    
        jmp @b
       @@:
        xchg edx,eax
       @@:
        or eax,eax                 
        je @f
        stosb                      
        shr eax, 8                 
        inc ecx                    
        jmp @b
       @@:
ret
proc dispf resf                 
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
finit
    fstcw control
    mov ax, control
    mov ah, 00001100b           
    mov temp, ax
    fldcw temp                  
mov eax,0
mov eax, [resf]
    fld dword [eax]             
    fxam                        
    fstsw ax                    
    sahf
    jnc @f                      
    fchs                        
    mov [minus], 1              
  @@:
    mov edi, decstr
    call .dbltodec
        ret
endp

.dbltodec:                      
   xor eax, eax
   xor ebx, ebx      
   xor ecx, ecx      
   xor edx, edx      
push ebx ebx ebx     
pop  ebx ebx ebx     
    push ebp
    mov ebp, esp
    sub esp, 12
    fst integer
    frndint                     
    fld integer
    mov dword [ebp-12], 00000000h     
    mov dword [ebp-8],  00000000h
    fxch
    fsub st1, st0               
    call .bcdtodec
    fabs                        
    mov byte [edi], '.'         
    add edi, 1
    mov ten, 10
    fild ten
    fxch
.get_fractional:
    fmul st0, st1               
    fist word temp              
    fisub word temp             
    mov al, byte temp           
    or al, 0x30                 
    mov byte [edi], al          
    add edi, 1                  
    fxam                        
    fstsw ax                    
    sahf                        
    jnz .get_fractional         
    mov byte [edi], 0           
    ffree st                    
    ffree st1                   
    leave
    ret                         
.bcdtodec:                      
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
    push ebp
    mov ebp, esp
    sub esp, 10                 
      pop eax eax
      xor eax, eax
      push eax eax
    fbstp [ebp-10]              
    mov ecx, 10                 
    lea esi, [ebp - 1]          
    xor bl, bl                  
     btr word [ebp-2], 15        
    jnc .loo                    
    mov byte [edi], '-'         
    add edi, 1
    .loo:
        mov al, byte [esi]
        mov ah, al
        shr ah, 4               
        or bl, ah               
        jz .uvasia
        or ah, 30h              
        mov [edi], ah
        add edi, 1
        .uvasia:
        and al, 0Fh             
        or bl, al               
        jz .vasia
        or al, 30h              
        mov [edi], al
        add edi, 1
        .vasia:
        sub esi, 1
        loop .loo

    test bl, bl                 
    jnz .R1                     
    mov byte [edi], '0'
    add edi, 1

    .R1:
    mov byte [edi], 0           
    leave
    ret                         
ClearR:                            
        push edi
        xor eax, eax
        mov edi, result
        mov ecx, sizeof.result /4  
        rep stosd                  
        pop edi
ret

ClearN:                            
        push edi
        xor eax, eax
        mov edi, number
        mov ecx, sizeof.number     
        rep stosb                  
        pop edi
ret

ClearF:                            
        push edi
        xor eax, eax
        mov edi, float
        mov ecx, sizeof.float      
        rep stosb                  
        pop edi
ret

ClearD:                            
        push edi
        xor eax, eax
        mov edi, decstr
        mov ecx, sizeof.decstr     
        rep stosb                  
        pop edi
ret

ClearRF:                           

        push edi
        xor eax, eax
        mov edi, resultf
        mov ecx, sizeof.resultf    
        rep stosb                  
        pop edi
ret

ClearRTM:                           
        push edi
        xor eax, eax
        mov edi, tmpsult
        mov ecx, sizeof.tmpsult /4 
        rep stosd                  
        pop edi
ret

ClearINT:                           
        push edi
        xor eax, eax
        mov edi, integrer
        mov ecx, sizeof.integrer 
        rep stosb                  
        pop edi
ret
section '.data' data readable writeable
 copyr  db 'Copyright 2025 by Denis AKA Quriositer [c]',0
 cont   db 'For comercial use contact me at Telegram @Quriositer to buy this product legally',0

