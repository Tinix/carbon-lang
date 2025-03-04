// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE

class Class;

// CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:4: ERROR: Cannot declare a member of incomplete class `Class`.
// CHECK:STDERR: fn Class.Function() {}
// CHECK:STDERR:    ^
// CHECK:STDERR: fail_incomplete.carbon:[[@LINE-5]]:1: Class was forward declared here.
// CHECK:STDERR: class Class;
// CHECK:STDERR: ^
fn Class.Function() {}

fn CallClassFunction() {
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:3: ERROR: Member access into incomplete class `Class`.
  // CHECK:STDERR:   Class.Function();
  // CHECK:STDERR:   ^
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-14]]:1: Class was forward declared here.
  // CHECK:STDERR: class Class;
  // CHECK:STDERR: ^
  Class.Function();
}

// CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:17: ERROR: Variable has incomplete type `Class`.
// CHECK:STDERR: var global_var: Class;
// CHECK:STDERR:                 ^
// CHECK:STDERR: fail_incomplete.carbon:[[@LINE-23]]:1: Class was forward declared here.
// CHECK:STDERR: class Class;
// CHECK:STDERR: ^
var global_var: Class;

// CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:24: ERROR: Function returns incomplete type `Class`.
// CHECK:STDERR: fn ConvertFromStruct() -> Class { return {}; }
// CHECK:STDERR:                        ^
// CHECK:STDERR: fail_incomplete.carbon:[[@LINE-31]]:1: Class was forward declared here.
// CHECK:STDERR: class Class;
// CHECK:STDERR: ^
fn ConvertFromStruct() -> Class { return {}; }

// TODO: Once the `->` operator is supported:
// TODO: fn G(p: Class*) -> i32 {
// TODO:   return p->n;
// TODO: }

fn MemberAccess(p: Class*) -> i32 {
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:11: ERROR: Member access into object of incomplete type `Class`.
  // CHECK:STDERR:   return (*p).n;
  // CHECK:STDERR:           ^
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-45]]:1: Class was forward declared here.
  // CHECK:STDERR: class Class;
  // CHECK:STDERR: ^
  return (*p).n;
}

// CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:20: ERROR: Function returns incomplete type `Class`.
// CHECK:STDERR: fn Copy(p: Class*) -> Class {
// CHECK:STDERR:                    ^
// CHECK:STDERR: fail_incomplete.carbon:[[@LINE-54]]:1: Class was forward declared here.
// CHECK:STDERR: class Class;
// CHECK:STDERR: ^
fn Copy(p: Class*) -> Class {
  return *p;
}

fn Let(p: Class*) {
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:10: ERROR: `let` binding has incomplete type `Class`.
  // CHECK:STDERR:   let c: Class = *p;
  // CHECK:STDERR:          ^
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-65]]:1: Class was forward declared here.
  // CHECK:STDERR: class Class;
  // CHECK:STDERR: ^
  let c: Class = *p;
}

fn TakeIncomplete(c: Class);

// TODO: We should allow this, and only reject calls to the function.
//
// CHECK:STDERR: fail_incomplete.carbon:[[@LINE+6]]:23: ERROR: Function returns incomplete type `Class`.
// CHECK:STDERR: fn ReturnIncomplete() -> Class;
// CHECK:STDERR:                       ^
// CHECK:STDERR: fail_incomplete.carbon:[[@LINE-78]]:1: Class was forward declared here.
// CHECK:STDERR: class Class;
// CHECK:STDERR: ^
fn ReturnIncomplete() -> Class;

fn CallTakeIncomplete(p: Class*) {
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE+9]]:17: ERROR: Forming value of incomplete type `Class`.
  // CHECK:STDERR:   TakeIncomplete(*p);
  // CHECK:STDERR:                 ^
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-87]]:1: Class was forward declared here.
  // CHECK:STDERR: class Class;
  // CHECK:STDERR: ^
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-19]]:1: Initializing parameter 1 of function declared here.
  // CHECK:STDERR: fn TakeIncomplete(c: Class);
  // CHECK:STDERR: ^
  TakeIncomplete(*p);

  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE+9]]:17: ERROR: Forming value of incomplete type `Class`.
  // CHECK:STDERR:   TakeIncomplete({});
  // CHECK:STDERR:                 ^
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-98]]:1: Class was forward declared here.
  // CHECK:STDERR: class Class;
  // CHECK:STDERR: ^
  // CHECK:STDERR: fail_incomplete.carbon:[[@LINE-30]]:1: Initializing parameter 1 of function declared here.
  // CHECK:STDERR: fn TakeIncomplete(c: Class);
  // CHECK:STDERR: ^
  TakeIncomplete({});
}

