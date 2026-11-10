;Description:Senario kinhshs basismeno se 8086 opou ena tetragwno pou allagei xrwma
;elegxei thn tuxaia aujhshs enos kinoumenou fidiou sthn Video Memory mexri na gemisei
;th grammh kai na termatisei
;Author: marthachd
;Date:10/01/2026

org 100h

jmp start

;Statheres
ROAD_TOP equ 15      ; panw dromos sthn grammh 15
ROAD_BOTTOM equ 17   ; katw dromos sthn grammh 17  
SNAKE_LINE equ 16    ; sthn grammh 16 kineitai to fidi
VIDEO_SEG equ 0B800h ; bash Video Memory 
ATTR_ROAD equ 07h    ; Gkri se mauro
ATTR_SNAKE equ 0Eh   ; Kitrino se mauro
ATTR_RED equ 44h     ; Kokkino
ATTR_GREEN equ 22h   ; Prasino

;Metavlites 
snake_pos    dw 0       ; arxiki thesi sthn grammh 16 (0-79)
snake_len    db 1       ; arxiko mikos fidiou 1
square_color db ATTR_GREEN; xrwma tetragonou
last_square dw 0     ; teleutaia allagh xrwmatos tetragonou
last_snake dw 0      ; teleutaia kinisi fidiou
rand_seed dw 1234h   ; gia tuxaio N
N_value db 0         ; timi N
prev_color db ATTR_GREEN  ; prohgoumeno xrwma tetragonou

msg db "It's not a bug; it's an undocumented feature$" ;minima termatismou

;Kurio programma
start:
    ;arxikopoihsh video mode
    mov ax, 0003h
    int 10h
   
    ;topothetish segments
    mov ax, cs
    mov ds, ax
    mov es, ax
   
    ; sxediash dromou
    call draw_road
   
    ; sxediash tetragonou 3x3
    call draw_square
   
    ; arxikopoihsh timers
    mov ah, 00h
    int 1Ah
    mov [last_square], dx
    mov [last_snake], dx
   
    ; sxediash arxikou fidiou sthn grammh 16
    call draw_snake

main_loop:
    ; elegxos gia tetragono (1 sec)
    call check_square
   
    ; elegxos gia fidi (100 ms)  
    call check_snake
   
    ; elegxos gia telos (megisto = 80)
    mov al, [snake_len]
    cmp al, 80
    jge game_end
   
    ; mikrh kathisterhsh
    mov cx, 1000
delay:
    loop delay
   
    jmp main_loop

game_end:
    ; emfanish minimatos
    mov ah, 09h
    lea dx, msg
    int 21h
   
    ; anamonh gia plhktro
    mov ah, 00h
    int 16h
   
    ; epistrofh sto DOS
    mov ax, 4C00h
    int 21h


;Diadikasies

draw_road proc ; sxediash dromou
    push es
    push di
    push ax
    push cx
   
    mov ax, VIDEO_SEG
    mov es, ax
   
    ; panw dromos (grammh 15)
    mov di, ROAD_TOP * 160   ;15*160=2400 bytes offset
    mov cx, 80               ;80 sthles
    mov ax, ATTR_ROAD * 256 + 'A' ; A me gkri xrwma
draw_road_top:
    mov es:[di], ax
    add di, 2
    loop draw_road_top
   
    ; katw dromos (grammh 17)  
    mov di, ROAD_BOTTOM * 160 ;17*160=2720 bytes offset
    mov cx, 80
draw_road_bottom:
    mov es:[di], ax
    add di, 2
    loop draw_road_bottom
   
    pop cx
    pop ax
    pop di
    pop es
    ret
draw_road endp

; sxediash tetragonou 3x3 sta deksia opws sthn eikona (theseis 77-79)
draw_square proc
    push es
    push di
    push ax
    push cx
   
    mov ax, VIDEO_SEG
    mov es, ax
    
    ;xarakthras kai xrwma
    mov al, 219      ; ASCII 219:gemato tetragono
    mov ah, [square_color]
   
    ; Grammh 0: Stiles 77,78,79
    mov di, 0 * 160 + 77 * 2  ;upologisei thn dieuthinsi sth video memory
                              ;gia thn grammh 0 kai stili 77 epeidi kathe grammh exei 
                              ;160 bytes (80 xaraktires * 2 bytes)kai kathe xarakthras katalamvanei 2 bytes
    mov es:[di], ax           ; Stili 77
    mov es:[di+2], ax         ; Stili 78
    mov es:[di+4], ax         ; Stili 79
 
    ; Grammh 1: Stiles 77,78,79
    mov di, 1* 160 +77*2 
    mov es:[di], ax                                      
    mov es:[di+2], ax         
    mov es:[di+4], ax   
     
    ; Grammh 2: Stiles 77,78,79
    mov di,2* 160+77*2  
    mov es:[di], ax           
    mov es:[di+2], ax        
    mov es:[di+4], ax         
   

    pop cx
    pop ax
    pop di
    pop es
    ret
draw_square endp

