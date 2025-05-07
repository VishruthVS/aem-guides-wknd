/**
 * @name Basic JavaScript security checks
 * @description Detects common JavaScript security issues
 * @kind problem
 * @problem.severity warning
 * @id javascript/security-checks
 * @tags security
 */

import javascript
import semmle.javascript.security.dataflow.CodeInjectionCustomizations
import semmle.javascript.dataflow.DataFlow

/**
 * Find potential unsafe direct user input handling
 */
predicate isUserInputSource(DataFlow::Node source) {
  exists(DataFlow::ParameterNode param |
    param.getName().matches("%user%") or
    param.getName().matches("%input%") or
    param.getName().matches("%password%")
  |
    source = param
  )
}

/**
 * Find potential insecure sinks
 */
predicate isInsecureSink(DataFlow::Node sink) {
  exists(CallExpr ce |
    (ce.getCalleeName() = "eval" or
     ce.getCalleeName().matches("%execCommand%") or
     ce.getCalleeName().matches("%innerHTML%"))
  |
    sink.asExpr() = ce.getAnArgument()
  )
}

/**
 * Check for potentially dangerous direct assignment operations
 */
from DataFlow::Node source, DataFlow::Node sink
where
  isUserInputSource(source) and
  isInsecureSink(sink) and
  DataFlow::localFlow(source, sink)
select sink, "This might be vulnerable to code injection from $@.", source, "user input"