.global addtri
.global drawtris
.data
    viewvect: .double 0, 1, 0, 0
.bss
.text
addtri://vertices packed x,y,z in %ymm0, %ymm1, %ymm2
    mov trim(%rip), %rdi
    sub $64, %rsp
    vmovupd %ymm1, (%rsp)
    vmovupd %ymm2, 32(%rsp)
    vpermq $0b01, %ymm0, %ymm1
    vpermq $0b10, %ymm0, %ymm2
    call addpoint
    movsd 0(%rsp), %xmm0
    movsd 8(%rsp), %xmm1
    movsd 16(%rsp), %xmm2
    call addpoint
    movsd 32(%rsp), %xmm0
    movsd 40(%rsp), %xmm1
    movsd 48(%rsp), %xmm2
    call addpoint
    add $64, %rsp
    ret
.macro bresenhamcaller a,b,c,d//calls bresenham from a list of stack offsets in order to draw a line
    mov $0xffffff, %rdi
    movsxd \a(%rsp), %rsi
    movsxd \b(%rsp), %rdx
    movsxd \c(%rsp), %rcx
    movsxd \d(%rsp), %r8
    call bresenham
.endm
.macro store012
    movsd %xmm0, 96(%rsp)
    movsd %xmm1, 104(%rsp)
    movsd %xmm2, 112(%rsp)
    push %r8
    push %r9
    push %r10
.endm
.macro restore012
    pop %r10
    pop %r9
    pop %r8
    movsd 96(%rsp), %xmm0
    movsd 104(%rsp), %xmm1
    movsd 112(%rsp), %xmm2
.endm
drawtri://first point in ymm0, second point in ymm1, third point in ymm2, draws triangle
    push %r15
    rdrand %r15
    sub $136,%rsp
    vmovups %ymm0,(%rsp)
    vmovups %ymm1,32(%rsp)
    vmovups %ymm2,64(%rsp)
    call crossproduct
    call normalize
    vmovups viewvect(%rip), %ymm1
    call dotproduct
    vcomisd zero(%rip), %xmm0
    ja enddraw
    vmovups (%rsp), %ymm0
    vmovups 32(%rsp), %ymm1
    vmovups 64(%rsp), %ymm2
    call bmt
    vmovups %ymm0, (%rsp)
    vmovups %ymm1, 32(%rsp)
    vmovups %ymm2, 64(%rsp)

    movsd (%rsp), %xmm4
    movsd 32(%rsp), %xmm6
    movsd 64(%rsp), %xmm8
    cvtsd2si 8(%rsp), %r8
    cvtsd2si 40(%rsp), %r9
    cvtsd2si 72(%rsp), %r10
    movsd 16(%rsp), %xmm0
    movsd 48(%rsp), %xmm1
    movsd 80(%rsp), %xmm2

    mov %r10, %r11
    sub %r8, %r11
    cvtsi2sd %r11, %xmm13
    vsubsd %xmm4, %xmm8, %xmm10
    vdivsd %xmm13, %xmm10, %xmm10
    vsubsd %xmm0, %xmm2, %xmm12
    vdivsd %xmm13, %xmm12, %xmm2
    mov %r9, %r11
    sub %r8, %r11
    cvtsi2sd %r11, %xmm13
    vsubsd %xmm4, %xmm6, %xmm11
    vdivsd %xmm13, %xmm11, %xmm11
    vsubsd %xmm0, %xmm1, %xmm12
    vdivsd %xmm13, %xmm12, %xmm13
    movsd %xmm4, %xmm3
    movsd %xmm0, %xmm1
 
    //?here do from bottom to middle ✓
    //+= (Tx-Bx)/(Ty-By)
    bottommiddleloop:
    cmp %r8, %r9
    jle bmiddletoploop
    mov %r15, %rdi
    cvtsd2si %xmm4, %rsi
    cvtsd2si %xmm3, %rdx
    mov %r8,  %rcx
    store012
    call bresenham2
    restore012
    inc %r8
    vaddsd %xmm10, %xmm4, %xmm4
    vaddsd %xmm11, %xmm3, %xmm3
    vaddsd %xmm2, %xmm0, %xmm0
    vaddsd %xmm13, %xmm1, %xmm1
    jmp bottommiddleloop
    bmiddletoploop:
    mov %r10, %r11
    sub %r9, %r11
    cvtsi2sd %r11, %xmm12
    vsubsd %xmm6, %xmm8, %xmm11
    vdivsd %xmm12, %xmm11, %xmm11
    movsd 48(%rsp), %xmm14
    movsd %xmm14, %xmm1
    movsd 80(%rsp), %xmm15
    vsubsd %xmm14, %xmm15, %xmm13
    vdivsd %xmm12, %xmm13, %xmm13
    middletoploop:
    cmp %r9, %r10
    jle enddraw
    mov %r15, %rdi
    cvtsd2si %xmm4, %rsi
    cvtsd2si %xmm6, %rdx
    mov %r9, %rcx
    store012
    call bresenham2
    restore012
    inc %r9
    vaddsd %xmm10, %xmm4, %xmm4
    vaddsd %xmm11, %xmm6, %xmm6
    vaddsd %xmm2, %xmm0, %xmm0
    vaddsd %xmm13, %xmm1, %xmm1
    jmp middletoploop
    enddraw:
    add $136, %rsp
    pop %r15
    ret
.macro swapit a,b,c,d,e
    vcomisd %xmm\d, %xmm\c
    jb \e
    vmovups \a(%rsp), %ymm3
    vmovups \b(%rsp), %ymm4
    vmovups %ymm4, \a(%rsp)
    vmovups %ymm3, \b(%rsp)
    movsd %xmm\c, %xmm3
    movsd %xmm\d, %xmm\c
    movsd %xmm3, %xmm\d
    \e:
.endm
bmt: //finds bottom, middle, and top points of all the 3 ymm registers
    sub $136, %rsp
    vmovups %ymm0,(%rsp)
    vmovups %ymm1,32(%rsp)
    vmovups %ymm2,64(%rsp)
    vpermq $0b01, %ymm0, %ymm0
    vpermq $0b01, %ymm1, %ymm1
    vpermq $0b01, %ymm2, %ymm2
    swapit 32,64,1,2,twolower
    swapit 0,32,0,1,onelower
    swapit 32,64,1,2,zerolower
    vmovups (%rsp), %ymm0
    vmovups 32(%rsp), %ymm1
    vmovups 64(%rsp), %ymm2
    add $136, %rsp
    ret
drawtris://draws all triangles in the trimatrix
    mov trim(%rip), %rdi
    mov 24(%rdi), %rax
    mov (%rdi), %rdi
    sub $3, %rax
    trisl:
    mov %rax, %rcx
    sal $2, %rcx
    vmovupd (%rdi,%rcx,8), %ymm0
    add $4, %rcx
    vmovupd (%rdi,%rcx,8), %ymm1
    add $4, %rcx
    vmovupd (%rdi,%rcx,8), %ymm2
    push %rax
    push %rcx
    push %rdi
    call drawtri
    pop %rdi
    pop %rcx
    pop %rax
    sub $3, %rax
    cmp $0, %rax
    jge trisl
    ret
