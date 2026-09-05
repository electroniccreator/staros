; STAROS bootloader — loads the kernel from floppy sector 2
BITS 16
ORG  0x7C00

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    cld
    mov [drv], dl

    mov si, loadmsg
    call print

    mov ah, 0x00
    mov dl, [drv]
    int 0x13

    mov ah, 0x02
    mov al, 16
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [drv]
    mov bx, 0x8000
    int 0x13
    jc fail

    jmp 0x0000:0x8000

fail:
    mov si, failmsg
    call print
hang:
    jmp hang

print:
    lodsb
    test al, al
    jz .d
    mov ah, 0x0E
    int 0x10
    jmp print
.d:
    ret

drv      db 0
loadmsg  db 'STAROS loading kernel...',13,10,0
failmsg  db 'disk read failed',0

times 510-($-$$) db 0
dw 0xAA55