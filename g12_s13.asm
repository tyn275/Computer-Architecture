.eqv MONITOR_SCREEN 0x10000000 #Bitmap Screen Adrress
.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xFFFF0014
.data
msg1: .asciz "Luot choi thu: "
msg2: .asciz "\n"
msg3: .asciz "Ban da thua"
msg4: .asciz "Ban da chien thang"
msg5: .asciz "Den luot ban nhap"
maximum: .word 100 #Toi da 100 luot choi
randomOrder: .space 400 #1 word = 4 bytes = 100 luot choi
currentIndex: .word 0 #Chi so phan tu dang to mau den
press_count: .word 0 #So lan nhan phim
color_count: .word 0
turn: .word 1 #Turn play
color: .word 0x0000FF00, 0x00FF0000, 0x000000FF, 0x00ffd700
lightclr: .word 0x0000ffaa, 0x00F5B7B1, 0x0087CEEB, 0x00FFF8DC
.text
main:

#To san 4 o mau goc cho man hinh
li a0, MONITOR_SCREEN 
li t0, 0x0000FF00
sw t0, 0(a0)
li t0, 0x00FF0000
sw t0, 4(a0)
li t0, 0x000000FF
sw t0, 8(a0)
li t0, 0x00ffd700
sw t0, 12(a0)

notice:
#Luot choi max -> Dung chuong trinh -> Thang
la a0, turn
lw a1, 0(a0)

la a0, maximum
lw a2, 0(a0)

blt a2, a1, win

#In ra thông báo đến lượt tiếp theo
la a0, msg1
li a7, 4
ecall

la t0, turn
lw a0, 0(t0)
li a7, 1
ecall

la a0, msg2
li a7, 4
ecall

#Ngu 0,1s -> Dung lai mot chut giua cac luot choi
li a0, 100
li a7, 32
ecall

#Bat dau random o vuong duoc to mau
random:
li a0, 0
li a1, 4
li a7, 42
ecall 
mv t6, a0 #t6 = [0,3]
addi t6, t6, 1 #t6 = [1,4] -> Giu nguyen de ghi gia tri vao mảng randomOrder

#Ghi gia tri random duoc vao mang randomOrder
#Đọc ra giá trị currentIndex hiện tại là gì 
la t0, currentIndex
lw t1, 0(t0) #currentIndex = ?
slli t2, t1, 2 #a3 = 4*currentIndex

la a1, randomOrder #address(randomOrder[0])
add a1, a1, t2 #a1 = address(randomOrder[currentIndex])

sw t6, 0(a1) #randomOrder[currentIndex] = randomNumber

#Set currentIndex = 0 de doc lai tu dau mang
la t0, currentIndex
sw zero, 0(t0)

color_loop:
#Bat dau xet tung lan to mau
la t0, turn
lw t1, 0(t0)

la t2, color_count
lw t3, 0(t2)

#Tô màu xong -> cho phép ngắt từ keypad
beq t1, t3, enable_keyboard

lightclr_paint:
#Đọc currentIndex
la t0, currentIndex
lw t1, 0(t0) #currentIndex = ?
slli t1, t1, 2 #4*currentIndex
la t0, randomOrder #address(randomOrder[0])
add t0, t0, t1 #address(randomOrder[currentIndex])
lw t5, 0(t0) #t5 = randomOrder[currentIndex]
addi t5, t5, -1 #[0,3]
slli t5, t5, 2 #t5 = 4*randomNumber
la t0, lightclr #t0 = address(lightclr[0])
add t0, t0, t5 #t0 = address(lightclr[randomNumber])
lw t1, 0(t0) #t1 = lightclr[randomNumber] -> Mau can to

li t0, MONITOR_SCREEN
add t0, t0, t5 #t0 = address(bitmap[randomNumber])
sw t1, 0(t0) #To mau lay duoc vao o bitmap tuong ung

#Ngu 1s
li a0, 1000
li a7, 32
ecall

#To lai mau goc
restore_color:
la t0, color #t0 = address(color[0])
add t0, t0, t5 #t0 = address(color[randomNumber])
lw t1, 0(t0) #t1 = color[randomNumber] -> Mau can to

li t0, MONITOR_SCREEN
add t0, t0, t5 #t0 = address(bitmap[randomNumber])
sw t1, 0(t0) #To mau lay duoc vao o bitmap tuong ung

#Tang chi so color_count
la t0, color_count
lw t1, 0(t0) #color_count = ?
addi t1, t1, 1 #color_count++
sw t1, 0(t0)

