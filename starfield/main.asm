; Begin code at $7530
org $7530

; System variables
tv_flag     EQU $5c3c   ; TV flags
last_k      EQU $5c08   ; Last pressed key
clr_screen  EQU $0daf   ; ROM routine to clear the screen

; http://www.z80.info/pseudo-random.txt
; seed - http://www.wearmouth.demon.co.uk/sys/frames.htm

; Screen is 256x192

; Star Structure
; X         1 Byte  $0 - $ff
; Y         1 Byte  $0 - $c0
; Speed     1 Byte  $1 - $3
; PrevX
; PrevY
MAX_STARS   EQU 60

start
    xor a
    ld (tv_flag), a
    push bc

    call clear_screen   ; Clear the screen
    call initStars  ; Initialize the number of stars defined in MAX_STARS

main_start
    ld hl, STARS    ; Points to X
    ld c, MAX_STARS

main
; CLEAR THE LAST POSITION
    ld de, $3   ; Skip to PrevX
    adc hl, de

    ld a, (hl)
    ld d, a     ; Save PrevX to D
    inc hl      ; PrevY

    ld a, (hl)
    ld e, a     ; Save PrevY to E

    push bc
    push hl
    call get_screen_address
    ; Video RAM address for those X,Y is now in HL and the bit needed
    ; to be set in that address value is in A
    call clear_pixel    ; Uses those values clears the pixel
    pop hl

    ld bc, $4   ; Go back to X
    sbc hl, bc

    pop bc
; WRITES THE PIXEL
    ld a, (hl)  ; HL points to X
    ld d, a     ; Save X to D
    inc hl      ; Y

    ld a, (hl)
    ld e, a     ; Save Y to E

    push bc
    push hl
    call get_screen_address
    ; Video RAM address for those X,Y is now in HL and the bit needed
    ; to be set in that address value is in A
    call write_pixel    ; Uses those values and writes the pixel
    pop hl

    ld bc, $4   ; Jump 4 positions - Next star
    adc hl, bc

    pop bc

    dec c       ; Decrement counter
    jr nz, main ; Repeat if not zero

    call increment_x    ; Increment X position in each star
    jr main_start   ; Do it all over again

    pop bc
    ret

PROC
; D = valor minimo
; E = valor maximo
Seed dw  $fa

get_rnd
    push bc ; Guarda o valor de RET na stack

get_rnd_loop
    ld a, (Seed)
    ld b, a 

    rrca ; multiply by 32
    rrca
    rrca
    xor 0x1f

    add a, b
    sbc a, 255 ; carry

    ld (Seed), a

    ld h, a ; Save A to H

    ld a, e ; Valor maximo em A
    cp h

    jr z, get_rnd_ret   ; É igual
    jr c, get_rnd_loop ; Se for menor

    ld a, d
    cp h

    jr z, get_rnd_ret
    jr c, get_rnd_ret

    jr get_rnd_loop

get_rnd_ret
    ld a, h
    pop bc  ; Tira o valor de RET da stack
    ret
ENDP

PROC
; Initialize stars X and Y with "random" values
initStars
    push bc
    ld d, MAX_STARS ; Number of stars to process
    ld hl, STARS    ; HL points to X of first start

initStars_loop
    push de

    push hl
    ld d, 0
    ld e, 250
    call get_rnd    ; Get a random value <= 255
    pop hl

    ld (hl), a      ; Set X to random value

    inc hl          ; points to Y

    push hl
    ld d, 0
    ld e, 191
    call get_rnd    ; Get a random value <= 191
    pop hl

    ld (hl), a      ; Set Y to random value

    inc hl          ; points to Speed

    push hl
    call getRandomSpeed ; Get a random value for Speed | 1 - 4
    pop hl

    ;push hl
    ;ld d, 1
    ;ld e, 4
    ;call get_rnd
    ;pop hl

    ld (hl), a      ; Set Speed to random value

    ld bc, $3       ; Jump to next star
    adc hl, bc      ; Skip PrevX and PrevY

    pop de    
    dec d           ; Decrement counter
    jr nz, initStars_loop   ; If not zero, do it again

    pop bc
    ret
ENDP

