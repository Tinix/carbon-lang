// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE

fn A();

namespace N;
fn N.A();

namespace N.M;

fn N.M.B() -> i32 {
  // This is N.A, not package.A.
  A();
  if (true) {
    var A: i32 = 0;
    // This is the local A.
    // TODO: Decide if we should warn or error on the shadowing of N.A here.
    return A;
  }
  return 0;
}

// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %.loc16: type = tuple_type ()
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file "shadow.carbon" {
// CHECK:STDOUT:   %A.loc7: <function> = fn_decl @A.1
// CHECK:STDOUT:   %.loc9: <namespace> = namespace {.A = %A.loc10, .M = %.loc12}
// CHECK:STDOUT:   %A.loc10: <function> = fn_decl @A.2
// CHECK:STDOUT:   %.loc12: <namespace> = namespace {.B = %B}
// CHECK:STDOUT:   %B: <function> = fn_decl @B
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @A.1();
// CHECK:STDOUT:
// CHECK:STDOUT: fn @A.2();
// CHECK:STDOUT:
// CHECK:STDOUT: fn @B() -> i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %A.ref.loc16: <function> = name_reference A, file.%A.loc10
// CHECK:STDOUT:   %.loc16: init () = call %A.ref.loc16()
// CHECK:STDOUT:   %.loc17: bool = bool_literal true
// CHECK:STDOUT:   if %.loc17 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %A.var: ref i32 = var A
// CHECK:STDOUT:   %A: ref i32 = bind_name A, %A.var
// CHECK:STDOUT:   %.loc18: i32 = int_literal 0
// CHECK:STDOUT:   assign %A.var, %.loc18
// CHECK:STDOUT:   %A.ref.loc21: ref i32 = name_reference A, %A
// CHECK:STDOUT:   %.loc21: i32 = bind_value %A.ref.loc21
// CHECK:STDOUT:   return %.loc21
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %.loc23: i32 = int_literal 0
// CHECK:STDOUT:   return %.loc23
// CHECK:STDOUT: }
