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
syscall                #���hello
#li  $v0, 40           #seed
#addi $a0, $0, 10  
#syscall

move $s1,$0 
move $s0,$0 # for i=0

mainloop:
beq $s0,100,end# i<100
addi $s0,$s0,1 # i++
jal getrandom#a0�ŵ�һ��������
move $a1,$a0#a1�ŵڶ���������
mov.s $f1,$f0
jal getrandom
jal getadd#######################  ��ѡһ�� getadd  getsub  getmul getdiv ##############################
move $a3,$t0
jal yourfunc#����������$a0,$a1�У��뽫����������$a2�У���ʱ�Ĵ������������޸ģ������Ĵ���������ָ�
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

#����IEEE754������һ��������
srl $s0, $a0, 31         #����λ
sll $s1, $a0, 1		 
srl $s1, $s1, 24	#ָ����
sll $s2, $a0, 9         #β��λ
srl $s2, $s2, 9   
ori $s2, $s2, 0x800000   #���β������λ

#����IEEE754�����ڶ���������
srl $s3, $a1, 31	#����λ
sll $s4, $a1, 1
srl $s4, $s4, 24	#ָ����
sll $s5, $a1, 9		#β��λ
srl $s5, $s5, 9
ori $s5, $s5, 0x800000   #���β������λ

#����ָ������
slt $t0, $s1, $s4
beq $t0, $0, shift_right_second    #��$t0����0����˵���ڶ�����������ָ����С����Ҫ�������ƶ���
sub $t1, $s4, $s1    
srlv $s2, $s2, $t1     #�ڶ�����������β������ $t1λ
move $s1, $s4          #ָ����ֵ
j change_to_complement

shift_right_second:
sub $t1, $s1, $s4
srlv $s5, $s5, $t1	#�ڶ�����������β������ $t1λ
move $s4, $s1		#ָ����ֵ

change_to_complement:
#��������ת���ɲ�����ʽ����������
beq $s0, $0, label1
nor $s2, $s2, $0     #ȡ��
addi $s2, $s2, 1     #��1

label1:
beq $s3, $0, label2
nor $s5, $s5, $0     #ȡ��
addi $s5, $s5, 1     #��1

label2:
add $t0, $s2, $s5      # $t0 �洢�Ž����β��
move $a2, $0          #�����������ʼֵ0

srl $t1, $t0, 31
beq $t1, $0, label3   #�����Ϊ��������ȡ����1
nor $t0, $t0, $0
addi $t0, $t0, 1
addi $a2, $0, 0x80000000    #����λ��ֵ1

label3:
#ѭ�����ҵ�һ��Ϊ1��λ��
addi $t3, $0, 32
find_first_position:
beq $t3, $0, out
addi $t3, $t3, -1
srlv $t4, $t0, $t3
bne $t4, 1, find_first_position

#������й��
out:
sub $t3, $t3, 23
slt $t4, $0, $t3
beq $t4, $0, shift_left_fraction   #$t4=0,˵��$t3�Ǹ�������Ҫ��β�����ƣ�ָ�������ƶ���λ��
srlv $t0, $t0, $t3    #β������
add $t5, $s1, $t3     #ָ�����������ƶ�λ��
j result

shift_left_fraction:
sub $t3, $0, $t3   #��$t3ת��Ϊ����
sllv $t0, $t0, $t3    #β������
sub $t5, $s1, $t3     #ָ����ȥ�ƶ�λ��

result:
andi $t0, $t0, 0x7fffff   #������λȥ��
add $a2, $a2, $t0         #β����ֵ
sll $t2, $t5, 23
or $a2, $a2, $t2       	  #ָ����ֵ

#�ָ��Ĵ���
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
