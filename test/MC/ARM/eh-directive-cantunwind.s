@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -u \
@ RUN:   | FileCheck %s -check-prefix CHECK-UNW
@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -r \
@ RUN:   | FileCheck %s -check-prefix CHECK-REL

@ Check the .cantunwind directive

@ When a function contains a .cantunwind directive, we should create an entry
@ in corresponding .ARM.exidx, and its second word should be EXIDX_CANTUNWIND.

	.syntax	unified

	.text
	.globl	func1
	.align	2
	.type	func1,%function
	.fnstart
func1:
	bx	lr
	.cantunwind
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: func1
@ CHECK-UNW:       Model: CantUnwind
@ CHECK-UNW:     }
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Relocations [
@ CHECK-REL:   Section ({{[0-9]+}}) .rel.ARM.exidx {
@ CHECK-REL:     0x0 R_ARM_PREL31 .text 0x0
@ CHECK-REL:   }
@ CHECK-REL: ]

