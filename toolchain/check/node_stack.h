// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_NODE_STACK_H_
#define CARBON_TOOLCHAIN_CHECK_NODE_STACK_H_

#include <type_traits>

#include "common/vlog.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/parse/node_kind.h"
#include "toolchain/parse/tree.h"
#include "toolchain/sem_ir/inst.h"

namespace Carbon::Check {

// Wraps the stack of parse nodes for Context. Each parse node can have an
// associated id of some kind (instruction, instruction block, function, class,
// ...).
//
// All pushes and pops will be vlogged.
//
// Pop APIs will run basic verification:
//
// - If receiving a pop_parse_kind, verify that the parse_node being popped is
//   of pop_parse_kind.
// - Validates presence of inst_id based on whether it's a solo
//   parse_node.
//
// These should be assumed API constraints unless otherwise mentioned on a
// method. The main exception is PopAndIgnore, which doesn't do verification.
class NodeStack {
 public:
  explicit NodeStack(const Parse::Tree& parse_tree,
                     llvm::raw_ostream* vlog_stream)
      : parse_tree_(&parse_tree), vlog_stream_(vlog_stream) {}

  // Pushes a solo parse tree node onto the stack. Used when there is no
  // IR generated by the node.
  auto Push(Parse::Node parse_node) -> void {
    CARBON_CHECK(ParseNodeKindToIdKind(parse_tree_->node_kind(parse_node)) ==
                 IdKind::SoloParseNode)
        << "Parse kind expects an Id: " << parse_tree_->node_kind(parse_node);
    CARBON_VLOG() << "Node Push " << stack_.size() << ": "
                  << parse_tree_->node_kind(parse_node) << " -> <none>\n";
    CARBON_CHECK(stack_.size() < (1 << 20))
        << "Excessive stack size: likely infinite loop";
    stack_.push_back(Entry(parse_node, SemIR::InstId::Invalid));
  }

  // Pushes a parse tree node onto the stack with an ID.
  template <typename IdT>
  auto Push(Parse::Node parse_node, IdT id) -> void {
    CARBON_CHECK(ParseNodeKindToIdKind(parse_tree_->node_kind(parse_node)) ==
                 IdTypeToIdKind<IdT>())
        << "Parse kind expected a different IdT: "
        << parse_tree_->node_kind(parse_node) << " -> " << id << "\n";
    CARBON_CHECK(id.is_valid()) << "Push called with invalid id: "
                                << parse_tree_->node_kind(parse_node);
    CARBON_VLOG() << "Node Push " << stack_.size() << ": "
                  << parse_tree_->node_kind(parse_node) << " -> " << id << "\n";
    CARBON_CHECK(stack_.size() < (1 << 20))
        << "Excessive stack size: likely infinite loop";
    stack_.push_back(Entry(parse_node, id));
  }

  // Returns whether the node on the top of the stack is the specified kind.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto PeekIs() const -> bool {
    return parse_tree_->node_kind(PeekParseNode()) == RequiredParseKind;
  }

  // Pops the top of the stack without any verification.
  auto PopAndIgnore() -> void { PopEntry<SemIR::InstId>(); }

