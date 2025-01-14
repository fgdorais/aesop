/-
Copyright (c) 2022 Jannis Limperg. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jannis Limperg
-/

import Aesop.Builder.Constructors
import Aesop.Builder.NormSimp
import Aesop.Builder.Tactic

open Lean
open Lean.Meta

namespace Aesop

-- TODO In the default builders below, we should distinguish between fatal and
-- nonfatal errors. E.g. if the `tactic` builder finds a declaration that is not
-- of tactic type, this is a nonfatal error and we should continue with the next
-- builder. But if the simp builder finds an equation that cannot be interpreted
-- as a simp lemma for some reason, this is a fatal error. Continuing with the
-- next builder is more confusing than anything because the user probably
-- intended to add a simp lemma.

namespace RuleBuilder

private def err (ruleType : String) : RuleBuilder := λ input =>
  throwError m!"aesop: Unable to interpret {input.kind.toRuleIdent} as {ruleType} rule. Try specifying a builder."

def default : RuleBuilder := λ input =>
  match input.phase with
  | PhaseName.safe =>
    constructorsDef input <|>
    tacticDef input <|>
    applyDef input <|>
    err "a safe" input
  | PhaseName.unsafe =>
    constructorsDef input <|>
    tacticDef input <|>
    applyDef input <|>
    err "an unsafe" input
  | PhaseName.norm =>
    constructorsDef input <|>
    tacticDef input <|>
    simp input <|>
    applyDef input <|>
    err "a norm" input
  where
    tacticDef := tactic Inhabited.default
    applyDef := apply Inhabited.default
    constructorsDef := constructors Inhabited.default

end RuleBuilder

end Aesop
