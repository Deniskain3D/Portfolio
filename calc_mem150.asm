format PE GUI 4.0
entry start
include 'win32ax.inc'

section '.data' data readable
control equ word [ebp-2]         ;
ten          equ word [ebp-4]    ; stack alias for fpufloat2ascii procedure
temp         equ [ebp-4]         ;
integer      equ qword [ebp-12]  ;
ID_TYPEA     = 101   ;field1
ID_TYPEB     = 102   ;field2
ID_RESULT    = 103   ;resultat field
ID_ADD       = 201   ;add checkbox
ID_SUB       = 202   ;sub checkbox
ID_MUL       = 203   ;mul checkbox
ID_DIV       = 204   ;div checkbox
ID_TOPMOST   = 301   ;div module checkbox
ID_A =401             ;memory A
ID_B =402             ;memory B
ID_C =403             ;memory C
ID_D =404             ;memory D
fixnop db 1,0         ;чтото нужно в дате чтобы секция не выпилилась компилятором
section '.text' code readable executable


;=============================================================================
  start:

        invoke  GetModuleHandle,0
        invoke  DialogBoxParam,eax,100,0,DialogProc,0 ;вызываю оснвную окно и порцедуру DialogProc  (ОСНОВНОЙ ЦИКЛ нашего окошка)
  exit:
        invoke  ExitProcess,0



;------------------------------------------- Проверка состояний переменной MSG  --------------------------------
proc DialogProc hwnddlg,msg,wparam,lparam
        push    ebx esi edi
        cmp     [msg],WM_COMMAND
        je      .wmcommand
        cmp     [msg],WM_CLOSE
        je      .wmclose
        xor     eax,eax
        jmp     .finish

  .wmcommand:
;---------------------------Focus for Memory Buttons---------------------------
;----------------------OnClick_GET_ID_For_TextFiels_Win32_Function--------------------
cmp  byte[ebp+10h], ID_TYPEA
jne @f
mov dword [ids],65h
@@:
cmp  byte[ebp+10h], ID_TYPEB
jne @f
mov dword [ids],66h
@@:
;------------------------------------------------------------------------------
;                             -= MEMORY BUTTONS =-
cmp  [wparam],BN_CLICKED + ID_D
        je      .copyD
cmp  [wparam],BN_CLICKED shl 16 + ID_C
        je      .copyC
cmp  [wparam],BN_CLICKED shl 16 + ID_B
        je      .copyB
cmp  [wparam],BN_CLICKED shl 16 + ID_A
        je      .copyA
;------------------------------------------------------------------------------
        cmp     [wparam],BN_CLICKED shl 16 + IDCANCEL
        je      .wmclose
        cmp     [wparam],BN_CLICKED shl 16 + IDOK
        jne     .processed
;------------------------------------------- эта часть выполняется после нажатия ок,забирает значения из полей вставляя их по ячейкам bss
           invoke  GetDlgItemText,[hwnddlg],ID_TYPEA, typea, 13   ;Функция проверяет что написано в поле и записывает это в переменную typea
           cmp dword[typea], 0x00000000
           je   .processed
           invoke  GetDlgItemText,[hwnddlg],ID_TYPEB, typeb, 13   ;31 lenght-int
           cmp dword[typeb], 0x00000000
           je  .processed
           invoke  GetDlgItemText,[hwnddlg],ID_RESULT,result,20   ;result field
;-----------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
        jmp     .topmost_ok

;------------------------------------------------------------------------------
;------------------------------------ калькулятор СЛОЖЕНИЕ --------------------
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

mov eax,dword[typea+8]
mov edx,dword[typea+4]
mov ebx,dword[typeb+8]              ;<<ЭТО НАДО ДОПИСЫВАТЬ
mov ecx,dword[typeb+4]
        cmp [minusa],01h            ;Проверяем HEX операнд A на наличие минуса
        jne @f                      ;Если нет переходим к операнду HEX B
        neg eax                     ;коли есть, превратим в минусовое, для операции
        .if edx<>0                  ;Если edx 0 то not делать нельзя иначе он превратит это в -1
        not edx                     ;edx превратим тоже
        .endif
      @@:
        cmp [minusb],01h             ;Проверяем HEX операнд B на наличие минуса
        jne @f                       ;Если нет то уже складываем
        neg ebx                      ;если есть превратим B в минус для операции
        .if ecx<>0                   ;Если ecx 0 то not делать нельзя иначе он превратит это в -1
        not ecx
        .endif
      @@:
;int3
                     ;-+-99999999999 10-11 знаков не работает
                     ;-+-10-11 теперь доходит с всеми 4 нормальными регистрами СЮДА . !
;------------------------------------------------
                 ;(СКЛАДЫВАЕМ ЧИСЛА Знаки добавлю потом по флагам)
        add eax, ebx                  ;тут же сложиваем
        ;xor ebx, ebx ;почистим т.к. возможно понадобится
        jz @f       ;Проверка на ложный CF который появляется при 0 результате
        adc edx, 0
        @@:
        add edx, ecx
        jz @f        ;Проверка на ложный CF который появляется при 0 результате
        jns @f       ;Если знак не менялся эта проверка не нужна, выходим
        not edx      ;Для негативного числа обратим в позитивное для пров на переполнение
        test edx,edx ;Проверяем есть ли cf-переполнение
        jnc .rch     ;Если переполнения нет прыгаем сразу на конвертацию обратно
        adc ebx, 0   ;Если есть расширяем аж до ebx
        not edx      ;приводим негатив в порядок
        not ebx      ;ebx тогда тоже будет негатив
        jmp @f
       .rch:
        not edx      ;вернем число в негатив
        @@:
                     ; ЗДЕСЬ При сложении больших положительных чисел взводится SF
                     ; Это надо как то решить
        test eax,eax
        jns .uint                    ;проверим на знак результата если плюс, к проверке переполнения
                                     ;ZF0 проверка не получился ли ноль, потому

        .if byte[minusa]=0         ;Проверка для больших чисел которые при сложении
        cmp byte[minusb],0         ;все же могут взводить SF  если посл. бит единица
        jz .uint
        .endif

        or eax, eax
        jz .zr                        ;что при нуле так же выставляется CF=1
        neg eax                       ;прим выставляется CF
        .if eax = -1
        adc edx,0
        .endif
      .zr:
        mov [minus],01h            ;просто укажем это для вывода '-'

        add edx,ecx
         jns .uint

        jz .zrd                       ;что при нуле так же выставляется CF=1 и будет
         .if edx<>0                   ;Если edx 0 то not делать нельзя иначе он превратит это в -1
        not edx                       ;прим выставляется CF
        .endif
        .if ebx = -1
        adc ebx,0
        .endif
      .zrd:
;------------------------------------------------
         xor ecx, ecx               ;почистим ФЛАГИ и регистр УЖЕ после входа в sign proc
         mov [minus],01h            ;просто укажем это для вывода '-'
         jmp  .prodolj
      ;///////////////////////////////////////////////////////////////////////////////////////////////


          ;bt eax, 31      ;проверим на переполнение примерно по последнему биту (ПЛОХАЯ проверка!)
          ;jnc @f
          ;adc edx,0                  ;даже инвертирует edx из минус -1 (ffffffff) в 0
       ;@@:                           ;prim. adc сбрасывает флагi

