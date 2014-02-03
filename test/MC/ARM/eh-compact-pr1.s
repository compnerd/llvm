@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -u \
@ RUN:   | FileCheck %s -check-prefix CHECK-UNW
@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -s -sr \
@ RUN:   | FileCheck %s -check-prefix CHECK-REL

@ Check the compact pr1 model

	.syntax unified

	.section .TEST1
	.globl	func1
	.align	2
	.type	func1,%function
func1:
	.fnstart
	.save	{r4, r5, r11, lr}
	push	{r4, r5, r11, lr}
	add	r0, r1, r0
	.setfp	r11, sp, #8
	add	r11, sp, #8
	pop	{r4, r5, r11, pc}
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: func1
@ CHECK-UNW:       ExceptionHandlingTable: .ARM.extab.TEST1
@ CHECK-UNW:       TableEntryOffset: 0x0
@ CHECK-UNW:       Model: Compact
@ CHECK-UNW:       PersonalityIndex: 1
@ CHECK-UNW:       Opcodes [
@ CHECK-UNW:         0x9B      ; vsp = r11
@ CHECK-UNW:         0x41      ; vsp = vsp - 8
@ CHECK-UNW:         0x84 0x83 ; pop {r4, r5, fp, lr}
@ CHECK-UNW:         0xB0      ; finish
@ CHECK-UNW:         0xB0      ; finish
@ CHECK-UNW:       ]
@ CHECK-UNW:     }
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.TEST1
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .TEST1 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr1 0x0
@ CHECK-REL:     0x4 R_ARM_PREL31 .ARM.extab.TEST1 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