fn CallReturnIncomplete() {
  ReturnIncomplete();
}

// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %.loc41: type = struct_type {}
// CHECK:STDOUT:   %.loc100: type = tuple_type ()
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file "fail_incomplete.carbon" {
// CHECK:STDOUT:   class_declaration @Class, ()
// CHECK:STDOUT:   %Class: type = class_type @Class
// CHECK:STDOUT:   %.loc15: <function> = fn_decl @.1
// CHECK:STDOUT:   %CallClassFunction: <function> = fn_decl @CallClassFunction
// CHECK:STDOUT:   %Class.ref: type = name_reference Class, %Class
// CHECK:STDOUT:   %global_var.var: ref <error> = var global_var
// CHECK:STDOUT:   %global_var: ref <error> = bind_name global_var, %global_var.var
// CHECK:STDOUT:   %ConvertFromStruct: <function> = fn_decl @ConvertFromStruct
// CHECK:STDOUT:   %MemberAccess: <function> = fn_decl @MemberAccess
// CHECK:STDOUT:   %Copy: <function> = fn_decl @Copy
// CHECK:STDOUT:   %Let: <function> = fn_decl @Let
// CHECK:STDOUT:   %TakeIncomplete: <function> = fn_decl @TakeIncomplete
// CHECK:STDOUT:   %ReturnIncomplete: <function> = fn_decl @ReturnIncomplete
// CHECK:STDOUT:   %CallTakeIncomplete: <function> = fn_decl @CallTakeIncomplete
// CHECK:STDOUT:   %CallReturnIncomplete: <function> = fn_decl @CallReturnIncomplete
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: class @Class;
// CHECK:STDOUT:
// CHECK:STDOUT: fn @.1() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @CallClassFunction() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Class.ref: type = name_reference Class, file.%Class
// CHECK:STDOUT:   %Function.ref: <error> = name_reference Function, <error>
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @ConvertFromStruct() -> <error> {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc41: {} = struct_literal ()
// CHECK:STDOUT:   return <error>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @MemberAccess(%p: Class*) -> i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: Class* = name_reference p, %p
// CHECK:STDOUT:   %.loc55: ref Class = dereference %p.ref
// CHECK:STDOUT:   return <error>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Copy(%p: Class*) -> <error> {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %p.ref: Class* = name_reference p, %p
// CHECK:STDOUT:   %.loc65: ref Class = dereference %p.ref
// CHECK:STDOUT:   return <error>
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Let(%p: Class*) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Class.ref: type = name_reference Class, file.%Class
// CHECK:STDOUT:   %p.ref: Class* = name_reference p, %p
// CHECK:STDOUT:   %.loc75: ref Class = dereference %p.ref
// CHECK:STDOUT:   %c: <error> = bind_name c, <error>
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @TakeIncomplete(%c: Class);
// CHECK:STDOUT:
// CHECK:STDOUT: fn @ReturnIncomplete() -> <error>;
// CHECK:STDOUT:
// CHECK:STDOUT: fn @CallTakeIncomplete(%p: Class*) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %TakeIncomplete.ref.loc100: <function> = name_reference TakeIncomplete, file.%TakeIncomplete
// CHECK:STDOUT:   %p.ref: Class* = name_reference p, %p
// CHECK:STDOUT:   %.loc100_18: ref Class = dereference %p.ref
// CHECK:STDOUT:   %.loc100_17: init () = call %TakeIncomplete.ref.loc100(<invalid>)
// CHECK:STDOUT:   %TakeIncomplete.ref.loc111: <function> = name_reference TakeIncomplete, file.%TakeIncomplete
// CHECK:STDOUT:   %.loc111_19: {} = struct_literal ()
// CHECK:STDOUT:   %.loc111_17: init () = call %TakeIncomplete.ref.loc111(<invalid>)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @CallReturnIncomplete() {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %ReturnIncomplete.ref: <function> = name_reference ReturnIncomplete, file.%ReturnIncomplete
// CHECK:STDOUT:   %.loc115: init <error> = call %ReturnIncomplete.ref()
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
