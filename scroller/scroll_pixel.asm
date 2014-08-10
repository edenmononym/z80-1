; Rotina de scroll de texto da direita para a esquerda pixel a pixel
scrolla
    ld hl, videoAddr       ; Endere�o de Memoria Video a ser manipulado
    ld c, 8                ; Numero de vezes que a rotina vai correr
                           ; 8 � o numero de linhas de pixeis a scrollar

; Loop1     
scrolla_0
    ld (tmpScroll1), hl    ; Guarda o valor de HL em tmp1
    call scrolla_1         ; Scrolla
    ld hl, (tmpScroll1)    ; Le o valor de tmp1 para HL
    
    inc h                  ; Incrementa H, mas como estamos a trabalhar com um
                           ; endere�o de 16bits, na realidade vai adicionar 
                           ; $100 a HL
                           ; Isto vai fazer com que a segunda rotina seja
                           ; chamada com os seguintes endere�os em tmp1 
                           ; videoAddr, videoAddr+$100 videoAddr+$200,
                           ; ..., videoAddr+$700
                           
    dec c                  ; Decrementa o contador C 
    jr nz, scrolla_0       ; Se C != 0 corre novamente o Loop1
    ret

; Segunda rotina 
scrolla_1
    ld hl, (tmpScroll1)    ; Le o argumento tmp1 para HL
    
    ; Soma $1F ao endere�o para come�ar no fim da linha, tudo � direita
    push bc
    ;ld bc, 1Fh
    ld bc, 20h
    adc hl, bc

    ; Guarda o endere�o do fim da linha em (ultimoaddr)
    ld b, h
    ld c, l
    ld (ultimoaddr), bc
    pop bc

    ld b, 1Fh              ; Numero de vezes que a rotina vai correr
    ld b, 21h              ; Numero de vezes que a rotina vai correr
    

; Loop2
scrolla_2
    ld a, (hl)             
    rla
    ld (hl), a
    dec hl
    djnz scrolla_2         
   
    ld hl, (ultimoaddr)
    ld a, (hl)
    rra
    ld (hl), a
    ret
