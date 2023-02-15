[org 0x7c00]
[bits 16]

LOAD_SEGMENT equ 0x100
LOAD_OFFSET equ 0x0

jmp short start
nop

%include "bpb.asm"

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, 0x7c00
    mov bp, sp

    ; Some BIOS might start us at 0x7c00:0x0000 instead of 0x0000:0x7c00
    push es
    push word .after
    retf
.after:
    mov [ebpb_drive_number], dl

    push es
    mov ah, 0x08
    int 0x13
    jc disk_error
    pop es

    and cl, 0x3f
    xor ch, ch
    mov [bpb_sectors_per_track], cx

    inc dh
    mov [bpb_number_of_heads], dh

    mov ax, [bpb_number_of_fats]
    mov bx, [bpb_sectors_per_fat]
    mul bx
    add ax, [bpb_reserved_sectors]
    xor ah, ah
    push ax                              ; root dir start

    mov ax, [bpb_root_dir_entries]
    shl ax, 5
    xor dx, dx
    div word [bpb_bytes_per_sector]

    test dx, dx
    jz .read_next_sector
    inc ax                              ; root dir size

.read_next_sector:
    mov cl, al
    pop ax
    mov bx, buffer
    mov dl, [ebpb_drive_number]
    call disk_read

    xor bx, bx
    mov di, buffer

.check_entry:
    mov cx, 11
    mov si, filename
    push di
    repe cmpsb
    pop di
    je .found_file

    add di, 32
    inc bx
    cmp bx, [bpb_root_dir_entries]
    jl .check_entry

    jmp stage2_not_found_error

.found_file:

    mov ax, [di + 26]
    mov [file_cluster], ax

    mov ax, [bpb_reserved_sectors]
    mov bx, buffer
    mov cl, [bpb_sectors_per_fat]
    mov dl, [ebpb_drive_number]
    call disk_read

    mov bx, LOAD_SEGMENT
    mov es, bx
    mov bx, LOAD_OFFSET

    mov ax, [file_cluster]

.load_stage2_loop:

    add ax, 31

    mov cl, 1
    mov dl, [ebpb_drive_number]
    call disk_read

    add bx, [bpb_bytes_per_sector]

    mov ax, [file_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0fff

.next_cluster_after:
    cmp ax, 0x0ff8
    jl .load_stage2_loop

.end_of_file:
    mov dl, [ebpb_drive_number]

    mov ax, LOAD_SEGMENT
    mov ds, ax
    mov es, ax

    jmp LOAD_SEGMENT:LOAD_OFFSET

wait_and_reboot:
    mov si, msg_wait_and_reboot
    call puts

    mov ah, 0x00
    int 0x16 

    jmp 0xffff:0x0000

puts:
    push ax
.puts_loop:
    lodsb
    or al, al
    jz .puts_done
    mov ah, 0x0e
    int 0x10
    jmp .puts_loop
.puts_done:
    pop ax
    ret

stage2_not_found_error:
    mov si, msg_stage2_not_found
    call puts

    jmp wait_and_reboot

%include "disk.asm"

%define ENDL 0x0d, 0x0a

msg_disk_error: db "Disk error", ENDL, 0
msg_stage2_not_found: db "Stage2 not found", ENDL, 0
msg_wait_and_reboot: db "Press any key to reboot", ENDL, 0

filename: db "STAGE2  BIN"
file_cluster: dw 0

times 510-($-$$) db 0
dw 0xaa55

buffer:
