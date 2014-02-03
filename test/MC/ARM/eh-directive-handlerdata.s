@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -u \
@ RUN:   | FileCheck %s -check-prefix CHECK-UNW
@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -s -sr \
@ RUN:   | FileCheck %s -check-prefix CHECK-REL

@ Check the .handlerdata directive (without .personality directive)

	.syntax unified

@-------------------------------------------------------------------------------
@ TEST1
@-------------------------------------------------------------------------------
	.section	.TEST1
	.globl	func1
	.align	2
	.type	func1,%function
	.fnstart
func1:
	bx	lr
	.handlerdata
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: func1
@ CHECK-UNW:       ExceptionHandlingTable: .ARM.extab.TEST1
@ CHECK-UNW:       TableEntryOffset: 0x0
@ CHECK-UNW:       Model: Compact
@ CHECK-UNW:       PersonalityIndex: 0
@ CHECK-UNW:       Opcodes [
@ CHECK-UNW:         0xB0      ; finish
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
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr0 0x0
@ CHECK-REL:     0x4 R_ARM_PREL31 .ARM.extab.TEST1 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }


@-------------------------------------------------------------------------------
@ TEST2
@-------------------------------------------------------------------------------
	.section	.TEST2
	.globl	func2
	.align	2
	.type	func2,%function
	.fnstart
func2:
@-------------------------------------------------------------------------------
@ Use a lot of unwind opcdes to get __aeabi_unwind_cpp_pr1.
@-------------------------------------------------------------------------------
	.save	{r4, r5, r6, r7, r8, r9, r10, r11, r12}
	push	{r4, r5, r6, r7, r8, r9, r10, r11, r12}
	pop	{r4, r5, r6, r7, r8, r9, r10, r11, r12}
	.pad	#0x240
	sub	sp, sp, #0x240
	add	sp, sp, #0x240
	bx	lr
	.handlerdata
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: func2
@ CHECK-UNW:       ExceptionHandlingTable: .ARM.extab.TEST2
@ CHECK-UNW:       TableEntryOffset: 0x0
@ CHECK-UNW:       Model: Compact
@ CHECK-UNW:       PersonalityIndex: 1
@ CHECK-UNW:       Opcodes [
@ CHECK-UNW:         0xB2 0x0F ; vsp = vsp + 576
@ CHECK-UNW:         0x81 0xFF ; pop {r4, r5, r6, r7, r8, r9, r10, fp, ip}
@ CHECK-UNW:         0xB0      ; finish
@ CHECK-UNW:         0xB0      ; finish
@ CHECK-UNW:       ]
@ CHECK-UNW:     }
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.TEST2
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .TEST2 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr1 0x0
@ CHECK-REL:     0x4 R_ARM_PREL31 .ARM.extab.TEST2 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

