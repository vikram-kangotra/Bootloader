%define ENDL 0x0a, 0x0d

msg_loading: db 'Loading...', ENDL, 0x00
msg_disk_error: db "Read operation from disk failed", ENDL, 0
msg_kernel_not_found: db "KERNEL.BIN file not found!", ENDL, 0

file_kernel_bin: db "KERNEL  BIN"