  // Pops the top of the stack and returns the parse_node.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto PopForSoloParseNode() -> Parse::Node {
    Entry back = PopEntry<SemIR::InstId>();
    RequireIdKind(Parse::NodeKind::Create(RequiredParseKind),
                  IdKind::SoloParseNode);
    RequireParseKind<RequiredParseKind>(back.parse_node);
    return back.parse_node;
  }

  // Pops the top of the stack if it is the given kind, and returns the
  // parse_node. Otherwise, returns std::nullopt.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto PopForSoloParseNodeIf() -> std::optional<Parse::Node> {
    if (PeekIs<RequiredParseKind>()) {
      return PopForSoloParseNode<RequiredParseKind>();
    }
    return std::nullopt;
  }

  // Pops the top of the stack.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto PopAndDiscardSoloParseNode() -> void {
    PopForSoloParseNode<RequiredParseKind>();
  }

  // Pops an expression from the top of the stack and returns the parse_node and
  // the ID.
  auto PopExprWithParseNode() -> std::pair<Parse::Node, SemIR::InstId> {
    return PopWithParseNode<SemIR::InstId>();
  }

  // Pops the top of the stack and returns the parse_node and the ID.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto PopWithParseNode() -> auto {
    constexpr IdKind RequiredIdKind =
        ParseNodeKindToIdKind(Parse::NodeKind::Create(RequiredParseKind));
    if constexpr (RequiredIdKind == IdKind::InstId) {
      auto back = PopWithParseNode<SemIR::InstId>();
      RequireParseKind<RequiredParseKind>(back.first);
      return back;
    }
    if constexpr (RequiredIdKind == IdKind::InstBlockId) {
      auto back = PopWithParseNode<SemIR::InstBlockId>();
      RequireParseKind<RequiredParseKind>(back.first);
      return back;
    }
    if constexpr (RequiredIdKind == IdKind::FunctionId) {
      auto back = PopWithParseNode<SemIR::FunctionId>();
      RequireParseKind<RequiredParseKind>(back.first);
      return back;
    }
    if constexpr (RequiredIdKind == IdKind::ClassId) {
      auto back = PopWithParseNode<SemIR::ClassId>();
      RequireParseKind<RequiredParseKind>(back.first);
      return back;
    }
    if constexpr (RequiredIdKind == IdKind::NameId) {
      auto back = PopWithParseNode<SemIR::NameId>();
      RequireParseKind<RequiredParseKind>(back.first);
      return back;
    }
    if constexpr (RequiredIdKind == IdKind::TypeId) {
      auto back = PopWithParseNode<SemIR::TypeId>();
      RequireParseKind<RequiredParseKind>(back.first);
      return back;
    }
    CARBON_FATAL() << "Unpoppable IdKind for parse kind: "
                   << Parse::NodeKind::Create(RequiredParseKind)
                   << "; see value in ParseNodeKindToIdKind";
  }

  // Pops an expression from the top of the stack and returns the ID.
  // Expressions map multiple Parse::NodeKinds to SemIR::InstId always.
  auto PopExpr() -> SemIR::InstId { return PopExprWithParseNode().second; }

  // Pops the top of the stack and returns the ID.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto Pop() -> auto {
    return PopWithParseNode<RequiredParseKind>().second;
  }

  // Pops the top of the stack if it has the given kind, and returns the ID.
  // Otherwise returns std::nullopt.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto PopIf() -> std::optional<decltype(Pop<RequiredParseKind>())> {
    if (PeekIs<RequiredParseKind>()) {
      return Pop<RequiredParseKind>();
    }
    return std::nullopt;
  }

  // Peeks at the parse node of the top of the name stack.
  auto PeekParseNode() const -> Parse::Node { return stack_.back().parse_node; }

  // Peeks at the ID associated with the top of the name stack.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto Peek() const -> auto {
    Entry back = stack_.back();
    RequireParseKind<RequiredParseKind>(back.parse_node);
    constexpr IdKind RequiredIdKind =
        ParseNodeKindToIdKind(Parse::NodeKind::Create(RequiredParseKind));
    if constexpr (RequiredIdKind == IdKind::InstId) {
      return back.id<SemIR::InstId>();
    }
    if constexpr (RequiredIdKind == IdKind::InstBlockId) {
      return back.id<SemIR::InstBlockId>();
    }
    if constexpr (RequiredIdKind == IdKind::FunctionId) {
      return back.id<SemIR::FunctionId>();
    }
    if constexpr (RequiredIdKind == IdKind::ClassId) {
      return back.id<SemIR::ClassId>();
    }
    if constexpr (RequiredIdKind == IdKind::NameId) {
      return back.id<SemIR::NameId>();
    }
    if constexpr (RequiredIdKind == IdKind::TypeId) {
      return back.id<SemIR::TypeId>();
    }
    CARBON_FATAL() << "Unpeekable IdKind for parse kind: "
                   << Parse::NodeKind::Create(RequiredParseKind)
                   << "; see value in ParseNodeKindToIdKind";
  }

  // Prints the stack for a stack dump.
  auto PrintForStackDump(llvm::raw_ostream& output) const -> void;

  auto empty() const -> bool { return stack_.empty(); }
  auto size() const -> size_t { return stack_.size(); }

 private:
  // Possible associated ID types.
  enum class IdKind : int8_t {
    InstId,
    InstBlockId,
    FunctionId,
    ClassId,
    NameId,
    TypeId,
    // No associated ID type.
    SoloParseNode,
    // Not expected in the node stack.
    Unused,
  };

  // An entry in stack_.
  struct Entry {
    explicit Entry(Parse::Node parse_node, SemIR::InstId inst_id)
        : parse_node(parse_node), inst_id(inst_id) {}
    explicit Entry(Parse::Node parse_node, SemIR::InstBlockId inst_block_id)
        : parse_node(parse_node), inst_block_id(inst_block_id) {}
    explicit Entry(Parse::Node parse_node, SemIR::FunctionId function_id)
        : parse_node(parse_node), function_id(function_id) {}
    explicit Entry(Parse::Node parse_node, SemIR::ClassId class_id)
        : parse_node(parse_node), class_id(class_id) {}
    explicit Entry(Parse::Node parse_node, SemIR::NameId name_id)
        : parse_node(parse_node), name_id(name_id) {}
    explicit Entry(Parse::Node parse_node, SemIR::TypeId type_id)
        : parse_node(parse_node), type_id(type_id) {}

    // Returns the appropriate ID basaed on type.
    template <typename T>
    auto id() -> T& {
      if constexpr (std::is_same<T, SemIR::InstId>()) {
        return inst_id;
      }
      if constexpr (std::is_same<T, SemIR::InstBlockId>()) {
        return inst_block_id;
      }
      if constexpr (std::is_same<T, SemIR::FunctionId>()) {
        return function_id;
      }
      if constexpr (std::is_same<T, SemIR::ClassId>()) {
        return class_id;
      }
      if constexpr (std::is_same<T, SemIR::NameId>()) {
        return name_id;
      }
      if constexpr (std::is_same<T, SemIR::TypeId>()) {
        return type_id;
      }
    }

    // The parse node associated with the stack entry.
    Parse::Node parse_node;

    // The entries will evaluate as invalid if and only if they're a solo
    // parse_node. Invalid is used instead of optional to save space.
    //
    // A discriminator isn't needed because the caller can determine which field
    // is used based on the Parse::NodeKind.
    union {
      SemIR::InstId inst_id;
      SemIR::InstBlockId inst_block_id;
      SemIR::FunctionId function_id;
      SemIR::ClassId class_id;
      SemIR::NameId name_id;
      SemIR::TypeId type_id;
    };
  };
  static_assert(sizeof(Entry) == 8, "Unexpected Entry size");

  // Translate a parse node kind to the enum ID kind it should always provide.
  static constexpr auto ParseNodeKindToIdKind(Parse::NodeKind kind) -> IdKind {
    switch (kind) {
      case Parse::NodeKind::ArrayExpr:
      case Parse::NodeKind::CallExpr:
      case Parse::NodeKind::CallExprStart:
      case Parse::NodeKind::IfExprThen:
      case Parse::NodeKind::IfExprElse:
      case Parse::NodeKind::IndexExpr:
      case Parse::NodeKind::InfixOperator:
      case Parse::NodeKind::Literal:
      case Parse::NodeKind::MemberAccessExpr:
      case Parse::NodeKind::NameExpr:
      case Parse::NodeKind::ParenExpr:
      case Parse::NodeKind::PatternBinding:
      case Parse::NodeKind::PostfixOperator:
      case Parse::NodeKind::PrefixOperator:
      case Parse::NodeKind::ReturnType:
      case Parse::NodeKind::SelfTypeNameExpr:
      case Parse::NodeKind::SelfValueNameExpr:
      case Parse::NodeKind::ShortCircuitOperand:
      case Parse::NodeKind::StructFieldValue:
      case Parse::NodeKind::StructLiteral:
      case Parse::NodeKind::StructFieldType:
      case Parse::NodeKind::StructTypeLiteral:
      case Parse::NodeKind::TupleLiteral:
        return IdKind::InstId;
      case Parse::NodeKind::IfCondition:
      case Parse::NodeKind::IfExprIf:
      case Parse::NodeKind::ImplicitParameterList:
      case Parse::NodeKind::ParameterList:
      case Parse::NodeKind::WhileCondition:
      case Parse::NodeKind::WhileConditionStart:
        return IdKind::InstBlockId;
      case Parse::NodeKind::FunctionDefinitionStart:
        return IdKind::FunctionId;
      case Parse::NodeKind::ClassDefinitionStart:
        return IdKind::ClassId;
      case Parse::NodeKind::Name:
        return IdKind::NameId;
      case Parse::NodeKind::ArrayExprSemi:
      case Parse::NodeKind::ClassIntroducer:
      case Parse::NodeKind::CodeBlockStart:
      case Parse::NodeKind::FunctionIntroducer:
      case Parse::NodeKind::IfStatementElse:
      case Parse::NodeKind::ImplicitParameterListStart:
      case Parse::NodeKind::LetIntroducer:
      case Parse::NodeKind::ParameterListStart:
      case Parse::NodeKind::ParenExprOrTupleLiteralStart:
      case Parse::NodeKind::QualifiedDeclaration:
      case Parse::NodeKind::ReturnStatementStart:
      case Parse::NodeKind::SelfValueName:
      case Parse::NodeKind::StructLiteralOrStructTypeLiteralStart:
      case Parse::NodeKind::VariableInitializer:
      case Parse::NodeKind::VariableIntroducer:
        return IdKind::SoloParseNode;
      default:
        return IdKind::Unused;
    }
  }

  // Translates an ID type to the enum ID kind for comparison with
  // ParseNodeKindToIdKind.
  template <typename IdT>
  static constexpr auto IdTypeToIdKind() -> IdKind {
    if constexpr (std::is_same_v<IdT, SemIR::InstId>) {
      return IdKind::InstId;
    }
    if constexpr (std::is_same_v<IdT, SemIR::InstBlockId>) {
      return IdKind::InstBlockId;
    }
    if constexpr (std::is_same_v<IdT, SemIR::FunctionId>) {
      return IdKind::FunctionId;
    }
    if constexpr (std::is_same_v<IdT, SemIR::ClassId>) {
      return IdKind::ClassId;
    }
    if constexpr (std::is_same_v<IdT, SemIR::NameId>) {
      return IdKind::NameId;
    }
    if constexpr (std::is_same_v<IdT, SemIR::TypeId>) {
      return IdKind::TypeId;
    }
  }

  // Pops an entry.
  template <typename IdT>
  auto PopEntry() -> Entry {
    Entry back = stack_.pop_back_val();
    CARBON_VLOG() << "Node Pop " << stack_.size() << ": "
                  << parse_tree_->node_kind(back.parse_node) << " -> "
                  << back.id<IdT>() << "\n";
    return back;
  }

  // Pops the top of the stack and returns the parse_node and the ID.
  template <typename IdT>
  auto PopWithParseNode() -> std::pair<Parse::Node, IdT> {
    Entry back = PopEntry<IdT>();
    RequireIdKind(parse_tree_->node_kind(back.parse_node),
                  IdTypeToIdKind<IdT>());
    return {back.parse_node, back.id<IdT>()};
  }

  // Require a Parse::NodeKind be mapped to a particular IdKind.
  auto RequireIdKind(Parse::NodeKind parse_kind, IdKind id_kind) const -> void {
    CARBON_CHECK(ParseNodeKindToIdKind(parse_kind) == id_kind)
        << "Unexpected IdKind mapping for " << parse_kind;
  }

  // Require an entry to have the given Parse::NodeKind.
  template <Parse::NodeKind::RawEnumType RequiredParseKind>
  auto RequireParseKind(Parse::Node parse_node) const -> void {
    auto actual_kind = parse_tree_->node_kind(parse_node);
    CARBON_CHECK(RequiredParseKind == actual_kind)
        << "Expected " << Parse::NodeKind::Create(RequiredParseKind)
        << ", found " << actual_kind;
  }

  // The file's parse tree.
  const Parse::Tree* parse_tree_;

  // Whether to print verbose output.
  llvm::raw_ostream* vlog_stream_;

  // The actual stack.
  // PushEntry and PopEntry control modification in order to centralize
  // vlogging.
  llvm::SmallVector<Entry> stack_;
};

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_NODE_STACK_H_
