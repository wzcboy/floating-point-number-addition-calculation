        .data
hello:   .asciiz "Hello\n"   
hh:   .asciiz "\n"
good:   .asciiz "Good:"
total:   .asciiz "Total:"
godie:   .asciiz "Thank you Bye" 

.text
main:
la    	$a0,	hello			
li    	$v0,	4
syscall                #输出hello
#li  $v0, 40           #seed
#addi $a0, $0, 10  
#syscall

move $s1,$0 
move $s0,$0 # for i=0

mainloop:
beq $s0,100,end# i<100
addi $s0,$s0,1 # i++
jal getrandom#a0放第一个浮点数
move $a1,$a0#a1放第二个浮点数
mov.s $f1,$f0
jal getrandom
jal getadd
move $a3,$t0
jal yourfunc#浮点数放在$a0,$a1中，请将计算结果放入$a2中，临时寄存器可以随意修改，其他寄存器改了请恢复
bne $a2,$a3,mainloop
addi $s1,$s1,1
j mainloop

yourfunc:
addi $sp, $sp, -24
sw $s5, 20($sp)
sw $s4, 16($sp)
sw $s3, 12($sp)
sw $s2, 8($sp)
sw $s1, 4($sp)
sw $s0, 0($sp)

#按照IEEE754解析第一个浮点数
srl $s0, $a0, 31         #符号位
sll $s1, $a0, 1		 
srl $s1, $s1, 24	#指数域
sll $s2, $a0, 9         #尾数位
srl $s2, $s2, 9   
ori $s2, $s2, 0x800000   #添加尾数隐藏位

#按照IEEE754解析第二个浮点数
srl $s3, $a1, 31	#符号位
sll $s4, $a1, 1
srl $s4, $s4, 24	#指数域
sll $s5, $a1, 9		#尾数位
srl $s5, $s5, 9
ori $s5, $s5, 0x800000   #添加尾数隐藏位

#进行指数对齐
slt $t0, $s1, $s4
beq $t0, $0, shift_right_second    #若$t0等于0，则说明第二个浮点数的指数较小，需要进行右移对齐
sub $t1, $s4, $s1    
srlv $s2, $s2, $t1     #第二个浮点数的尾数右移 $t1位
move $s1, $s4          #指数赋值
j change_to_complement

shift_right_second:
sub $t1, $s1, $s4
srlv $s5, $s5, $t1	#第二个浮点数的尾数右移 $t1位
move $s4, $s1		#指数赋值

change_to_complement:
#将两个数转换成补码形式，便于运算
beq $s0, $0, label1
nor $s2, $s2, $0     #取反
addi $s2, $s2, 1     #加1

label1:
beq $s3, $0, label2
nor $s5, $s5, $0     #取反
addi $s5, $s5, 1     #加1

label2:
add $t0, $s2, $s5      # $t0 存储着结果的尾数
move $a2, $0          #给最后结果赋初始值0

srl $t1, $t0, 31
beq $t1, $0, label3   #若结果为负数，则取反加1
nor $t0, $t0, $0
addi $t0, $t0, 1
addi $a2, $0, 0x80000000    #符号位赋值1

label3:
#循环查找第一个为1的位置
addi $t3, $0, 32
find_first_position:
beq $t3, $0, out
addi $t3, $t3, -1
srlv $t4, $t0, $t3
bne $t4, 1, find_first_position

#结果进行规格化
out:
sub $t3, $t3, 23
slt $t4, $0, $t3
beq $t4, $0, shift_left_fraction   #$t4=0,说明$t3是负数，即要将尾数左移，指数加上移动的位数
srlv $t0, $t0, $t3    #尾数右移
add $t5, $s1, $t3     #指数加上正的移动位数
j result

shift_left_fraction:
sub $t3, $0, $t3   #将$t3转化为正数
sllv $t0, $t0, $t3    #尾数左移
sub $t5, $s1, $t3     #指数减去移动位数

result:
andi $t0, $t0, 0x7fffff   #将隐藏位去掉
add $a2, $a2, $t0         #尾数域赋值
sll $t2, $t5, 23
or $a2, $a2, $t2       	  #指数域赋值

#恢复寄存器
lw $s0, 0($sp)
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $s3, 12($sp)
lw $s4, 16($sp)
lw $s5, 20($sp)
addi $sp, $sp, 24
jr $ra


getrandom:
li  $v0, 43           #getrandom
addi $a0, $0, 10  # 
syscall
sub $sp,$sp,4
s.s $f0,($sp)
lw $a0,($sp)
addi $a0,$a0,0x2000000
andi $a0,$a0,0xfffff000
sw $a0,($sp)
l.s $f0,($sp)
addi $sp,$sp,4
jr $ra

getadd:
add.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra
getsub:
sub.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra
getmul:
mul.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra
getdiv:
div.s $f0,$f0,$f1
sub $sp,$sp,4
s.s $f0,($sp)
lw $t0,($sp)
addi $sp,$sp,4
jr $ra

end:
la    	$a0,	good			
li    	$v0,	4
syscall
move $a0,$s1		
li    	$v0,	1
syscall
la    	$a0,	hh			
li    	$v0,	4
syscall
la    	$a0,	total			
li    	$v0,	4
syscall
move $a0,$s0		
li    	$v0,	1
syscall
la    	$a0,	hh			
li    	$v0,	4
syscall
la    	$a0,	godie			
li    	$v0,	4
syscall
