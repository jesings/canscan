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
.endm
.macro restore012
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
    movsd 16(%rsp), %xmm0
    movsd 48(%rsp), %xmm1
    movsd 80(%rsp), %xmm2
    movsd (%rsp), %xmm4
    movsd 8(%rsp), %xmm5
    movsd 32(%rsp), %xmm6
    movsd 40(%rsp), %xmm7
    movsd 64(%rsp), %xmm8
    movsd 72(%rsp), %xmm9
    vsubsd %xmm0, %xmm2, %xmm12
    vsubsd %xmm5, %xmm9, %xmm13
    vdivsd %xmm13, %xmm12, %xmm2
    vsubsd %xmm0, %xmm1, %xmm12
    vsubsd %xmm5, %xmm7, %xmm13
    vdivsd %xmm13, %xmm12, %xmm13

    //?here do from bottom to middle ✓
    //+= (Tx-Bx)/(Ty-By)
    vsubsd %xmm4, %xmm8, %xmm10
    vsubsd %xmm5, %xmm9, %xmm11
    vdivsd %xmm11, %xmm10, %xmm10
    vsubsd %xmm4, %xmm6, %xmm11
    vsubsd %xmm5, %xmm7, %xmm12
    vdivsd %xmm12, %xmm11, %xmm11
    movsd %xmm4, %xmm3
    bottommiddleloop:
    vcomisd %xmm5, %xmm7
    jbe bmiddletoploop
    mov %r15, %rdi
    cvtsd2si %xmm4, %rsi
    cvtsd2si %xmm3, %rdx
    cvtsd2si %xmm5, %rcx
    store012
    call bresenham2
    restore012
    vaddsd one(%rip), %xmm5, %xmm5
    vaddsd %xmm10, %xmm4, %xmm4
    vaddsd %xmm11, %xmm3, %xmm3
    vaddsd %xmm2, %xmm0, %xmm0
    vaddsd %xmm13, %xmm1, %xmm1
    jmp bottommiddleloop
    bmiddletoploop:
    vsubsd %xmm6, %xmm8, %xmm11
    vsubsd %xmm7, %xmm9, %xmm12
    vdivsd %xmm12, %xmm11, %xmm11
    movsd 48(%rsp), %xmm14
    movsd 80(%rsp), %xmm15
    vsubsd %xmm14, %xmm15, %xmm13
    vdivsd %xmm12, %xmm13, %xmm13
    middletoploop:
    vcomisd %xmm7, %xmm9
    jbe enddraw
    mov %r15, %rdi
    cvtsd2si %xmm4, %rsi
    cvtsd2si %xmm6, %rdx
    cvtsd2si %xmm7, %rcx
    store012
    call bresenham2
    restore012
    vaddsd one(%rip), %xmm7, %xmm7
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
