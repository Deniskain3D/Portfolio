format pe gui
entry start
include 'win32ax.inc'

start:
	mov ecx, 0x2
	mov eax, 'kot'
	mov ebx, 'bot'
.ring:
	push ebx
	mov edx, eax
	not ebx
	and eax, ebx
	not ebx
	not edx
	and ebx, edx
	or eax, ebx
	pop ebx
	push eax
	mov edx, ebx
	not eax
	and ebx, eax
	not eax
	not edx
	and eax, edx
	or ebx, eax
	pop eax
	push ebx
	mov edx, eax
	not ebx
	and eax, ebx
	not ebx
	not edx
	and ebx, edx
	or eax, ebx
	pop ebx
	mov [outa+4], eax
	mov [outb+4], ebx
	pusha
	cinvoke wsprintf,buffer,fmt, outa
	invoke	MessageBox,0,buffer,title,0
	cinvoke wsprintf,buffer,fmt, outb
	invoke	MessageBox,0,buffer,title,0
	popa
	dec ecx
jnz .ring
	ret

data import
library user32,'USER32.DLL';, msvcrt,'MSVCRT.DLL'
;import msvcrt,sprintf,'sprintf'
include 'api/user32.inc'
end data

section '.bss' data readable writable
title db 'XOR Test',0
fmt db '%s',0
outa dd 'eax:',0,0
outb dd 'ebx:',0,0
buffer rb 32
