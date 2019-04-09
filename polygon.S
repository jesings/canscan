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
drawtri://first point in ymm0, second point in ymm1, third point in ymm2, draws triangle
    sub $136,%rsp
    vmovups %ymm0,(%rsp)
    vmovups %ymm1,32(%rsp)
    vmovups %ymm2,64(%rsp)
    call crossproduct
    call normalize
    vmovups viewvect(%rip), %ymm1
    call dotproduct
    vcomisd zero(%rip), %xmm0
    jna enddraw
    vmovups (%rsp), %ymm0
    vmovups 32(%rsp), %ymm1
    vmovups 64(%rsp), %ymm2
    vcvtpd2dq %ymm0, %xmm0
    vcvtpd2dq %ymm1, %xmm1
    vcvtpd2dq %ymm2, %xmm2
    movlps %xmm0, (%rsp)
    movlps %xmm1, 8(%rsp)
    movlps %xmm2, 16(%rsp)
    bresenhamcaller 0,4,8,12
    bresenhamcaller 16,20,8,12
    bresenhamcaller 16,20,0,4
    enddraw:
    add $136, %rsp
    ret
.macro swapit a,b,c,d,e
    vcomiss %xmm\d, %xmm\c
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
bmt: //finds bottom, middle, and top points of all the ymm registers
    sub $136, %rsp
    vmovups %ymm0,(%rsp)
    vmovups %ymm1,32(%rsp)
    vmovups %ymm2,64(%rsp)
    vpermq $0b10, %ymm0, %ymm0
    vpermq $0b10, %ymm1, %ymm1
    vpermq $0b10, %ymm2, %ymm2
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
