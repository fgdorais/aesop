/-
Copyright (c) 2021 Jannis Limperg. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jannis Limperg
-/

import Aesop.Frontend

open Lean
open Lean.Meta

namespace Aesop.BuiltinRules

@[aesop safe -50 (rule_sets [builtin])]
def assumption : RuleTac := λ input => do
  let goal := input.goal
  goal.withContext do
    goal.checkNotAssigned `Aesop.BuiltinRules.assumption
    goal.instantiateMVars
    let generateScript := input.options.generateScript
    let tgt ← goal.getType
    let initialState ← saveState
    let mut applications := #[]
    for ldecl in ← getLCtx do
      if ldecl.isImplementationDetail then
        continue
      restoreState initialState
      let (some (application, proofHasMVar)) ←
        tryHyp goal tgt ldecl generateScript
        | continue
      if ! tgt.hasMVar && ! proofHasMVar then
        applications := #[application]
        break
      else
        applications := applications.push application
    if applications.isEmpty then
      throwTacticEx `Aesop.BuiltinRules.assumption goal "no matching assumption found"
    return ⟨applications⟩
  where
    tryHyp (goal : MVarId) (tgt : Expr) (ldecl : LocalDecl)
        (generateScript : Bool) : MetaM (Option (RuleApplication × Bool)) := do
      if ! (← isDefEq ldecl.type tgt) then
        return none
      goal.assign ldecl.toExpr
      let postState ← saveState
      let scriptBuilder? :=
        mkScriptBuilder? generateScript $
          .ofTactic 0 `(tactic| exact $(mkIdent ldecl.userName))
      let app := {
        goals := #[]
        postState, scriptBuilder?
      }
      let proofHasMVar := ldecl.type.hasMVar
      return some (app, proofHasMVar)

end Aesop.BuiltinRules
