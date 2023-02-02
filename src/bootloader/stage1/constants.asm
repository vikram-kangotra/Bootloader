%define ENDL 0x0a, 0x0d

hello: db 'Hello, world!', ENDL, 0x00
msg_disk_error: db "Read operation from disk failed", ENDL, 0
