@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -u \
@ RUN:   | Filecheck %s -check-prefix CHECK-UNW
@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -s -sr \
@ RUN:   | Filecheck %s -check-prefix CHECK-REL

@ Check the compact pr0 model

	.syntax unified

	.section	.TEST1
	.globl	func1
	.align	2
	.type	func1,%function
func1:
	.fnstart
	.save	{r11, lr}
	push	{r11, lr}
	.setfp	r11, sp
	mov	r11, sp
	pop	{r11, lr}
	mov	pc, lr
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: func1
@ CHECK-UNW:       Model: Compact (Inline)
@ CHECK-UNW:       PersonalityIndex: 0
@ CHECK-UNW:       Opcodes [
@ CHECK-UNW:         0x9B      ; vsp = r11
@ CHECK-UNW:         0x84 0x80 ; pop {fp, lr}
@ CHECK-UNW:       ]
@ CHECK-UNW:     }
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.TEST1
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .TEST1 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr0 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

	.section	.TEST2
	.globl	func2
	.align	2
	.type	func2,%function
func2:
	.fnstart
	.save	{r11, lr}
	push	{r11, lr}
	pop	{r11, pc}
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: func2
@ CHECK-UNW:       Model: Compact (Inline)
@ CHECK-UNW:       PersonalityIndex: 0
@ CHECK-UNW:       Opcodes [
@ CHECK-UNW:         0x84 0x80 ; pop {fp, lr}
@ CHECK-UNW:         0xB0      ; finish
@ CHECK-UNW:       ]
@ CHECK-UNW:     }
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL:   Section {
@ CHECK-REL:     Name: .rel.ARM.exidx.TEST2
@ CHECK-REL:     Relocations [
@ CHECK-REL:       0x0 R_ARM_PREL31 .TEST2 0x0
@ CHECK-REL:       0x0 R_ARM_NONE __aeabi_unwind_cpp_pr0 0x0
@ CHECK-REL:     ]
@ CHECK-REL:   }

