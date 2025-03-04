// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/parse/context.h"

namespace Carbon::Parse {

// Handles DeclarationNameAndParamsAs(Optional|Required).
static auto HandleDeclarationNameAndParams(Context& context, State after_name)
    -> void {
  auto state = context.PopState();

  // TODO: Should handle designated names.
  if (auto identifier = context.ConsumeIf(Lex::TokenKind::Identifier)) {
    state.state = after_name;
    context.PushState(state);

    if (context.PositionIs(Lex::TokenKind::Period)) {
      context.AddLeafNode(NodeKind::Name, *identifier);
      state.state = State::PeriodAsDeclaration;
      context.PushState(state);
    } else {
      context.AddLeafNode(NodeKind::Name, *identifier);
    }
  } else {
    CARBON_DIAGNOSTIC(ExpectedDeclarationName, Error,
                      "`{0}` introducer should be followed by a name.",
                      Lex::TokenKind);
    context.emitter().Emit(*context.position(), ExpectedDeclarationName,
                           context.tokens().GetKind(state.token));
    context.ReturnErrorOnState();
    context.AddLeafNode(NodeKind::InvalidParse, *context.position(),
                        /*has_error=*/true);
  }
}

auto HandleDeclarationNameAndParamsAsNone(Context& context) -> void {
  HandleDeclarationNameAndParams(
      context, State::DeclarationNameAndParamsAfterNameAsNone);
}

auto HandleDeclarationNameAndParamsAsOptional(Context& context) -> void {
  HandleDeclarationNameAndParams(
      context, State::DeclarationNameAndParamsAfterNameAsOptional);
}

auto HandleDeclarationNameAndParamsAsRequired(Context& context) -> void {
  HandleDeclarationNameAndParams(
      context, State::DeclarationNameAndParamsAfterNameAsRequired);
}

enum class Params : int8_t {
  None,
  Optional,
  Required,
};

static auto HandleDeclarationNameAndParamsAfterName(Context& context,
                                                    Params params) -> void {
  auto state = context.PopState();

  if (context.PositionIs(Lex::TokenKind::Period)) {
    // Continue designator processing.
    context.PushState(state);
    state.state = State::PeriodAsDeclaration;
    context.PushState(state);
    return;
  }

  // TODO: We can have a parameter list after a name qualifier, regardless of
  // whether the entity itself permits or requires parameters:
  //
  //   fn Class(T:! type).AnotherClass(U:! type).Function(v: T) {}
  //
  // We should retain a `DeclarationNameAndParams...` state on the stack in all
  // cases below to check for a period after a parameter list, which indicates
  // that we've not finished parsing the declaration name.

  if (params == Params::None) {
    return;
  }

  if (context.PositionIs(Lex::TokenKind::OpenSquareBracket)) {
    context.PushState(State::DeclarationNameAndParamsAfterImplicit);
    context.PushState(State::ParameterListAsImplicit);
  } else if (context.PositionIs(Lex::TokenKind::OpenParen)) {
    context.PushState(State::ParameterListAsRegular);
  } else if (params == Params::Required) {
    CARBON_DIAGNOSTIC(ParametersRequiredByIntroducer, Error,
                      "`{0}` requires a `(` for parameters.", Lex::TokenKind);
    context.emitter().Emit(*context.position(), ParametersRequiredByIntroducer,
                           context.tokens().GetKind(state.token));
    context.ReturnErrorOnState();
  }
}

auto HandleDeclarationNameAndParamsAfterNameAsNone(Context& context) -> void {
  HandleDeclarationNameAndParamsAfterName(context, Params::None);
}

auto HandleDeclarationNameAndParamsAfterNameAsOptional(Context& context)
    -> void {
  HandleDeclarationNameAndParamsAfterName(context, Params::Optional);
}

auto HandleDeclarationNameAndParamsAfterNameAsRequired(Context& context)
    -> void {
  HandleDeclarationNameAndParamsAfterName(context, Params::Required);
}

auto HandleDeclarationNameAndParamsAfterImplicit(Context& context) -> void {
  context.PopAndDiscardState();

  if (context.PositionIs(Lex::TokenKind::OpenParen)) {
    context.PushState(State::ParameterListAsRegular);
  } else {
    CARBON_DIAGNOSTIC(
        ParametersRequiredAfterImplicit, Error,
        "A `(` for parameters is required after implicit parameters.");
    context.emitter().Emit(*context.position(),
                           ParametersRequiredAfterImplicit);
    context.ReturnErrorOnState();
  }
}

}  // namespace Carbon::Parse
