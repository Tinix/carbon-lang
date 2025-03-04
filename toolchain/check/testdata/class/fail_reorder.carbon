// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE

class Class {
  fn G() -> i32 {
    // TODO: This should find the member function `F` even though it's declared
    // later.
    // CHECK:STDERR: fail_reorder.carbon:[[@LINE+9]]:12: ERROR: Member access into incomplete class `Class`.
    // CHECK:STDERR:     return Class.F();
    // CHECK:STDERR:            ^
    // CHECK:STDERR: fail_reorder.carbon:[[@LINE-7]]:1: Class is incomplete within its definition.
    // CHECK:STDERR: class Class {
    // CHECK:STDERR: ^
    // CHECK:STDERR: fail_reorder.carbon:[[@LINE+3]]:17: ERROR: Name `F` not found.
    // CHECK:STDERR:     return Class.F();
    // CHECK:STDERR:                 ^
    return Class.F();
  }

  fn F() -> i32 {
    return 1;
  }
}

// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %.loc26: type = struct_type {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file "fail_reorder.carbon" {
// CHECK:STDOUT:   class_declaration @Class, ()
// CHECK:STDOUT:   %Class: type = class_type @Class
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Class {
// CHECK:STDOUT:   %G: <function> = fn_decl @G
// CHECK:STDOUT:   %F: <function> = fn_decl @F
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .G = %G
// CHECK:STDOUT:   .F = %F
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Class.ref: type = name_reference Class, file.%Class
// CHECK:STDOUT:   %F.ref: <error> = name_reference F, <error>
// CHECK:STDOUT:   return <error>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc24: i32 = int_literal 1
// CHECK:STDOUT:   return %.loc24
// CHECK:STDOUT: }