;Здесь ничего не надо проверять на переполнение потому что в случае переполнения SF поменяется
;и в этой ветке вообще ничего не будет!!!


       .uint:             ;это часть если имеем положительные числа
      ;///////////////////////////////////////////////////////////////////////////////////////////////
        cmp [minus],01h              ;Если попали сюда с минусом значит в EDX возможно был плюс
      jne @f                              ;тогда надо сделать перенос из EDX в EAX получив полож значение
        .if edx>0
        sbb edx, 0                   ;по идее так должно работать   <<<<<<<<<<<<<<<< надо проверять!
        .endif
      @@:

        xor ecx,ecx                  ;проверка если оба сложеных числа были минусовые
        add cl, byte[minusa]         ;такое тоже возможно так что дадим ему здесь минус обратно
        add cl, byte[minusb]
        cmp cl, 2
       jne @f
       mov [minus],01h
       test edx,edx
       jz .prodolj
  ;int3
       jns .prodolj                  ;Если есть флаг знака значит это минус! Инвертируем
       ;test ebx                     ;еще надо будет доделать эту проверку
       neg eax
       not edx
       jmp .prodolj

     @@:
        cmp [minusa],1    ;Если minusa был выставлен и B был плюсом но больше A то CF поднялся
        jnz .expand         ;не по переполнению а по карусели из минуса в плюс и переполнен быть не может
                          ;в принципе, проверяем это и в случае успеха направляем алгоритм в expand

        ;bt edx, 1                   ;проверим на переполнение примерно по последнему биту (ПЛОХАЯ проверка!)
        jc @f                        ;если переполнение было пропустим расширение
   .expand:
        xor ecx, ecx
        or edx, edx                  ;проверим есть ли что то в edx если есть пропускаем расширение
        jne @f
        cdq                          ;расширим ка до edx нулями если короткая положительная сумма
      @@:
         xor ecx, ecx
         jmp .prodolj                 ;и на печать

         ;adc edx,0                   ;попробуем перенести esli ne minus i cf=1

;----------------------------------  ;Проверка на переполнение минуса (тогда он уйдет в плюс и залезет сюда)

       .prodolj:                     ;cdq расширить по 31 биту dword->qword
                                     ;clc очиститть флаг переноса
                                     ;stc -уст. флаг переноса
                                     ;sbb выч. с заемом из edx
;------------------------------------------------------------------------------
         call WriteNum             ;Копируем результат из EAX в number слева направо
         mov [sizes], cl           ;скопируем кол-во байтов HEX результата, в [sizes]
         call ClearR               ;очистка [result]
         call HexcProc             ;
    pop esi edi edx ecx ebx eax    ;восстанавливаем в обратном порядке
    jmp .topmost_ok

;------------------------------------------------------------------------------
;---------------------------------- калькулятор ВЫЧИТАНИЕ ---------------------
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
;------------------------------------------------------------------------------

        cmp [minusa],01h
        jne @f
        neg eax
      @@:
        cmp [minusb],01h
        jne @f
        neg ebx                              ;cdq расширить по 31 биту dword->qword
      @@:                                    ;clc очиститть флаг переноса
		call negcheck
		sub eax, ebx                         ;stc -уст. флаг переноса
      .prodoljs:                             ;sbb выч. с заемом из edx
;------------------------------------------------------------------------------
         bt eax, 31                ;проверка на минус в целочисленном результате
         jnc @f
         mov [minus],01h           ;установим флаг отрицательного числа для обработки
         neg eax
        @@:
;------------------------------------------------------------------------------
         call WriteNum             ;Копируем результат из EAX в number слева направо
         mov [sizes], cl           ;скопируем кол-во байтов HEX результата, в [sizes]
         call ClearR               ;очистка [result]
         call HexcProc             ;преобразование hex обратно в ascii
    pop esi edi edx ecx ebx eax    ;восстанавливаем в обратном порядке
    jmp .topmost_ok

;--------------------------------------------------------------------------------
;---------------------------------- калькулятор УМНОЖЕНИЕ -----------------------
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
;--------------------------------------------------------------------------------
        mov esi, minusa   ;
        mov edi, minusb   ;
        cmpsb             ;
        je @f             ;        ;поскольку для умножения - * - будет плюс те je  а не jne
        mov [minus],01h   ;
      @@:                 ;
         ;call negcheck   ;        ;<< Буду переписывать в столбик :)
         mul ebx          ;
;------------------------------------------------------------------------------
;         bt eax, 31                ;проверка на минус в целочисленном результате
;         jnc @f
;         mov [minus],01h           ;установим флаг отрицательного числа для обработки
;         neg eax
;        @@:
;--------------------------------------------------------------------------------
         call WriteNum             ;Копируем результат из EAX в number слева направо

         mov [sizes], cl           ;скопируем кол-во байтов HEX результата, в [sizes]
         call ClearR               ;очистка [result]
         call HexcProc             ;преобразование hex обратно в ascii
    pop esi edi edx ecx ebx eax    ;восстанавливаем в обратном порядке
    jmp .topmost_ok

;--------------------------------------------------------------------------------
;---------------------------------- калькулятор ДЕЛЕНИЕ -------------------------
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
     push esi edi
        mov esi, minusa
        mov edi, minusb
        cmpsb
        je .divik
        mov [minus],01h
       .divik:
      pop edi esi
      div ebx                      ;Производим вычисления в привычном машине формате!++++++++++++++++++
      push ebx                    ;сохраним делитель
      push edx
;==================================================================================

;========================================================
;        mov   [number],1234567898 ;ложим какой то нумбер в ячейку
;        mov   eax, [number]       ;будем преобразовывать число из ячейки number
        mov   ebx, 10             ;это будет делитель 10
        mov   edi, integrer       ;установим адрес edi на integrer
.bycle:
        inc   ecx                 ;будем прибавлять итерацию к ecx в цикле для определения размера буффера
        xor   edx, edx            ;чистим edx
        div   ebx                 ;делим число [number] на 10 (делится уже в переведенном int формате! т.е [number]/10)
        push  edx                 ;кладем остаток в стек это уже разряды в формате INT в порядке от младших к старшим
        or    eax,eax             ;проверяем регистр на наличие информации отличной от нуля
      jne .bycle                  ;если в eax что то есть продолжаем цикл (увеличивая буффер ecx)
       mov byte[sizes],cl
.ite:
        pop   eax                 ;вынимаем из стека в eax получившиеся INT байты, в цикле определенном счетчиком ecx от старших к младшим
        add   al, 0x30            ;корректируем значение int для вывода в формате ascii
    stosb                         ;запишем значение из eax в integrer и сместимся на байт вперед (std/cld)
;        or   [integrer], edx     ;помещаем откорректированный результат в ячейку integrer переписывая только нулевые биты
        cmp   ecx, 1              ;если ecx 1 больше не крутим байты в ячейке ибо они пойдут на второй круг и
