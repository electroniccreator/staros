; STAROS kernel v0.2 — text-mode desktop
BITS 16
ORG  0x8000

    mov ax, 0x0003
    int 0x10

    mov ah, 0x01          ; hide cursor
    mov cx, 0x2000
    int 0x10

    call desktop
    call prompt

main:
    xor ah, ah
    int 0x16
    cmp al, 13
    je run
    cmp al, 8
    je back
    cmp byte [blen], 24
    jae main
    mov bl, [blen]
    xor bh, bh
    mov [buf+bx], al
    inc byte [blen]
    call prompt
    jmp main

back:
    cmp byte [blen], 0
    je main
    dec byte [blen]
    mov bl, [blen]
    xor bh, bh
    mov byte [buf+bx], 0
    call prompt
    jmp main

run:
    mov bl, [blen]
    xor bh, bh
    mov byte [buf+bx], 0
    call do_cmd
    mov byte [blen], 0
    mov byte [buf], 0
    call desktop
    call prompt
    jmp main

do_cmd:
    mov si, buf
    mov di, c_help
    call eq
    je cmd_help
    mov di, c_about
    call eq
    je cmd_about
    mov di, c_time
    call eq
    je cmd_time
    mov di, c_clear
    call eq
    je cmd_ok
    mov di, c_reboot
    call eq
    je cmd_reboot
    mov word [status], m_bad
    ret
cmd_ok:
    mov word [status], m_ok
    ret
cmd_help:
    mov word [status], m_help
    ret
cmd_about:
    mov word [status], m_about
    ret
cmd_time:
    call fill_time
    mov word [status], tbuf
    ret
cmd_reboot:
    jmp 0xFFFF:0x0000

eq:
    push si
.l:
    mov al, [si]
    cmp al, [di]
    jne .n
    test al, al
    jz .y
    inc si
    inc di
    jmp .l
.y:
    pop si
    ret
.n:
    pop si
    ret

desktop:
    mov dh, 0
.row:
    mov dl, 0
.col:
    mov al, ' '
    cmp dh, 0
    je .top
    cmp dh, 24
    je .bot
    mov ah, 0x1F
    jmp .put
.top:
    mov ah, 0x70
    jmp .put
.bot:
    mov ah, 0x70
.put:
    call put
    inc dl
    cmp dl, 80
    jb .col
    inc dh
    cmp dh, 25
    jb .row

    mov dh, 0
    mov dl, 2
    mov si, title
    mov ah, 0x70
    call puts

    mov dh, 24
    mov dl, 2
    mov si, hint
    mov ah, 0x70
    call puts

    ; window
    mov dh, 4
    mov dl, 8
    mov si, win1
    mov ah, 0x1E
    call puts
    mov dh, 5
    mov dl, 8
    mov si, win2
    mov ah, 0x1E
    call puts
    mov dh, 6
    mov dl, 8
    mov si, win3
    mov ah, 0x1E
    call puts
    mov dh, 7
    mov dl, 8
    mov si, win4
    mov ah, 0x1E
    call puts
    mov dh, 8
    mov dl, 8
    mov si, win5
    mov ah, 0x1E
    call puts
    mov dh, 9
    mov dl, 8
    mov si, win6
    mov ah, 0x1E
    call puts

    mov dh, 12
    mov dl, 8
    mov si, [status]
    mov ah, 0x1A
    call puts
    ret

prompt:
    mov dh, 20
    mov dl, 8
    mov si, pfx
    mov ah, 0x1F
    call puts
    mov si, buf
    call puts
    mov al, ' '
    mov ah, 0x1F
    call putc
    mov al, ' '
    call putc
    ret

; AL=char AH=attr DH=row DL=col
put:
    push ax
    push bx
    push dx
    push es
    push ax
    mov ax, 0xB800
    mov es, ax
    xor ax, ax
    mov al, dh
    mov bl, 80
    mul bl
    xor dh, dh
    add ax, dx
    shl ax, 1
    mov di, ax
    pop ax
    mov [es:di], ax
    pop es
    pop dx
    pop bx
    pop ax
    ret

putc:
    call put
    inc dl
    ret

puts:
.n:
    lodsb
    test al, al
    jz .d
    call putc
    jmp .n
.d:
    ret

fill_time:
    mov ah, 0x02
    int 0x1A
    mov si, tbuf
    mov al, ch
    call bcd
    mov byte [si], ':'
    inc si
    mov al, cl
    call bcd
    mov byte [si], ':'
    inc si
    mov al, dh
    call bcd
    mov byte [si], 0
    ret

bcd:
    push ax
    shr al, 4
    and al, 0x0F
    add al, '0'
    mov [si], al
    inc si
    pop ax
    and al, 0x0F
    add al, '0'
    mov [si], al
    inc si
    ret

title:   db 'STAROS  0.2                              text desktop',0
hint:    db 'help   about   time   clear   reboot',0
pfx:     db 'staros> ',0
win1:    db '+--------------------------------------------+',0
win2:    db '|  STAROS                                    |',0
win3:    db '|  Your machine is now running YOUR kernel.  |',0
win4:    db '|  Type a command below, then press Enter.   |',0
win5:    db '|  This is still 16-bit real mode. Next: C.  |',0
win6:    db '+--------------------------------------------+',0
m_ok:    db 'ok.                                          ',0
m_bad:   db 'unknown command. try help                    ',0
m_help:  db 'commands: help about time clear reboot       ',0
m_about: db 'STAROS — hobby kernel built for Stardance    ',0
c_help:  db 'help',0
c_about: db 'about',0
c_time:  db 'time',0
c_clear: db 'clear',0
c_reboot:db 'reboot',0
status:  dw m_ok
blen:    db 0
buf:     times 28 db 0
tbuf:    times 12 db 0