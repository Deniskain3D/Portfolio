#fasm#
pusha
xor di,di
xor ax,ax
xor bx,bx
xor cx,cx
xor dx,dx


mov ax,13h 
int 10h 
push 0a000h
pop ds
mov bl,255   ;set color 
;-----------------------
check:
inc bl      ;for slidedown color
drawpoint:
mov dx,3015 ;start point at 10y lines and 135px offset
n_vect:
mov cx,32h
cmp dx,18880
ja slide
inc bl
add di,dx

vdraw:
mov byte[di],bl
inc di
loop vdraw
xor di,di
add dx,140h
loop n_vect 


slide:
push ax
push dx
xor ax,ax
xor dx,dx
;call braketormoz
call vgasync
pop dx
pop ax
;restore videomemory entrypoint
push 0a000h
pop ds
;------------
xor di,di
sub bl,52     ;return color to topline state
loop check

exit:
popa
int 16h
ret 
;braketormoz:
;push 0000
;pop ds
;mov ax,[046ch]
;add ax,1   ;onesec/18
;lp: cmp ax,[046ch]
;jnz lp
;ret
vgasync:
mov      dx, 3DAh ;load videocard laserstate address to cpu register
zzzz:    in       al, dx ;copy laserstate from videocard to al
         and      al, 8        ;comparewritetest
         je       zzzz
ret