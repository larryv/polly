; RUN: opt %loadPolly -polly-detect-unprofitable -polly-scops -analyze -polly-delinearize < %s | FileCheck %s
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; void foo(float *input) {
;   for (int j = 0; j < 8; j++) {
;     //SCoP begin
;     for (int i = 0; i < 63; i++) {
;       float x = input[j * 64 + i + 1];
;       input[j * 64 + i + 0] = x * x;
;     }
;   }
; }

; CHECK  p0: {0,+,256}<%for.cond1.preheader>
; CHECK-NOT: p1

; CHECK: ReadAccess
; CHECK:   [p_0] -> { Stmt_for_body3[i0] -> MemRef_input[o0] : 4o0 = 4 + p_0 + 4i0 };
; CHECK: MustWriteAccess
; CHECK:   [p_0] -> { Stmt_for_body3[i0] -> MemRef_input[o0] : 4o0 = p_0 + 4i0 };

define void @foo(float* nocapture %input) {
entry:
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.inc10, %entry
  %j.021 = phi i64 [ 0, %entry ], [ %inc11, %for.inc10 ]
  %mul = shl nsw i64 %j.021, 6
  br label %for.body3

for.body3:                                        ; preds = %for.body3, %for.cond1.preheader
  %i.020 = phi i64 [ 0, %for.cond1.preheader ], [ %inc, %for.body3 ]
  %add = add nsw i64 %i.020, %mul
  %add4 = add nsw i64 %add, 1
  %arrayidx = getelementptr inbounds float, float* %input, i64 %add4
  %0 = load float, float* %arrayidx, align 8
  %mul5 = fmul float %0, %0
  %arrayidx9 = getelementptr inbounds float, float* %input, i64 %add
  store float %mul5, float* %arrayidx9, align 8
  %inc = add nsw i64 %i.020, 1
  %exitcond = icmp eq i64 %inc, 63
  br i1 %exitcond, label %for.inc10, label %for.body3

for.inc10:                                        ; preds = %for.body3
  %inc11 = add nsw i64 %j.021, 1
  %exitcond22 = icmp eq i64 %inc11, 8
  fence seq_cst
  br i1 %exitcond22, label %for.end12, label %for.cond1.preheader

for.end12:                                        ; preds = %for.inc10
  ret void
}
