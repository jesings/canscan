.global bresenham
.global bresenham2
.data
    colorR: .byte 255
    colorG: .byte 255 
    colorB: .byte 255
    .align 8
    x: .quad 0
    y: .quad 0
.bss
    x0: .quad 0
    x1: .quad 0
    y0: .quad 0
    y1: .quad 0
.text
bresenham: //something like this: bresenham(int color,int x0,int x1, int y0, int y1, double z0, double z1), color is a hex value
#process arguments
    push %rbx
    mov %rdi, %rax
    movb %al, colorB(%rip)
    shr $8, %rax
    movb %al, colorG(%rip)
    shr $8, %rax
    movb %al, colorR(%rip)
    mov %rsi, x0(%rip)
    neg %rdx
    add $511, %rdx
    mov %rdx, y0(%rip)
    mov %rcx, x1(%rip)
    neg %r8
    add $511, %r8
    mov %r8, y1(%rip)
#handle wrong direction coords
    mov x0(%rip), %rcx
    cmp x1(%rip), %rcx
    jl noswap
    xchg x1(%rip), %rcx
    mov %rcx, x0(%rip)
    mov y0(%rip), %rcx
    xchg y1(%rip), %rcx
    mov %rcx, y0(%rip)
    movsd %xmm0, %xmm2
    movsd %xmm1, %xmm0
    movsd %xmm2, %xmm1
    noswap:
    movsd %xmm0, %xmm2
    mov x1(%rip), %r10
    sub x0(%rip), %r10
    cvtsi2sd %r10, %xmm3
    vsubsd %xmm0, %xmm1, %xmm2
    vdivsd %xmm2, %xmm3, %xmm2
#assign x and y
    movq x0(%rip), %r8
    movq %r8, x(%rip) //x = x-naught
    movq y0(%rip), %r8
    movq %r8, y(%rip) //y = y-naught
#assign a b and d
    movq y0(%rip), %rax
    subq y1(%rip), %rax//A = y-naught - y-one these needed to be negated for some reason...?
    movq x1(%rip), %rbx
    subq x0(%rip), %rbx//B = x-one - x-naught
#differentiate between octants
    cmp $0, %rax
    jl topq
    bottomq:
    cmp %rax, %rbx
    jg o7
    jmp o8
    topq:
    mov %rax, %rcx
    neg %rcx
    cmp %rcx,%rbx
    jg o1
    jmp o2
#A is rax, B is rbx, rdx is d (twice d actually)
o1:
    movq %rax,%rdx //d=2a+b
    salq %rdx
    addq %rbx, %rdx
    salq %rax
    salq %rbx //double a and b
    start1:
    mov x1(%rip), %rcx
    cmpq x(%rip), %rcx
    jl end
    call plot
    cmp $0,%rdx#check if y needs to be incremented
    jg ifninc1
    incq y(%rip)
    add %rbx, %rdx
    ifninc1:
    incq x(%rip)
    add %rax, %rdx
    jmp start1
o2:
    neg %rax
    neg %rbx
    movq %rbx,%rdx //d=2b+a
    salq %rdx
    addq %rax, %rdx
    salq %rax
    salq %rbx //double a and b
    start2:
    mov y1(%rip), %rcx
    cmpq y(%rip), %rcx
    jl end
    call plot
    cmp $0,%rdx#check if y needs to be incremented
    jg ifninc2
    incq x(%rip)
    add %rax, %rdx
    ifninc2:
    incq y(%rip)
    add %rbx, %rdx
    jmp start2
o7:
    movq %rax,%rdx //d=2b-a
    salq %rdx
    subq %rbx, %rdx
    salq %rax
    salq %rbx //double a and b
    start7:
    mov x1(%rip), %rcx
    cmpq x(%rip), %rcx
    jl end
    call plot
    cmp $0,%rdx#check if y needs to be decremented
    jl ifninc7
    decq y(%rip)
    sub %rbx, %rdx
    ifninc7:
    incq x(%rip)
    add %rax, %rdx
    jmp start7
o8:
    movq %rax,%rdx //d=2a-b
    salq %rdx
    subq %rbx, %rdx
    salq %rax
    salq %rbx //double a and b
    start8:
    mov y1(%rip), %rcx
    cmpq y(%rip), %rcx
    jg end
    call plot
    cmp $0,%rdx#check if y needs to be incremented
    jg ifninc8
    incq x(%rip)
    add %rax, %rdx
    ifninc8:
    decq y(%rip)
    sub %rbx, %rdx
    jmp start8
    end:
    pop %rbx
    ret
plot:
#plot x,y,z!!!
    cmpq $512, x(%rip)
    jae pltdone
    cmpq $512, y(%rip)
    jae pltdone
    mov y(%rip), %r8//this will be the index
    sal $9, %r8
    add x(%rip), %r8
    mov %r8, %r9
    lea zbuffer(%rip), %rcx
    comisd (%rcx, %r9,8), %xmm0
    jb pltdone
    shl $2, %r8
    lea data(%rip),%rcx
    add %rcx, %r8
//color the pixel :)
    movzbw colorR(%rip), %cx
    movb %cl, 0(%r8)
    movzbw colorG(%rip), %cx
    movb %cl, 1(%r8)
    movzbw colorB(%rip), %cx
    movb %cl, 2(%r8)
    lea zbuffer(%rip),%rcx
    movsd %xmm0, (%rcx, %r9,8)
//Plotting done 
    pltdone:
    addsd %xmm2, %xmm0
    ret
bresenham2: //something like this: bresenham(int color,int x0,int x1, int y, double z0, double z1), color is a hex value
    neg %rcx
    add $511, %rcx
    cmp $511, %rcx
    ja endb2
    cmp %rsi, %rdx
    jge noswap2
    xchg %rsi, %rdx
    sub $8, %rsp
    movsd %xmm0, (%rsp)
    movsd %xmm1, %xmm0
    movsd (%rsp), %xmm1
    add $8, %rsp
    noswap2:
    mov %edi, %eax//put color into rax register for stosd
    lea data(%rip), %rdi//find proper destination
    imul $512,%rcx//get y coord offset
    add %rsi, %rcx
    mov %rdx, %r8
    sub %rsi, %r8
    //inc %r8
    cvtsi2sd %r8, %xmm2
    vsubsd %xmm0, %xmm1, %xmm1
    vdivsd %xmm2, %xmm1, %xmm1
    lea zbuffer(%rip), %r9
    startb2:
    cmp %rsi, %rdx
    jl endb2
    cmp $511, %rsi
    jg endb2
    cmp $0, %rsi
    jl oof
    vcomisd (%r9,%rcx,8),%xmm0
    jna oof
    vmovsd %xmm0, (%r9,%rcx,8)
    mov %eax, (%rdi,%rcx,4)
    oof:
    inc %rcx
    inc %rsi
    vaddsd %xmm1, %xmm0, %xmm0
    jmp startb2
    endb2:
    ret