;      je .clear                  ;прыгаем в следущую подпрограмму
;        rol  [integrer], 8         ;освобождаем значение для следущего байта
loop .ite                         ;тут нам пригодится буффер ecx (будем доставать dword-ы из стека ecx раз)
;xor ebx,ebx                       ;.create_float хочет делитель
;=======================================================
      pop edx              ;восстановим делитель
      pop ebx              ;проверим на остаток

      call .create_float           ;формирование cpu-float и запись в result
.finita:

   pop esi edi edx ecx ebx eax
   jmp .topmost_ok

;====================================MEMORY BUTTONS===============================
.copyA:
.if dword [result]<>0
invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memA,13     ;копируем результат в memX при нажатии
invoke  SetDlgItemText,[hwnddlg],ID_A,fula
call ClearR
jmp     DialogProc.topmost_ok                          ;продолжаем цикл обработки текущих данных
.endif

.if dword [memA]<>0
invoke  SetDlgItemText,[hwnddlg],dword [ids],memA      ;[ids]вставляем данные ячейки в [ids] поле
jmp     DialogProc.topmost_ok
.endif

invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memA,13     ;когда память пустая можно ввести что то в result и взять оттуда
;call ClearR
jmp     DialogProc.topmost_ok
;----------------------------------------------------------------------------------------------------------
.copyB:
.if dword [result]<>0
invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memB,13     ;копируем результат в memX при нажатии
invoke  SetDlgItemText,[hwnddlg],ID_B,fulb
call ClearR
jmp     DialogProc.topmost_ok                          ;продолжаем цикл обработки текущих данных
.endif

.if dword [memB]<>0
invoke  SetDlgItemText,[hwnddlg],[ids],memB            ;[ids]вставляем данные ячейки в указанное в [ids] поле type
jmp     DialogProc.topmost_ok
.endif

invoke  GetDlgItemText,[hwnddlg],ID_RESULT,memB,13     ;когда память пустая можно ввести что то в result и взять оттуда
;call ClearR
jmp     DialogProc.topmost_ok
;-----------------------------------------------------------------------------------------------------------

.copyC:
mov ecx, 31
.clA:
mov [memA+ecx-1],00000000h                 ;testclear
loop .clA
invoke  SetDlgItemText,[hwnddlg],ID_A,empa
jmp     DialogProc.processed                             ;продолжаем цикл обработки текущих данных

.copyD:
mov ecx, 31
.clB:
mov [memB+ecx-1],00000000h                 ;testclear
loop .clB
invoke  SetDlgItemText,[hwnddlg],ID_B,empb
jmp     DialogProc.processed                             ;продолжаем цикл обработки текущих данных



;==================================================================================
.checkin:

   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
;----------------------------------------

call ClearRF
mov dword [Afloat], 00000000h ; ClearA
mov dword [Bfloat], 00000000h ; ClearB
mov byte[multa],00h
mov byte[multb],00h
call ClearN                    ;очистка [number]
mov byte[flajok], 00h

stdcall CheckFloat, dword typea
mov [multa], ecx

;--------------------------------------------------------------------------------------------------------------------------------
 stdcall ConvAB, dword typea, dword minusa
;int3
    mov dword [typea+8],  eax
   mov dword [typea+4], edx    ;кладем в 1-e сформированое число для операции
  mov dword [typea], ebx

 mov edx, 0
 mov eax, 0
 mov ebx, 0

stdcall CreateFloat, dword typea, dword multa, dword Afloat, dword minusa
mov eax, 0                     ;
mov al, [flajok]               ;сохраним значение флага для первого поля
push eax                       ;
;================================================================================================================================

mov [flajok],0
stdcall CheckFloat, dword typeb
mov [multb], ecx

pop eax                        ;вынем состояние флажка после проверки первого поля
add [flajok], al
cmp byte[flajok],0             ;посмотрим был ли флоат в хотябы одном из полей, если 0 то небыло
je .gens                       ;если флоатов вообще небыло, переходим к обычной процедуре
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx

;================================================================================================================================
;----------------------------------------- FLOAT РАЗДЕЛ если нашли float
.if [wozflag] = 03h                ;
       mov ecx, sizeof.typeb       ;
       mov esi, typeb              ;
       mov eax, [esi]              ;
.nulfloa:                          ;

       cmp al,2Dh                  ;проверим на минус ascii в выражении
       jne @f
       inc esi
       lodsb
     @@:
       cmp al, 00h                 ;
       je .pustotaa                ;
       cmp al, 30h ;'0'            ;проверка деления на ноль Float
       jne .estcyfra               ;
       lodsb                       ;
       loop .nulfloa               ;
.pustotaa:                         ;
        jne @f
        call ClearR
        invoke  SetDlgItemText,[hwnddlg],ID_RESULT,NaN
        jmp DialogProc.processed ;
.estcyfra:                         ;
.endif                             ;
mov ecx,0                          ;
mov eax,0                          ;
;-------------------------------------------

call ClearRF
 stdcall ConvAB, dword typeb, dword minusb       ;конвертируeт числа из dword char int string (31 32 33 34) в hex  (4D2)                                                              ;

    mov dword [typeb+8],  eax
   mov dword [typeb+4], edx        ;кладем 2-e сформированое число для операции
  mov dword [typeb], ebx
 mov edx, 0
 mov eax, 0
 mov ebx, 0

call ClearRTM
call ClearR
call ClearD
call ClearF      ;очистка resultf
;--
mov edx,0
mov edx,[operat] ;определяем действие "+-*/"
;mov dword[edx], 00000000h
;xor edx,edx
;--
stdcall CreateFloat, dword typea, dword multa, dword Afloat, dword minusa
stdcall CreateFloat, dword typeb, dword multb, dword Bfloat, dword minusb
mov eax, [operat]
;mov dword [eax], 00000000h
;xor eax, eax
call flload   ;загружаем floats в fpu и складываем результаты в [resXXXf](operat)

stdcall dispf, dword [operat] ;переводим результат float в ascii-bytes

;        mov esi, minusa
;        mov edi, minusb
;        cmpsb                 ;FLOAT РАЗДЕЛ
;        jne @f                ;//////////////////////////////////////////
;        mov [minus],01h       ;Здесь необходима более глубокая мысль!
;        or [minusa],0         ;поскольку для умножения - * - будет плюс те je  а не jne
;        jnz @f
;        mov [minus],0
;       @@:

mov esi, decstr
mov edi, result                   ;скопируем результат в result

        .if [minus]<>0            ;проверим на флаг минуса
        mov byte [edi], '-'       ;Yes: store a minus character in [result]
        add edi, 1                ;сместимся на позицию для записи самого числа
        .endif
mov ecx, 22                       ;ограничим точность 22 знаками
rep movsb
pop esi edi edx ecx ebx eax       ;восстанавливаем в обратном порядке
jmp DialogProc.topmost_ok

;-------------------------------------------------------------------------------------------

                        ; -= ЦЕЛОЧИСЛЕННЫЙ НЕ ТРОГАЕМ!!!=-

                            ;ЕСЛИ НЕ ПОПАЛИ ВО float

