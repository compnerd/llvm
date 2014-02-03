@ RUN: llvm-mc -triple armv7-eabi -filetype obj -o - %s | llvm-readobj -u \
@ RUN:   | FileCheck %s -check-prefix CHECK-UNW
@ RUN: llvm-mc -triple armv7-eabi -filetype obj -o - %s | llvm-readobj -s -sr \
@ RUN:   | FileCheck %s -check-prefix CHECK-REL

	.syntax unified
	.thumb

	.section .duplicate

	.global duplicate
	.type duplicate,%function
duplicate:
	.fnstart
	.setfp sp, sp, #8
	add sp, sp, #8
	.movsp r11
	mov r11, sp
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: duplicate
@ CHECK-UNW:       Model: Compact (Inline)
@ CHECK-UNW:       PersonalityIndex: 0
@ CHECK-UNW:       Opcodes [
@ CHECK-UNW:         0x9B      ; vsp = r11
@ CHECK-UNW:         0x9B      ; vsp = r11
@ CHECK-UNW:         0xB0      ; finish
@ CHECK-UNW:       ]
@ CHECK-UNW:     }
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.duplicate
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .duplicate 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr0 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }


	.section .squash

	.global squash
	.type squash,%function
squash:
	.fnstart
	.movsp ip
	mov ip, sp
	.save {fp, ip, lr}
	stmfd sp!, {fp, ip, lr}
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     Entry {
@ CHECK-UNW:       FunctionName: squash
@ CHECK-UNW:       Model: Compact (Inline)
@ CHECK-UNW:       PersonalityIndex: 0
@ CHECK-UNW:       Opcodes [
@ CHECK-UNW:         0x85 0x80 ; pop {fp, ip, lr}
@ CHECK-UNW:         0x9C      ; vsp = r12
@ CHECK-UNW:       ]
@ CHECK-UNW:     }
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.squash
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .squash 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr0 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