#Tang chi so currentIndex
la t0, currentIndex
lw t1, 0(t0) #currentIndex = ?
addi t1, t1, 1 #currentIndex++
sw t1, 0(t0)

j color_loop

#Sau khi to du so o vuong moi cho phep ngat tu keyboard
enable_keyboard:

#Reset currentIndex, color_count = 0
la t0, currentIndex
sw zero, 0(t0)

la t0, color_count
sw zero, 0(t0)

#In ra thong bao da nhap tu keyboard (chi de kiem tra chuong trinh chay dung khong)
la a0, msg5
li a7, 4
ecall

# Load the interrupt service routine address to the UTVEC register
la t0, handler
csrrs zero, utvec, t0
# Set the UEIE (User External Interrupt Enable) bit in UIE register
li t1, 0x100
csrrs zero, uie, t1 # uie - ueie bit (bit 8) 
# Set the UIE (User Interrupt Enable) bit in USTATUS register
csrrsi zero, ustatus, 1 # ustatus - enable uie (bit 0)
# Enable the interrupt of Digital Lab Sim
li t1, IN_ADDRESS_HEXA_KEYBOARD
li t3, 0x80 # bit 7 = 1 to enable interrupt 
sb t3, 0(t1)

#Cho nguoi choi lan luot nhap vao chuoi so
loop:
nop
nop
nop
j loop

#In ra thong bao chien thang khi da choi du luot max
win: 
la a0, msg4
li a7, 4
ecall
j end_main

#In ra thong bao thua 
lose:
la a0, msg2
li a7, 4
ecall

la a0, msg3
li a7, 4
ecall

#Ket thuc chuong trinh
end_main:
li a7, 10
ecall

# -----------------------------------------------------------------
# Interrupt service routine
# -----------------------------------------------------------------

handler:
# -----------------------------------------------------------------
# Keyboard_interrupt
# -----------------------------------------------------------------
keyboard_interrupt:

get_key_code:
#Quet hang 1: 
li t1, IN_ADDRESS_HEXA_KEYBOARD
li t2, 0x81
sb t2, 0(t1)
li t1, OUT_ADDRESS_HEXA_KEYBOARD
lbu a0, 0(t1)

li t3, 0x11      #phim 0
li t6, 1
beq a0, t3, interrupt

li t3, 0x21      #phim 1
li t6, 2
beq a0, t3, interrupt

#Quet hang 2: 
li t1, IN_ADDRESS_HEXA_KEYBOARD
li t2, 0x82 
sb t2, 0(t1)
li t1, OUT_ADDRESS_HEXA_KEYBOARD
lbu a0, 0(t1)

li t3, 0x12    #phim 4
li t6, 3
beq a0, t3, interrupt

li t3, 0x22    #phim 5
li t6, 4
beq a0, t3, interrupt

#Neu khong phai phim 1-4, bo qua
j end_handler

interrupt:
#So sanh so duoc nhan voi so duoc luu trong randomOrder
la t0, currentIndex
lw t1, 0(t0) #currentIndex = ?
mv s11, t1 
slli s11, s11, 2 #s11 = 4*currentIndex
la t2, randomOrder #address(randomOrder[0])
add t2, t2, s11 #randomOrder[currentIndex]
lw t3, 0(t2)

#Nhap sai -> Thua
bne t3, t6, lose

update:
la t0, press_count
lw t1, 0(t0) #press_count = ?
addi t1, t1, 1 #press_count++
sw t1, 0(t0)

la t0, turn
lw t2, 0(t0)         # Đọc turn
#Nhap du chuoi, bat dau luot choi tiep theo
beq t1, t2, reset_game 
    
la t0, currentIndex
lw t1, 0(t0) #currentIndex = ?
addi t1, t1, 1 #currentIndex++
sw t1, 0(t0)

j end_handler

reset_game: 
#In ra dau cach
la a0, msg2
li a7, 4
ecall

#Reset cac bien
la t0, turn
lw t2, 0(t0)
addi t2, t2, 1 #turn++
sw t2, 0(t0)

la t0, currentIndex
lw t1, 0(t0)
addi t1, t1, 1
sw t1, 0(t0)
#sw zero, 0(t0) #currentIndex = 0

la t0, press_count
sw zero, 0(t0) #press_count = 0

#Tat cho phep ngat tu keyboard
li t1, IN_ADDRESS_HEXA_KEYBOARD
li t3, 0x00 # bit 7 = 1 to enable interrupt 
sb t3, 0(t1)

j notice

end_handler:
uret