;--------------------------------- ЦЕЛОЧИСЛЕННЫЙ РАЗДЕЛ ------------------------------------
;---------------------------------
.gens:
call ClearRTM
call ClearRF
call ClearN  ;очистка [number] (это куда положится результат в hex или float после операции
call ClearR
call ClearD
call ClearF  ;очистка resultf

        ;mov eax, dword[edxeaxstore+8]                                                     ;test
        ;push eax
                                   ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        stdcall ConvAB, dword typeb, dword minusb

        ;mov dword [typeb], edx

;int3
    mov dword [typeb+8],  eax
   mov dword [typeb+4], edx        ;кладем в 2-e сформированое число для операции
  mov dword [typeb], ebx
 ;mov edx, 0
 mov eax, 0
 ;mov ebx, 0
 ;mov ebx, dword[edxeaxstore+8]                                                            ;test
        ;mov ebx, dword[typeb]      ;кладем в ebx 2-e сформированое число для операции
        ;pop eax

;=================================

cmp byte [wozflag],00h
je .wozratadd
cmp byte [wozflag],01h
je .wozratsub
cmp byte [wozflag],02h
je .wozratmul
        test    ebx, ebx            ;проверка деления на ноль целочисл.
        jnz @f
        call ClearR
        invoke  SetDlgItemText,[hwnddlg],ID_RESULT,NaN
        jmp DialogProc.processed ;
@@:
cmp byte [wozflag],03h
je .wozratdiv
;=====================================================================================
       ;^^^^; -= ЦЕЛОЧИСЛЕННЫЙ НЕ ТРОГАЕМ!!!=-


;                          THE END OF PROG

;================= FLOAT (CPU MODE) PROCEDURE заполняем [float] ascii ================

.create_float:

        call ClearF
        mov ecx, 0
     .fl:
        imul eax, edx, 10         ;умножаем остаток на 10 и записываем результат в eax
        or eax, eax               ;не ноль ли имеем в eax?
       je .fle                    ;если ничего уже нет значит флоат уже в ascii и помещен по адресу
        xor edx, edx              ;dx надо чистить чтобы не глючил div (ему нужен пустой регистр)
        div ebx                   ;делим умноженый остаток в eax на (---целое---) ДЕЛИТЕЛЬ!
 pushad
 ; ---------------------------------------

        mov   ebx, 10             ;это будет делитель 10
        lea   edi, [float+ecx]    ;установим адрес edi
        xor   ecx, ecx
.cycle:

        inc   ecx                 ;будем прибавлять итерацию к ecx в цикле для определения размера буффера
        xor   edx, edx            ;чистим edx перед делением, иначе будет unbehavior
        div   ebx                 ;делим число [number] на 10 (делится уже в переведенном int формате! т.е [number]/10)
        push  edx                 ;кладем остаток в стек это уже разряды в формате INT в порядке от младших к старшим
        or    eax,eax             ;проверяем регистр на наличие информации отличной от нуля
      jne .cycle                  ;если в eax что то есть продолжаем цикл (увеличивая буффер ecx)
        mov [tmpd], cl            ;сохраним кол-во целых int байтов-цифр
.iter:  pop   eax                 ;вынимаем из стека в eax получившиеся INT байты, в цикле определенном счетчиком ecx от старших к младшим
        add   al, 0x30            ;корректируем значение int для вывода в формате ascii
    stosb                         ;запишем значение из eax в result и сместимся на байт вперед (std/cld)
        cmp   ecx, 1              ;если ecx 1 больше не rep-aem stosb т.к. это значит что eax уже пустой
      je @f                       ;прыгаем в следущую подпрограмму
      dec ecx
      cmp   ecx, 0                ;тут нам пригодится буффер ecx (будем писать в edi [result] ecx раз)
      jnz   .iter
     @@:
; -----------------------------------------
 popad
        xor eax,eax               ;очистим для корректной проверки or наверьху
        inc ecx                   ;счетчик итераций полезная вещь!
        cmp ecx, 22               ;ограничим точность 5 знаками ++++++++++++++
        je .fle
        jmp .fl
      .fle:
;---------------------------------

        mov eax, dword[integrer]
        ;or eax,30h
;---------------------------------
        call WriteNum             ;Копируем результат из EAX в number слева направо
;---------------------------------
        mov [sizes], cl           ;скопируем кол-во байтов HEX результата, в [sizes] +++++++++++++++++
;---------------------------------
        call ClearRTM
        call ClearR               ;очистка [result]
;=================================
        call HexcProc ;формируем целое в ascii++++++++++++++++++++++++
;=================================
        ;lea edi, [ecx+result]     ;адрес начала ascii float output [result] в tmp
        ;mov esi, point
        ;movsb                     ;копируем ascii точку в [result] после целого
        ;;mov [tmpd], edi          ;сохраняем адрес начала ascii float output [result] в tmp
;---------------------------------
        mov esi, float
       @@:                        ;Формируем [result.float]
        movsb
        mov eax, [esi]
        or eax, eax
        je @f
        jmp @b
       @@:
;-----------------------------------------------------------------------------------------------------
    jmp .finita
;--------------------------------INTEGER Калькулятор ДЕЛЕНИЕ ПО МОДУЛЮ -------------------------------
DialogProc.mod_process:
   push eax ebx ecx edx edi esi
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
        call ClearRTM
        call ClearN                ;очистка [number]
;================================= преобразование ascii в hex integrer per byte
        stdcall ConvAB, dword typea, dword minusa
        ;xchg edx, eax
        push eax
        stdcall ConvAB, dword typeb, dword minusb
        xchg eax, ebx
        pop eax
;=================================
        div ebx
        add dl, 30h
        call ClearR
        mov [result], edx

;=================================
        pop esi edi edx ecx ebx eax   ; восстанавливаем в обратном порядке

 jmp DialogProc.topmost_ok







;-------------------------------------------------------------------------------------
;---------------------------------ОБРАБОТЧИК WIN32 -----------------------------------
  DialogProc.topmost_ok:                                     ;если нажата клавиша ok (calculate)
        invoke SetDlgItemText, [hwnddlg], ID_RESULT, result  ;выводим результат в поле result при нажатии ок
        ;call ClearR                                          ;почистим result из поля чтобы не маячил после загрузки в ячейки
        jmp     DialogProc.processed

  DialogProc.wmclose:
        invoke  EndDialog,[hwnddlg],0

  DialogProc.processed:
        mov     eax,1

  DialogProc.finish:
        pop     edi esi ebx
        ret
endp


;---------------------------------------------------------------
HexcProc:     ;процедура преобразования hex в ascii и запись в [result]
;---------------------------------------------------------------
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx

call ClearD
call ClearRTM
call ClearR
;================================================================

or dword[number],00000000h ;проверим не 0 ли был в результате и чего мы копаемся
je .nulll
   finit
   fild qword[number]     ;<<<<<<<<<<<<<<<<<<<<<<<<<<<

call ClearN               ;чистим только после загрузки числа в FPU
   frndint
   fbstp tword[decstr]    ; save st0 to memory in BCD
   ffree st               ; Empty ST(0)
   ffree st1              ; Empty ST(1)
   mov esi,dword decstr;+1; BCD (tword size) (without first sign byte) reversed
   mov edi,dword number   ; for expand and convert to ascii byte (reversed)

.bcdd:
   cmp dword[esi],0     ;
   jne @f               ;
   cmp dword[esi+4],0   ; У=Уверенность!
   jne @f               ; ^^проверки на нули в начале длинных целых чисел
   cmp dword[esi+8],0   ; что то около того
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
;===================================================================================
  mov esi, number       ;source for reverse and get lenght of result
  mov edi, tmpsult      ;destination
  add ecx, ecx          ;устанавливаеи значение счетчика для распакованного числа
  mov byte[sizes],cl    ;сохраним размер распакованого числа
  dec ecx               ;скорректируем счетчик
  add edi, ecx          ;добавляем смещение длинны строки в для tmpsult тк. писать будем справа на лево

  inc ecx               ;восстановим для итерации

 .iout:
  mov al, byte[esi]
  inc esi
  mov [edi],al
  dec edi               ;смещаемся по памяти приемника вверх на байт ()
  loop .iout

mov cl,[sizes]
mov esi, tmpsult
mov edi, result         ; копирование итогового результата в ASCII 
cmp byte[tmpsult],30h
jne @f
inc esi                         ;если забрался ноль из BCD его мы брать не будем
dec ecx
@@:
.if [minus]<>0                  ;проверим на флаг минуса
        mov byte [edi], '-'     ;Yes: store a minus character in [result]
        mov byte[minus],0
        inc edi                 ;сместимся на позицию для записи самого числа
  .endif

.if dword[integrer]<>0         ; Из целочисл деления +++++++++++++
mov ecx,0
      @@:
        cmp dword[integrer+ecx],0        ;предв
        jne .oper
        cmp dword[integrer+ecx+4],0      ;окончательн
        je @f
      .oper:
         mov eax, dword[integrer+ecx]
          ;or eax, 30h
          mov [edi],eax
          inc ecx
          inc edi
         jmp @b
      @@:
        mov byte [edi], '.'
        add edi, 1

     call ClearINT
     ret          ;выходим обратно в процедуру деления
  .endif
;mov cl,[sizes]  ;ненадо вроде?, иначе будет без учета верхней проверки на нули и минус
;-------------продолжение общей процедуры
.form:
lodsb
stosb
loop .form

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^HexcProc ЭТО ОТЛАДИЛ НЕ ТРОГАТЬ!!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


;.clear:

ret
.nulll:

mov byte[result], 30h
ret


;===============================================================
mdwordh2dec:
 ;-----------------------------
;        mov cl, [sizes]           ;передадим в ecx длинну HEX результата в байтах и
;        lea esi, byte[edi]
;        std                       ;двигаемся обратно
;       @@:
;        lodsb
;        or ecx, 0
;        je @f                     ;загружаем результат HEX в eax побайтно в цикле
;        shl eax, 8
;        dec ecx
;        jmp @b
;       @@:
;        cld
;===============================================================
;       mov   ebx, 10             ;это будет делитель 10
;        mov   edi, result         ;установим адрес edi на result
;       .if [minus]<>0            ;проверим на флаг минуса
;        mov byte [edi], '-'       ;Yes: store a minus character in [result]
;        add edi, 1                ;сместимся на позицию для записи самого числа
;        .endif
;.cycle:
;        inc   ecx                 ;будем прибавлять итерацию к ecx в цикле для определения размера буффера
;        xor   edx, edx            ;чистим edx
;        div   ebx                 ;делим число [number] на 10 (делится уже в переведенном int формате! т.е [number]/10)
;        push  edx                 ;кладем остаток в стек это уже разряды в формате INT в порядке от младших к старшим
;        or    eax,eax             ;проверяем регистр на наличие информации отличной от нуля
;      jne .cycle                  ;если в eax что то есть продолжаем цикл (увеличивая буффер ecx)
;        mov [tmp], cl             ;сохраним кол-во целых int байтов-цифр
;.iter:  pop   eax                 ;вынимаем из стека в eax получившиеся INT байты, в цикле определенном счетчиком ecx от старших к младшим
;        add   al, 0x30            ;корректируем значение int для вывода в формате ascii
;    stosb                         ;запишем значение из eax в result и сместимся на байт вперед (std/cld)
;        cmp   ecx, 1              ;если ecx 1 больше не rep-aem stosb т.к. это значит что eax уже пустой
;      je .clear                   ;прыгаем в следущую подпрограмму
;      dec ecx
;      cmp   ecx, 0                ;тут нам пригодится буффер ecx (будем писать в edi [result] ecx раз)
;      jnz   .iter

;===============================================================
proc ConvAB typeab, mini             ; -=  WORKED  =-
;=============================================================== конвертируeт числа из dword char int string (31 32 33 34) в hex  (4D2)
;int3
        xor eax, eax
        mov ecx, 0
        mov byte [tmp],00h
        mov esi, [typeab]
      .chk:
        lodsb
         cmp al,2Dh            ;проверим на минус ascii в выражении
         je .flag
         sub al, 30h
         mov [tmp+ecx], al     ;кладем в tmp входное число без ascii

         jmp .prom
     .flag:
        mov eax,[mini]               ; дублирующая проверка вышла
        mov dword[eax],00000001h     ;                   ??

     .prom:
        or [esi], byte 00h
        je .nxt
        cmp byte [esi-1],2Dh
        je .chk
        inc ecx
        jmp .chk
      .nxt:
;============================================

        mov [multipl], 10
        lea esi, [tmp+ecx]
        xor eax, eax
        mov ah, cl
        inc ah
        mov ecx, 1
        std
;-------------------------------------------- Init for Storages:
mov [count],ah
xor eax,eax                ;подготовим пару для накопления
xor edx,edx                ;

mov dword[edxecxstore+8],1 ;инициализируем значение для мультиплера
mov dword[edxecxstore+4],0
mov dword[edxecxstore],0

mov dword[edxeaxstore+8],0   ;очистим
mov dword[edxeaxstore+4],0   ;выходное хранилище HEX этой процедуры,
mov dword[edxeaxstore],  0   ;т.к. она вызывается 2 раза
;---------------------------------------------

    .llop:

        or [count], 0      ;в счетчике колличество разрядов dec числа
        je .cor
        xor eax, eax       ;подготовим регистр к работе
        xor ebx, ebx
        lodsb              ;тут нам нужен eax, поэтому и переносим из него в edi
        mov bl, al         ;кладем в ebx очередной разряд для конвертации
;----------MULTIPER CYCLE
        xor edx, edx
        mov edx, dword[edxecxstore+4]     ;Восстановим мультиплаер
        mov ecx, dword[edxecxstore+8]   ;                перед произведением
                                        ;умножаем разряд bl на основание в степени разряда
                                        ;imul c двумя аргументами не добавляет в edx!
        mul ecx                         ;от младшего к старшему ecx=(1^разр по модулю 10)
        mov dword[edxebxstore+4], edx
        mov dword[edxebxstore+8], eax

        xor ebx, ebx
        xor eax, eax
        xor edx, edx

;----------------------------------------------------------------------------
      .if dword[edxecxstore+4]>0          ;Проверим чтобы не умножить на 0
   ;       Сюда дебаг заходит с глюканами, не декрементирует счетчик?
        mov al, byte[esi+1]               ;заберем текущий знак опять в eax
        mov ebx, dword[edxecxstore+4]     ;высшие разряды multiplier
        mul ebx
        add dword[edxebxstore+4], eax
        adc edx,0
        add dword[edxebxstore], edx
      .endif
;---------------------------------------------------------------------------
.save:
        xor edx, edx
        xor eax, eax
           mov eax, ecx
           mul [multipl] ;умножаем ecx на 10 согласно разряду,(ecx=1 в 1 разр)
           mov dword[edxecxstore+8], eax    ; сохраним мультиплаер
           mov dword[edxecxstore+4], edx    ;         ECX

 ;-------------ADD EDX:EAX CYCLE
        mov eax, dword[edxeaxstore+8]   ;Восстановим
        mov edx, dword[edxeaxstore+4]   ;накопленное
        mov ebx, dword[edxeaxstore]     ;в ebx:edx:eax

        add eax, dword[edxebxstore+8]   ;сложим предыдущий eax и ebx
        adc edx,0                       ;добавим в edx если ,случилось переполнение
        add edx, dword[edxebxstore+4]   ;сложим предыдущий edx и edxebx
        adc edx,0
        add ebx, dword[edxebxstore]
 ;------------------------------

        mov dword[edxeaxstore+8], eax        ;              результат
        mov dword[edxeaxstore+4], edx        ;       полученый
        mov dword[edxeaxstore],   ebx        ;  сохраним
        xor eax, eax
        xor edx, edx
        xor ebx, ebx
        xor ecx, ecx
        dec [count]           ;уменьшаем итерации

        mov byte [esi+1],00h  ;чистим за собой tmp для будущих поколений
        jmp .llop
     .cor:
        cld
        mov eax,dword[edxeaxstore+8]   ;так будет пара edx:eax
        mov edx,dword[edxeaxstore+4]
        mov ebx,dword[edxeaxstore]
        mov ecx,0
     ret
 endp

;================================================================ Check for symbol '.' and create number & multipler for FPU
proc CheckFloat typeab
   mov esi, [typeab]      ;передадим адрес введенного числа для анализа
   mov edi, [typeab]      ;будем переписывать число из type a or b туда же но без точки
   mov ecx,0              ;подготовим ecx
   mov [tmp], 0           ;сюда впишем кол-во знаков до точки
.check:
   lodsb
   .if al <> '.'          ;если символ не равен точке записываем байт в переменную
        stosb
        .endif


   .if al='.'

                mov [flajok],1               ;типа возврат на тру фальзе из функции для проверки
                mov dword [tmp], ecx         ;запишем кол-во обнаруженых символов до точки
                sub cl, 1                    ;скорректируем кол-во результирующих символов-ascii-байтов (вычтем попадание в точку)

        .endif
    inc ecx            ;сюда занесем общую длинну числа с точкой

    or eax, 0
    jne .check
    sub cl, 1  ;скорректируем еще раз кол-во результирующих символов-ascii-байтов (вычтем нулевую итерацию по завершению подпрограммы)
    ;stosb             ; добиваем typea or b нулем т.к число короче из за отсутствия точки и там будет лишний байт(не будет т.к. затрется нулевой итерацией)
.if byte [flajok]=00h
         mov ecx, 00h  ;если целое не будем делить
         mov [tmp], cl ;и вычитать для деления
        .endif
.if byte [flajok]=01h
         sub cl, byte[tmp] ; получаем в ECX кол-во итераций деления на 10 для FPU ---------------------------------------------------------------!
        .endif
    ret
endp

;-------------------------------------
fpuinit:
FINIT
    ffree st0              ; Empty ST(0)
    ffree st1              ; Empty ST(1)
    mov word[cw],0000h
    mov word[cws],0000h
fstcw word [cws]
fstcw word [cw]
or word [cw], 0000001100000000b   ;окр к ближ четн,точность single dword
fldcw word [cw]
ret
;================================================================ Подготовка Float из typeab c помощью FPU и запись в abfloat
proc CreateFloat typeab, multab, abfloat, minusab
call fpuinit
mov ecx,0
mov ecx, [multab]           ;заряжаем счетчик для fpu сколько раз повторять операцию (декремент после каждой операции)
mov ecx, [ecx]
mov eax, [typeab]
FILD dword [eax]         ;Загрузить целое значение в ST0
@@:
or ecx, 0
je @f
FIDIV dword  [delitel]   ;поделить целое число на делитель в памяти и записать в ST0

loop @b
@@:
mov eax, [abfloat]
mov ebx, [minusab]
.if dword [ebx]=01h      ; ////////////////////////////////////////////////////////////
FCHS               ;  Попробуем откорректировать работу со знаками так
.endif             ;
FST dword   [eax]        ;сохранить float в памяти по адресу указаному в регистре в реальном формате
    ffree st                   ; Empty ST(0)
    ffree st1                  ; Empty ST(1)
fldcw word  [cws]        ;восстановим состояние FPU
mov eax, 0
mov ebx, 0
    ret
endp
;================================================================ Load FLOATS to FPU
flload:
call fpuinit
FLD dword   [Bfloat]     ;Загрузить float значение в ST0
FLD dword   [Afloat]     ;Загрузить float значение в ST0
mov eax, [operat]
;---------------------------------------------------------------
.if eax = dword resaddf
FADD ST, ST1             ;сложить float-ы st0, st1 и положить результат в ST0
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
;---------------------------------------------------------------
FST dword [eax]          ;записать результат [resultf]
    ffree st             ; Empty ST(0)
    ffree st1            ; Empty ST(1)
fldcw word [cws]         ;восстановим состояние FPU
mov eax, 0
ret
;----------------------------------------------------------------
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
;--------------------------------------------------------
WriteNum:   ;Копируем результат из EAX в number слева направо
;--------------------------------------------------------
        mov ecx, 0                 ;устанавливаем счетчик на 0
        mov edi, number            ;кладем в edi начальный адрес ячейки number
       @@:
        or eax,eax                 ;проверяем eax на наличие оставшейся после shr инфы
        je @f
        stosb                      ;записываем из al текущий байт в текущее смещение по esi
        shr eax, 8                 ;сдвигаем строку вправо и удаляем скопированный в esi байт
        inc ecx                    ;считаем тут длинну строки HEX результата
        jmp @b
       @@:
;---------------------------------------------------------------
        xchg edx,eax
       @@:
        or eax,eax                 ;проверяем eax на наличие оставшейся после shr инфы
        je @f
        stosb                      ;записываем из al текущий байт в текущее смещение по esi
        shr eax, 8                 ;сдвигаем строку вправо и удаляем скопированный в esi байт
        inc ecx                    ;считаем тут длинну строки HEX результата
        jmp @b
       @@:
ret
;===============================================================

proc dispf resf                 ;proc (dispf) (dword [operat]) ;переводим результат float в ascii-bytes
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx
finit

    fstcw control
    mov ax, control

    mov ah, 00001100b           ; set  RC=00 (режим округления к бл. четн.) PC=11; расширенная точность
    mov temp, ax
    fldcw temp                  ; Load new rounding mode

mov eax,0
mov eax, [resf]

    fld dword [eax]             ; Load Float корректно но надо ограничить знаки
;-------------------------------------
    fxam                        ; ST0 == 0.0?    C3, C2, C0 = 101(st0 empty)
    fstsw ax                    ; загрузим флаги fpu в eax
    sahf
    jnc @f                      ;                                       990
    fchs                        ; Change sign
    mov [minus], 1              ;поставим флаг для вывода если выгрузили минус из fpu
  @@:
;-------------------------------------
    mov edi, decstr
    call .dbltodec
        ret
endp
;===============================================================================================

.dbltodec:                      ; Args: ST(0): FPU-register to convert, EDI: pointer to string
   xor eax, eax
   xor ebx, ebx      ;
   xor ecx, ecx      ;
   xor edx, edx      ;  Чистим стек
push ebx ebx ebx     ;
pop  ebx ebx ebx     ;
    push ebp
    mov ebp, esp
    sub esp, 12



    ; Separate integer and fractional part & convert integer part into ASCII
    ; Разделим целое и перцишен и сконвертируем целую часть в ascII
    fst integer

    frndint                     ; ST(0) round to integer

    fld integer

    mov dword [ebp-12], 00000000h     ; чистим стэк
    mov dword [ebp-8],  00000000h
    fxch
    fsub st1, st0               ; Integral part in ST(0), fractional part in ST(1)
    call .bcdtodec
    fabs                        ; Make fractional positive (not guaranteed by fsub)

    mov byte [edi], '.'         ; Decimal point
    add edi, 1

    ; Move 10 to st(1)
    mov ten, 10
    fild ten
    fxch

    ; isolate digits of fractional part and store ASCII
.get_fractional:
    fmul st0, st1               ; Multiply by 10 (shift one decimal digit into integer part)
    fist word temp              ; Store digit
    fisub word temp             ; Clear integer part
    mov al, byte temp           ; Load digit
    or al, 0x30                 ; Convert digit to ASCII
    mov byte [edi], al          ; Append it to string
    add edi, 1                  ; Increment pointer to string
    fxam                        ; ST0 == 0.0?    C3, C2, C0 = 101(st0 empty)
    fstsw ax                    ; загрузим флаги fpu в eax
    sahf                        ; сохраним их в регистре флагов CPU
    jnz .get_fractional         ; No: once more  Проверяем теперь FPU на зеро
    mov byte [edi], 0           ; Null-termination for ASCIIZ

    ; clean up FPU
    ffree st                    ; Empty ST(0)
    ffree st1                   ; Empty ST(1)
    ;fldcw control              ; Restore old rounding mode  ска блт

    leave
    ret                         ; Return: EDI points to the null-termination of the string

.bcdtodec:                      ; Args: ST(0): FPU-register to convert, EDI: target string
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx

    push ebp
    mov ebp, esp
    sub esp, 10                 ; 10 bytes for local tbyte variable

      pop eax eax
      xor eax, eax
      push eax eax
    fbstp [ebp-10]              ; выталкивает число из стека fpu в стек в CPU в ДЕСЯТИЧНОМ (BCD) формате =====
    mov ecx, 10                 ; Loop counter
    lea esi, [ebp - 1]          ; bcd + 9 (last byte)
    xor bl, bl                  ; Checker for leading zeros

    ; Handle sign
    btr word [ebp-2], 15        ; Move sign bit into carry flag and clear it
    jnc .loo                    ; Negative?
    mov byte [edi], '-'         ; Yes: store a minus character
    add edi, 1

    .loo:
        mov al, byte [esi]
        mov ah, al
        shr ah, 4               ; Isolate left nibble
        or bl, ah               ; Check for leading zero
        jz .uvasia
        or ah, 30h              ; Convert digit to ASCII
        mov [edi], ah
        add edi, 1
        .uvasia:
        and al, 0Fh             ; Isolate right nibble
        or bl, al               ; Check for leading zero
        jz .vasia
        or al, 30h              ; Convert digit to ASCII
        mov [edi], al
        add edi, 1
        .vasia:
        sub esi, 1
        loop .loo

    test bl, bl                 ; BL remains 0 if all digits were 0
    jnz .R1                     ; Skip next line if integral part > 0
    mov byte [edi], '0'
    add edi, 1

    .R1:
    mov byte [edi], 0           ; Null-termination for ASCIIZ
    leave
    ret                         ; Return: EDI points to the null-termination of the string

;--------------------------------------------------------
ClearR:                            ;очистка [result]
;--------------------------------------------------------
        push edi
        xor eax, eax
        mov edi, result
        mov ecx, sizeof.result /4  ;(ложим в ecx общий размер места result в dword-ах)
        rep stosd                  ;чистим dword-ами ecx раз
        pop edi
ret
;--------------------------------------------------------
ClearN:                            ;очистка [number]
;--------------------------------------------------------
        push edi
        xor eax, eax
        mov edi, number
        mov ecx, sizeof.number     ;(ложим в ecx общий размер места number в байтах)
        rep stosb                  ;чистим байтами ecx раз
        pop edi
ret
;--------------------------------------------------------
ClearF:                            ;очистка [float]
;--------------------------------------------------------
        push edi
        xor eax, eax
        mov edi, float
        mov ecx, sizeof.float      ;(ложим в ecx общий размер места float в байтах)
        rep stosb                  ;чистим байтами ecx раз
        pop edi
ret
;--------------------------------------------------------
ClearD:                            ;очистка [decstr]
;--------------------------------------------------------
        push edi
        xor eax, eax
        mov edi, decstr
        mov ecx, sizeof.decstr     ;(ложим в ecx общий размер места decstr в байтах)
        rep stosb                  ;чистим байтами ecx раз
        pop edi
ret
;--------------------------------------------------------
ClearRF:                           ;очистка [resultf]
;--------------------------------------------------------
        push edi
        xor eax, eax
        mov edi, resultf
        mov ecx, sizeof.resultf    ;(ложим в ecx общий размер места в resultf байтах)
        rep stosb                  ;чистим байтами ecx раз
        pop edi
ret
;--------------------------------------------------------
ClearRTM:                           ;очистка [tmpult]
;--------------------------------------------------------
        push edi
        xor eax, eax
        mov edi, tmpsult
        mov ecx, sizeof.tmpsult /4 ;(ложим в ecx общий размер места в tmpsult байтах)
        rep stosd                  ;чистим байтами ecx раз
        pop edi
ret
;--------------------------------------------------------
ClearINT:                           ;очистка [tmpult]
;--------------------------------------------------------
        push edi
        xor eax, eax
        mov edi, integrer
        mov ecx, sizeof.integrer ;(ложим в ecx общий размер места в tmpsult байтах)
        rep stosb                  ;чистим байтами ecx раз
        pop edi
ret
;==========================================================================
section '.bss' data readable writeable


  typea db 31 dup (0),0          ;suda zapishem pervoe chislo
 sizeof.typea = $ - typea
  typeb db 31 dup (0),0          ;vtoroe chislo
 sizeof.typeb = $ - typeb
 floatb_int db 31 dup (0),0
 number db 31 dup (0),0          ;сюда будем ложить результат операций cpu или fpu
 sizeof.number = $ - number      ;размер результата HEX в байтах
 result dd 31 dup (0),0          ;cюда уже ложим результат переведенный в byte ascii
 sizeof.result = $ - result      ;высчитываем размер строки результата в dword-ах
 tmpsult dd 31 dup (0),0
 sizeof.tmpsult = $ - tmpsult
 tmp db 31 dup (0),0
 tmpd db (0),0
 float db 31 dup (0),0
 sizeof.float = $ - float
 integrer db 31 dup (0),0
 sizeof.integrer = $ - integrer
 saveres db (0),0                ;остаток из dx
 multipl dd (0),0
 sizes db (0),0
 style dd (0),0
 stackp dd (0),0
 point db '.',0
 flajok db (0),0
 multa dd (0),0                  ;сюда запомним колво цифр до точки слева числа A
 multb dd (0),0                  ;сюда запомним колво цифр до точки слева числа B
 minus db (0),0                  ;флагг минус для целочисленного вычитания
 wozflag dd (0),0
 operat dd (0),0                 ;здесь лежит адрес текущей переменной операции resXXXf
 ids dd (0),0
 fula db 'AF',0
 fulb db 'BF',0
 NaN db 'NaN',0
 empa db 'mA',0
 empb db 'mB',0
 minusa dd (0),0
 minusb dd (0),0
 count db(0),0
 edxecxstore db 12 dup (0),0
 edxebxstore db 12 dup (0),0
 edxeaxstore db 12 dup (0),0
;--------------------------------------------------------------------------------------
 memA db 31 dup (0),0            ;
 memB db 31 dup (0),0            ;                 Memory Buttons
 memC db 31 dup (0),0            ;
 memD db 31 dup (0),0            ;

;--------------------------------------- FPU ------------------------------------------
 Afloat dd (0),0
 sizeof.Afloat = $ - Afloat
 Bfloat dd (0),0
 sizeof.Bfloat = $ - Bfloat
 resultf db 11 dup (0),0
 sizeof.resultf = $ - resultf

 resaddf db 10 dup (0),0
 sizeof.resaddf = $ - resaddf
 ressubf db 10 dup (0),0
 sizeof.ressubf = $ - ressubf
 resmulf db 10 dup (0),0
 sizeof.resmulf = $ - resmulf
 resdivf db 10 dup (0),0
 sizeof.resdivf = $ - resdivf

 delitel dd 10,0
  cw dd (0),0
 cws dd (0),0
 decstr db 63 dup (0),0          ;результат FPU в ascii-байтах (прямой записью)
 sizeof.decstr = $ - decstr      ;размер результата ascii FPU в байтах


;========================================================================================




section '.idata' import data readable writeable

  library kernel,'KERNEL32.DLL',\
          user,'USER32.DLL';,\
          ;msvcrt,'msvcrt.dll'

  import kernel,\
         GetModuleHandle,'GetModuleHandleA',\
         ExitProcess,'ExitProcess'

  import user,\
         DialogBoxParam,'DialogBoxParamA',\
         IsDlgButtonChecked,'IsDlgButtonChecked',\
         SetDlgItemText,'SetDlgItemTextA',\
         EndDialog,'EndDialog',\
         GetDlgItemText,'GetDlgItemTextA'
         ;CheckRadioButton,'CheckRadioButton',\
         ;MessageBox, 'MessageBoxA',\
         ;GetDlgCtrlID,'GetDlgCtrlID'
         ;SetWindowLong,'SetWindowLongA',\
         ;PostMessage,'PostMessageA'
         ;SetFocus,'SetFocus'
         ;GetDlgItem,'GetDlgItem',\
         ;SetDlgCtrlID,'SetDlgCtrlID',\
         ;SetFocus,'SetFocus',\
         ;GetFocus,'GetFocus',\
         ;GetCapture,'GetCapture',\
         ;GetCursor,'GetCursor',\
         ;GetMenuItemID,'GetMenuItemID'

  ; import msvcrt,\
  ;              printf,         'printf',\       ;Псевдоним функция
  ;              system,         'system';,\
               ; exit,           'exit';,\
               ; scanf,          'scanf',\        ;Псевдоним функция
               ; free,           'free',\
               ; malloc,         'malloc',\
               ; memset,         'memset',\
               ; getch,          '_getch'         ;Псевдоним функция

;================================================================
section '.rsrc' resource data readable
directory RT_DIALOG,dialogs
 resource dialogs,\
 100,LANG_ENGLISH+SUBLANG_DEFAULT,canculator
 dialog canculator,'Okkolo Pro v.1.50 Beta Unregistered',70,70,190,175,WS_MINIMIZEBOX+WS_POPUP+WS_CAPTION+WS_SYSMENU+DS_MODALFRAME+DS_3DLOOK

dialogitem 'BUTTON','BC',ID_D, 160, 120, 16, 14, WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
dialogitem 'BUTTON','AC',ID_C, 135, 120, 15, 14, WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
dialogitem 'BUTTON','mB',ID_B, 110, 120, 15, 14, WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
dialogitem 'BUTTON','mA',ID_A, 85, 120, 15, 15, WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
dialogitem 'STATIC','&Entry A:',65535, 10, 5, 30, 8, WS_VISIBLE,WS_EX_LEFT;,NOT WS_GROUP;, SS_LEFT
dialogitem 'EDIT','',ID_TYPEA,  5, 15, 176, 13, WS_VISIBLE+WS_BORDER+WS_TABSTOP;+EM_LIMITTEXT+20
dialogitem 'STATIC','&Entry B:',65535, 10, 30, 30, 8,WS_VISIBLE,WS_EX_LEFT
dialogitem 'EDIT','',ID_TYPEB,  5, 40, 176, 13, WS_VISIBLE+WS_BORDER+WS_TABSTOP ;+BS_NOTIFY
dialogitem 'EDIT','',ID_RESULT, 85, 100, 90, 13, WS_VISIBLE+WS_BORDER+WS_TABSTOP+ES_AUTOHSCROLL
dialogitem 'BUTTON','&Operation',-1, 5, 70, 60, 70,WS_VISIBLE+BS_GROUPBOX
dialogitem 'BUTTON','&Add',ID_ADD, 20, 82, 25, 13,WS_VISIBLE+BS_AUTORADIOBUTTON+WS_TABSTOP+WS_GROUP
dialogitem 'BUTTON','S&ub',ID_SUB, 20, 95, 25, 13,WS_VISIBLE+BS_AUTORADIOBUTTON
dialogitem 'BUTTON','&Mul',ID_MUL, 20, 108, 30, 13,WS_VISIBLE+BS_AUTORADIOBUTTON
dialogitem 'BUTTON','&Div',ID_DIV, 20, 121, 30, 13, WS_VISIBLE+BS_AUTORADIOBUTTON
dialogitem 'BUTTON','&Result',-1, 75, 90, 110, 50,WS_VISIBLE+BS_GROUPBOX
dialogitem 'BUTTON','&Div-Module',ID_TOPMOST, 135, 75, 50, 13, WS_VISIBLE+WS_TABSTOP+BS_AUTOCHECKBOX
dialogitem 'BUTTON','Calculate',IDOK, 30, 150, 45, 15,WS_VISIBLE+WS_TABSTOP+BS_DEFPUSHBUTTON
dialogitem 'BUTTON','E&xit',IDCANCEL, 110, 150, 45, 15,WS_VISIBLE+WS_TABSTOP+BS_PUSHBUTTON
enddialog