;sxediash fidou sthn grammh 16
draw_snake proc
    push es
    push di
    push ax
    push cx
    push bx
   
    mov ax, VIDEO_SEG
    mov es, ax
   
    ; offset gia grammh 16
    mov di, SNAKE_LINE * 160  ; 16 * 160 = 2560
   
    ;ypologismos theshs fidiou
    mov ax, [snake_pos]
    shl ax, 1           ; *2 gia kathe xaraktira+attribute
    add di, ax          ; di deixnei sthn svsth thesi
   
    ;sxediash snake_length 'B'
    mov cl, [snake_len]
    xor ch, ch
    jcxz skip_draw  ;an mhkos=0 tote termatise
   
    mov ax, ATTR_SNAKE * 256 + 'B'
   
draw_loop:
    ;elegxos gia to an to fidi jefeugei apo thn grammh 16
    cmp di, SNAKE_LINE * 160 + 160
    jae reset_to_line_start
   
    ;sxediash
    mov es:[di], ax
    add di, 2
    loop draw_loop
    jmp skip_draw
   
reset_to_line_start:;epistrofh sthn arxh ths grammhs 16
   
    mov di, SNAKE_LINE * 160
    jmp draw_loop
   
skip_draw:
    pop bx
    pop cx
    pop ax
    pop di
    pop es
    ret
draw_snake endp

; katharismos fidiou apo thn grammh 16
clear_snake proc
    push es
    push di
    push ax
    push cx
    push bx
   
    mov ax, VIDEO_SEG
    mov es, ax
   
    ; offset theshs fidiou 
    mov di, SNAKE_LINE * 160  ; 16 * 160 = 2560
   
    ; upologismos theshs fidiou
    mov ax, [snake_pos]
    shl ax, 1
    add di, ax
    ;katharismos snake_len xarakthron
    mov cl, [snake_len]
    xor ch, ch
    jcxz skip_clear
   
    mov ax, 0000h + ' ' ;kenos xarakthras

clear_loop: ; elegxos gia to an to fidi jefeygei apo thn grammh 16
    cmp di, SNAKE_LINE * 160 + 160
    jae reset_clear_to_start
   
    ;diagrafh
    mov es:[di], ax
    add di, 2
    loop clear_loop
    jmp skip_clear
   
reset_clear_to_start:;epistrofh sthn arxh ths grammhs 16
   
    mov di, SNAKE_LINE * 160
    jmp clear_loop
   
skip_clear:
    pop bx
    pop cx
    pop ax
    pop di
    pop es
    ret
clear_snake endp

;elegxos timer tetragonou
check_square proc
    push ax
    push dx
    push bx
   
    mov ah, 00h
    int 1Ah        
   
    mov ax, dx
    sub ax, [last_square]
    cmp ax, 18     ; 18 ticks = ~1 sec
    jb square_done ; an oxi 1 sec tote telos
    ;apothikeush prohgoymenou xrwmatos             
    mov al,[square_color]
    mov [prev_color], al
   
    ;allagh xrwmatos
    cmp al, ATTR_GREEN
    je make_red
   
make_green:
    mov byte ptr [square_color], ATTR_GREEN
    jmp check_growth
   
make_red:
    mov byte ptr [square_color], ATTR_RED
   
check_growth:  ;elegxos an allagei apo prasino se kokkino
   
    mov al, [prev_color]
    cmp al, ATTR_GREEN
    jne no_growth
   
    mov al, [square_color]
    cmp al, ATTR_RED
    jne no_growth
   
    ; dhmiourgia tuxaiou N
    call generate_N
   
    ; aujhsh mikous
    mov al, [snake_len]
    mov bl, [N_value]
    add al, bl
    mov [snake_len], al
   
no_growth:
    ; ananewsh tetragonou
    call draw_square
   
    ; ananewsh timer
    mov [last_square], dx
   
square_done:
    pop bx
    pop dx
    pop ax
    ret
check_square endp

;elegxos timer fidiou
check_snake proc
    push ax
    push dx
   
    mov ah, 00h
    int 1Ah        ; DX = trexwn ticks
   
    mov ax, dx
    sub ax, [last_snake]
    cmp ax, 2      ; 2 ticks = ~110 ms
    jb snake_done
   
    ;diagrafh trexontos fidiou
    call clear_snake
   
    ;kinhsh tou fidiou se olo to mikos ths grammhs 16
    mov ax, [snake_pos]
    inc ax
   
    ;elegxos gia to an ftasei sthn thesi 80 tote na epistrepsei sthn 0
    cmp ax, 80
    jl update_position
    xor ax, ax      ;epistrofh sthn arxh (thesi 0)
update_position:
    mov [snake_pos], ax
   
    ; Sxediash neou fidiou
    call draw_snake
   
    ; ananewsh timer
    mov [last_snake], dx
   
snake_done:
    pop dx
    pop ax
    ret
check_snake endp


generate_N proc ;dhmiourgia N
    push ax
    push bx
    push dx
   
    ; ;Pseudotuxaia gennhtria (0,1,2)
    mov ax, [rand_seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [rand_seed], ax    
    
    ;upoloipo diaireshs me 3
    mov bx, 3
    xor dx, dx
    div bx          ; dx =upoloipo (0-2)
   
    mov [N_value], dl
   
    pop dx
    pop bx
    pop ax
    ret
generate_N endp

end start
