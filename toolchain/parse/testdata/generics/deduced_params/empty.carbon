// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE

class Foo[]();

interface Bar[]() {}

// CHECK:STDOUT: - filename: empty.carbon
// CHECK:STDOUT:   parse_tree: [
// CHECK:STDOUT:     {kind: 'FileStart', text: ''},
// CHECK:STDOUT:       {kind: 'ClassIntroducer', text: 'class'},
// CHECK:STDOUT:       {kind: 'Name', text: 'Foo'},
// CHECK:STDOUT:         {kind: 'ImplicitParameterListStart', text: '['},
// CHECK:STDOUT:       {kind: 'ImplicitParameterList', text: ']', subtree_size: 2},
// CHECK:STDOUT:         {kind: 'ParameterListStart', text: '('},
// CHECK:STDOUT:       {kind: 'ParameterList', text: ')', subtree_size: 2},
// CHECK:STDOUT:     {kind: 'ClassDeclaration', text: ';', subtree_size: 7},
// CHECK:STDOUT:         {kind: 'InterfaceIntroducer', text: 'interface'},
// CHECK:STDOUT:         {kind: 'Name', text: 'Bar'},
// CHECK:STDOUT:           {kind: 'ImplicitParameterListStart', text: '['},
// CHECK:STDOUT:         {kind: 'ImplicitParameterList', text: ']', subtree_size: 2},
// CHECK:STDOUT:           {kind: 'ParameterListStart', text: '('},
// CHECK:STDOUT:         {kind: 'ParameterList', text: ')', subtree_size: 2},
// CHECK:STDOUT:       {kind: 'InterfaceDefinitionStart', text: '{', subtree_size: 7},
// CHECK:STDOUT:     {kind: 'InterfaceDefinition', text: '}', subtree_size: 8},
// CHECK:STDOUT:     {kind: 'FileEnd', text: ''},
// CHECK:STDOUT:   ]
