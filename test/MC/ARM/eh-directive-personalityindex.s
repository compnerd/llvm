@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -u \
@ RUN:   | FileCheck %s -check-prefix CHECK-UNW
@ RUN: llvm-mc -triple armv7-eabi -filetype obj %s | llvm-readobj -s -sr \
@ RUN:   | FileCheck %s -check-prefix CHECK-REL

	.syntax unified
	.thumb


	.section .pr0

	.global pr0
	.type pr0,%function
	.thumb_func
pr0:
	.fnstart
	.personalityindex 0
	bx lr
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   SectionName: .ARM.exidx.pr0
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     FunctionAddress: 0x0
@ CHECK-UNW:     Model: Compact (Inline)
@ CHECK-UNW:     PersonalityIndex: 0
@ CHECK-UNW:     Opcodes [
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:     ]
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.pr0
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .pr0 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr0 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

	.section .pr0.nontrivial

	.global pr0_nontrivial
	.type pr0_nontrivial,%function
	.thumb_func
pr0_nontrivial:
	.fnstart
	.personalityindex 0
	.pad #0x10
	sub sp, sp, #0x10
	add sp, sp, #0x10
	bx lr
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   SectionName: .ARM.exidx.pr0.nontrivial
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     FunctionAddress: 0x0
@ CHECK-UNW:     Model: Compact (Inline)
@ CHECK-UNW:     PersonalityIndex: 0
@ CHECK-UNW:     Opcodes [
@ CHECK-UNW:       0x03      ; vsp = vsp + 16
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:     ]
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.pr0.nontrivial
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .pr0.nontrivial 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr0 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

	.section .pr1

	.global pr1
	.type pr1,%function
	.thumb_func
pr1:
	.fnstart
	.personalityindex 1
	bx lr
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   SectionName: .ARM.exidx.pr1
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     FunctionAddress: 0x0
@ CHECK-UNW:     ExceptionHandlingTable: .ARM.extab.pr1
@ CHECK-UNW:     TableEntryOffset: 0x0
@ CHECK-UNW:     Model: Compact
@ CHECK-UNW:     PersonalityIndex: 1
@ CHECK-UNW:     Opcodes [
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:     ]
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.pr1
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .pr1 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr1 0x0
@ CHECK-REL:     0x4 R_ARM_PREL31 .ARM.extab.pr1 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

	.section .pr1.nontrivial

	.global pr1_nontrivial
	.type pr1_nontrivial,%function
	.thumb_func
pr1_nontrivial:
	.fnstart
	.personalityindex 1
	.pad #0x10
	sub sp, sp, #0x10
	add sp, sp, #0x10
	bx lr
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   SectionName: .ARM.exidx.pr1.nontrivial
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     FunctionAddress: 0x0
@ CHECK-UNW:     ExceptionHandlingTable: .ARM.extab.pr1.nontrivial
@ CHECK-UNW:     TableEntryOffset: 0x0
@ CHECK-UNW:     Model: Compact
@ CHECK-UNW:     PersonalityIndex: 1
@ CHECK-UNW:     Opcodes [
@ CHECK-UNW:       0x03      ; vsp = vsp + 16
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:     ]
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.pr1.nontrivial
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .pr1.nontrivial 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr1 0x0
@ CHECK-REL:     0x4 R_ARM_PREL31 .ARM.extab.pr1.nontrivial 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

	.section .pr2

	.global pr2
	.type pr2,%function
	.thumb_func
pr2:
	.fnstart
	.personalityindex 2
	bx lr
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   SectionName: .ARM.exidx.pr2
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     FunctionAddress: 0x0
@ CHECK-UNW:     ExceptionHandlingTable: .ARM.extab.pr2
@ CHECK-UNW:     TableEntryOffset: 0x0
@ CHECK-UNW:     Model: Compact
@ CHECK-UNW:     PersonalityIndex: 2
@ CHECK-UNW:     Opcodes [
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:     ]
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.pr2
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .pr2 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr2 0x0
@ CHECK-REL:     0x4 R_ARM_PREL31 .ARM.extab.pr2 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

	.section .pr2.nontrivial
	.type pr2_nontrivial,%function
	.thumb_func
pr2_nontrivial:
	.fnstart
	.personalityindex 2
	.pad #0x10
	sub sp, sp, #0x10
	add sp, sp, #0x10
	bx lr
	.fnend

@ CHECK-UNW: UnwindIndexTable {
@ CHECK-UNW:   SectionName: .ARM.exidx.pr2.nontrivial
@ CHECK-UNW:   Entries [
@ CHECK-UNW:     FunctionAddress: 0x0
@ CHECK-UNW:     ExceptionHandlingTable: .ARM.extab.pr2.nontrivial
@ CHECK-UNW:     TableEntryOffset: 0x0
@ CHECK-UNW:     Model: Compact
@ CHECK-UNW:     PersonalityIndex: 2
@ CHECK-UNW:     Opcodes [
@ CHECK-UNW:       0x03      ; vsp = vsp + 16
@ CHECK-UNW:       0xB0      ; finish
@ CHECK-UNW:     ]
@ CHECK-UNW:   ]
@ CHECK-UNW: }

@ CHECK-REL: Section {
@ CHECK-REL:   Name: .rel.ARM.exidx.pr2.nontrivial
@ CHECK-REL:   Relocations [
@ CHECK-REL:     0x0 R_ARM_PREL31 .pr2.nontrivial 0x0
@ CHECK-REL:     0x0 R_ARM_NONE __aeabi_unwind_cpp_pr2 0x0
@ CHECK-REL:     0x4 R_ARM_PREL31 .ARM.extab.pr2.nontrivial 0x0
@ CHECK-REL:   ]
@ CHECK-REL: }

