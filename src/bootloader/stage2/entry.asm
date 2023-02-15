[bits 16]

global entry
entry:
    cli

    mov ax, 0
    mov es, ax
    mov di, 0x0

    mov cx, 4
    rep stosw

    mov es:[di], word 0xffff

    mov es:[di+2], word 0x0000
    mov es:[di+4], byte 0x0
    mov es:[di+5], byte 0x9a
    mov es:[di+6], byte 0xcf
    mov es:[di+7], byte 0x00
    add di, 8

    mov es:[di], word 0xffff

    mov es:[di+2], word 0x0000
    mov es:[di+4], byte 0x0
    mov es:[di+5], byte 0x92
    mov es:[di+6], byte 0xcf
    mov es:[di+7], byte 0x00

    lgdt [es:di]

    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp 0x08:start_pm

[bits 32]

extern kmain

start_pm:

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x2ffff

    call kmain

    cli
    hlt

; gdt_start:
; 
; gdt_null:
;     dd 0
;     dd 0
; 
; gdt_code:
;     dw 0xffff
;     dw 0
;     db 0
;     db 10011010b
;     db 11001111b
;     db 0
; 
; gdt_data:
;     dw 0xffff
;     dw 0
;     db 0
;     db 10010010b
;     db 11001111b
;     db 0
; 
; gdt_end:
;     
; gdt_descriptor:
;     dw gdt_end - gdt_start - 1
;     dd gdt_start
; 
; CODE_SEG equ gdt_code - gdt_start
; DATA_SEG equ gdt_data - gdt_start
