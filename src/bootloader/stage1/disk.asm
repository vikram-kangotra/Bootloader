;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA Address
;   - cl: Number of sectors to read
;   - dl: Drive number
;   - es:bx: Buffer to read into

disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call lba_to_chs
    pop ax

    mov ah, 0x02
    mov di, 3                       ; retry 3 times

.retry:
    pusha
    stc                             ; set carry flag
    int 0x13
    jnc .success

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; All attempts failed
    jmp disk_error

.success:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

;
; Resets disk controller
; Parameters:
;  - dl: Drive number

disk_reset:
    pusha
    mov ah, 0x00
    stc
    int 0x13
    jc disk_error
    popa
    ret

disk_error:
    mov si, msg_disk_error
    call puts
    jmp wait_key_and_reboot

msg_disk_error:
    db "Read operation from disk failed", ENDL, 0
