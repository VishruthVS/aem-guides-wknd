/**
 * @name Hardcoded credentials
 * @description Detects potential hardcoded credentials in JavaScript code
 * @kind problem
 * @problem.severity warning
 * @id javascript/hardcoded-credentials
 * @tags security
 *       credentials
 */

import javascript

/**
 * Identifies variable names that suggest they might contain credentials
 */
predicate isSensitiveVariableName(string name) {
  name.toLowerCase().matches("%password%") or
  name.toLowerCase().matches("%token%") or 
  name.toLowerCase().matches("%secret%") or
  name.toLowerCase().matches("%key%") or
  name.toLowerCase().matches("%pwd%") or
  name.toLowerCase().matches("%credential%")
}

/**
 * Finds string literals assigned to variables with sensitive names
 */
from Variable var, StringLiteral literal
where 
  isSensitiveVariableName(var.getName()) and
  literal = var.getAnAssignedExpr() and
  // Ignore empty strings or very short values which are likely not actual credentials
  literal.getValue().length() > 3 and
  // Ignore obvious placeholder values
  not literal.getValue().matches("%placeholder%") and
  not literal.getValue().matches("%example%") and
  not literal.getValue() = "password"
select literal, "Possible hardcoded credential in " + var.getName()