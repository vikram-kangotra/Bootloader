; converts a LBA address to CHS address
; Params:
;   %1 = LBA address
; Returns:
;   cx [0:5] = sector
;   cx [6:15] = cylinder
;   dh = head

lba_to_chs:
    ; lba = (cyl * heads + head) * sectors + sector - 1
    ; cyl = lba / (heads * sectors)
    ; head = (lba / sectors) % heads
    ; sector = (lba % sectors) + 1

    push ax
    push dx

    xor dx, dx
    div word [bpb_sectors_per_track]

    inc dx
    mov cx, dx

    xor dx, dx
    div word [bpb_number_of_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax

    ret

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
    mov di, 3

.retry:
    pusha
    stc
    int 0x13
    jnc .done

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp disk_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 0x13
    jc disk_error
    popa
    ret

disk_error:
    mov si, msg_disk_error
    call puts

    jmp wait_and_reboot
