// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE

fn F() {
  // CHECK:STDERR: fail_variety.carbon:[[@LINE+15]]:21: ERROR: Operator `=` can only be used as a complete statement.
  // CHECK:STDERR:   n = a * b + c * d = d * d << e & f - not g;
  // CHECK:STDERR:                     ^
  // CHECK:STDERR: fail_variety.carbon:[[@LINE+12]]:29: ERROR: Parentheses are required to disambiguate operator precedence.
  // CHECK:STDERR:   n = a * b + c * d = d * d << e & f - not g;
  // CHECK:STDERR:                             ^
  // CHECK:STDERR: fail_variety.carbon:[[@LINE+9]]:34: ERROR: Parentheses are required to disambiguate operator precedence.
  // CHECK:STDERR:   n = a * b + c * d = d * d << e & f - not g;
  // CHECK:STDERR:                                  ^
  // CHECK:STDERR: fail_variety.carbon:[[@LINE+6]]:38: ERROR: Parentheses are required to disambiguate operator precedence.
  // CHECK:STDERR:   n = a * b + c * d = d * d << e & f - not g;
  // CHECK:STDERR:                                      ^
  // CHECK:STDERR: fail_variety.carbon:[[@LINE+3]]:40: ERROR: Parentheses are required around this unary `not` operator.
  // CHECK:STDERR:   n = a * b + c * d = d * d << e & f - not g;
  // CHECK:STDERR:                                        ^
  n = a * b + c * d = d * d << e & f - not g;
}

// CHECK:STDOUT: - filename: fail_variety.carbon
// CHECK:STDOUT:   parse_tree: [
// CHECK:STDOUT:     {kind: 'FileStart', text: ''},
// CHECK:STDOUT:         {kind: 'FunctionIntroducer', text: 'fn'},
// CHECK:STDOUT:         {kind: 'Name', text: 'F'},
// CHECK:STDOUT:           {kind: 'ParameterListStart', text: '('},
// CHECK:STDOUT:         {kind: 'ParameterList', text: ')', subtree_size: 2},
// CHECK:STDOUT:       {kind: 'FunctionDefinitionStart', text: '{', subtree_size: 5},
// CHECK:STDOUT:             {kind: 'NameExpr', text: 'n'},
// CHECK:STDOUT:                 {kind: 'NameExpr', text: 'a'},
// CHECK:STDOUT:                 {kind: 'NameExpr', text: 'b'},
// CHECK:STDOUT:               {kind: 'InfixOperator', text: '*', subtree_size: 3},
// CHECK:STDOUT:                 {kind: 'NameExpr', text: 'c'},
// CHECK:STDOUT:                 {kind: 'NameExpr', text: 'd'},
// CHECK:STDOUT:               {kind: 'InfixOperator', text: '*', subtree_size: 3},
// CHECK:STDOUT:             {kind: 'InfixOperator', text: '+', subtree_size: 7},
// CHECK:STDOUT:           {kind: 'InfixOperator', text: '=', subtree_size: 9},
// CHECK:STDOUT:                   {kind: 'NameExpr', text: 'd'},
// CHECK:STDOUT:                   {kind: 'NameExpr', text: 'd'},
// CHECK:STDOUT:                 {kind: 'InfixOperator', text: '*', subtree_size: 3},
// CHECK:STDOUT:                 {kind: 'NameExpr', text: 'e'},
// CHECK:STDOUT:               {kind: 'InfixOperator', text: '<<', has_error: yes, subtree_size: 5},
// CHECK:STDOUT:               {kind: 'NameExpr', text: 'f'},
// CHECK:STDOUT:             {kind: 'InfixOperator', text: '&', has_error: yes, subtree_size: 7},
// CHECK:STDOUT:               {kind: 'NameExpr', text: 'g'},
// CHECK:STDOUT:             {kind: 'PrefixOperator', text: 'not', subtree_size: 2},
// CHECK:STDOUT:           {kind: 'InfixOperator', text: '-', has_error: yes, subtree_size: 10},
// CHECK:STDOUT:         {kind: 'InfixOperator', text: '=', has_error: yes, subtree_size: 20},
// CHECK:STDOUT:       {kind: 'ExprStatement', text: ';', subtree_size: 21},
// CHECK:STDOUT:     {kind: 'FunctionDefinition', text: '}', subtree_size: 27},
// CHECK:STDOUT:     {kind: 'FileEnd', text: ''},
// CHECK:STDOUT:   ]