PROC
; Gets a value a from a list of pre-calculated values
; Returns to begin after 0 is found | TODO: change this
getRandomSpeed
    push hl
getRandomSpeed_loop    
    ld hl, (speedrandpos)
    ld a, (hl)
    cp $0
    jr z, getRandomSpeed_reset
    inc hl
    ld (speedrandpos), hl
    pop hl
    ret
getRandomSpeed_reset
    ld hl, speedranddata
    ld (speedrandpos), hl
    jr getRandomSpeed_loop
ENDP

PROC
; Increment X
increment_x
    push bc
    ld hl, STARS
    ld c, MAX_STARS
increment_x_loop
; First lets copy current position to previous position
    ld d, (hl)  ; Save current X to D
    inc hl      ; points to Y
    ld e, (hl)  ; Save current Y to E
    
    inc hl      ; points to Speed
    inc hl      ; points to PrevX
    ld (hl), d  ; Save X
    inc hl      ; PrevY
    ld (hl), e  ; Save Y
    
    ld de, $4
    sbc hl, de  ; Go back to X

    ld a, (hl)  ; Is X at $FF - end of screen
    cp $ff
    jr z, increment_x_zero  ; Yes, lets reset

; Increments X position by speed value
; X = X + Y

    inc hl      ; points to Y
    inc hl      ; points to Speed

    ld b, (hl)  ; Read speed to B

    dec hl      ; Back to Y
    dec hl      ; Back to X

    add a, b    ; X = X + Speed
    jr c, increment_x_zero ; If carry is set, it passed $ff, lets reset

increment_x_update
; Saves to X the value in A
    ld (hl), a  ; Save X with the value in A

    ld de, $5   ; Skip 5 bytes to the next star
    adc hl, de

    dec c       ; Decrement counter
    jr nz, increment_x_loop ; If not zero, do it again

    pop bc
    ret

increment_x_zero
; Sets X to 0 and Y and Speed to random values
    push bc
    inc hl      ; point to Y

    push hl
    ld d, 0
    ld e, 191
    call get_rnd    ; Get a random value below 191
    pop hl

    ld (hl), a  ; Set Y = getRandomY

    inc hl      ; point to speed

    push hl
    call getRandomSpeed ; Get a random Speed value
    pop hl

    ld (hl), a  ; Set Speed = getRandomSpeed

    ld de, $2
    sbc hl, de  ; Get back to X position

    ld a, $0    ; X = 0
    pop bc
    jr increment_x_update
ENDP

PROC
; Video Ram Address in HL
; Pixel to write in A
write_pixel
    push bc
    ld b, a
    ld c, $0
    scf
write_pixel_loop
    ld a, c
    rra
    ld c, a
    ld a, b
    jr z, write_pixel_do_it
    dec b
    jr write_pixel_loop
write_pixel_do_it
    ld a, (hl)
    or c
    ld (hl), a
    pop bc
    ret
ENDP

PROC
; Video Ram Address in HL
; Pixel to write in A
clear_pixel
    push bc
    ld b, a
    ld c, $ff
    and a   ; reset carry
clear_pixel_loop
    ld a, c
    rra
    ld c, a
    ld a, b
    jr z, clear_pixel_do_it
    dec b
    jr clear_pixel_loop
clear_pixel_do_it
    ld a, (hl)
    and c
    ld (hl), a
    pop bc
    ret
ENDP

PROC
; Calculate the high byte of the screen address and store in H reg.
; On Entry: D reg = X coord,  E reg = Y coord
; On Exit: HL = screen address, A = pixel postion
get_screen_address
    ld a,e
    and %00000111
    ld h,a
    ld a,e
    rra
    rra
    rra
    and %00011000
    or h
    or %01000000
    ld h,a
; Calculate the low byte of the screen address and store in L reg.
    ld a,d
    rra
    rra
    rra
    and %00011111
    ld l,a
    ld a,e
    rla
    rla
    and %11100000
    or l
    ld l,a
; Calculate pixel position and store in A reg.
    ld a,d
    and %00000111
    ret
ENDP

PROC
INCLUDE "clear.asm"
ENDP

STARS
    REPT MAX_STARS
        DB $0,$0, $0, $0,$0
    ENDM

INCLUDE "randomvalues.asm"

END start