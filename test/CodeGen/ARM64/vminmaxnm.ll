; RUN: llc < %s -march=arm64 -arm64-neon-syntax=apple | FileCheck %s

define <2 x float> @f1(<2 x float> %a, <2 x float> %b) nounwind readnone ssp {
; CHECK: fmaxnm.2s	v0, v0, v1
; CHECK: ret
  %vmaxnm2.i = tail call <2 x float> @llvm.arm64.neon.fmaxnm.v2f32(<2 x float> %a, <2 x float> %b) nounwind
  ret <2 x float> %vmaxnm2.i
}

define <4 x float> @f2(<4 x float> %a, <4 x float> %b) nounwind readnone ssp {
; CHECK: fmaxnm.4s	v0, v0, v1
; CHECK: ret
  %vmaxnm2.i = tail call <4 x float> @llvm.arm64.neon.fmaxnm.v4f32(<4 x float> %a, <4 x float> %b) nounwind
  ret <4 x float> %vmaxnm2.i
}

define <2 x double> @f3(<2 x double> %a, <2 x double> %b) nounwind readnone ssp {
; CHECK: fmaxnm.2d	v0, v0, v1
; CHECK: ret
  %vmaxnm2.i = tail call <2 x double> @llvm.arm64.neon.fmaxnm.v2f64(<2 x double> %a, <2 x double> %b) nounwind
  ret <2 x double> %vmaxnm2.i
}

define <2 x float> @f4(<2 x float> %a, <2 x float> %b) nounwind readnone ssp {
; CHECK: fminnm.2s	v0, v0, v1
; CHECK: ret
  %vminnm2.i = tail call <2 x float> @llvm.arm64.neon.fminnm.v2f32(<2 x float> %a, <2 x float> %b) nounwind
  ret <2 x float> %vminnm2.i
}

define <4 x float> @f5(<4 x float> %a, <4 x float> %b) nounwind readnone ssp {
; CHECK: fminnm.4s	v0, v0, v1
; CHECK: ret
  %vminnm2.i = tail call <4 x float> @llvm.arm64.neon.fminnm.v4f32(<4 x float> %a, <4 x float> %b) nounwind
  ret <4 x float> %vminnm2.i
}

define <2 x double> @f6(<2 x double> %a, <2 x double> %b) nounwind readnone ssp {
; CHECK: fminnm.2d	v0, v0, v1
; CHECK: ret
  %vminnm2.i = tail call <2 x double> @llvm.arm64.neon.fminnm.v2f64(<2 x double> %a, <2 x double> %b) nounwind
  ret <2 x double> %vminnm2.i
}

declare <2 x double> @llvm.arm64.neon.fminnm.v2f64(<2 x double>, <2 x double>) nounwind readnone
declare <4 x float> @llvm.arm64.neon.fminnm.v4f32(<4 x float>, <4 x float>) nounwind readnone
declare <2 x float> @llvm.arm64.neon.fminnm.v2f32(<2 x float>, <2 x float>) nounwind readnone
declare <2 x double> @llvm.arm64.neon.fmaxnm.v2f64(<2 x double>, <2 x double>) nounwind readnone
declare <4 x float> @llvm.arm64.neon.fmaxnm.v4f32(<4 x float>, <4 x float>) nounwind readnone
declare <2 x float> @llvm.arm64.neon.fmaxnm.v2f32(<2 x float>, <2 x float>) nounwind readnone


define double @test_fmaxnmv(<2 x double> %in) {
; CHECK-LABEL: test_fmaxnmv:
; CHECK: fmaxnmp.2d d0, v0
  %max = call double @llvm.arm64.neon.fmaxnmv.f64.v2f64(<2 x double> %in)
  ret double %max
}

define double @test_fminnmv(<2 x double> %in) {
; CHECK-LABEL: test_fminnmv:
; CHECK: fminnmp.2d d0, v0
  %min = call double @llvm.arm64.neon.fminnmv.f64.v2f64(<2 x double> %in)
  ret double %min
}

declare double @llvm.arm64.neon.fmaxnmv.f64.v2f64(<2 x double>)
declare double @llvm.arm64.neon.fminnmv.f64.v2f64(<2 x double>)
