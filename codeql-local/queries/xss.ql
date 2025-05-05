/**
 * @name Client-side cross-site scripting
 * @description Writing user input directly to the DOM allows for
 *              a cross-site scripting vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id js/xss
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 */

import javascript

// Source: user input
predicate isSource(DataFlow::Node source) {
  exists(source.asExpr().getStringValue()) or
  source.asExpr() instanceof ThisExpr or
  // DOM sources
  source.(DataFlow::PropRead).getPropertyName() = "location" or
  source.(DataFlow::PropRead).getPropertyName() = "href"
}

// Sink: writing to DOM
predicate isSink(DataFlow::Node sink) {
  exists(DataFlow::PropWrite write | 
    write.getRhs() = sink and
    write.getPropertyName() = "innerHTML"
  ) or
  // createElement sink
  exists(MethodCallExpr mce |
    mce.getMethodName() = "appendChild" and
    sink.asExpr() = mce.getArgument(0)
  )
}

from DataFlow::Node source, DataFlow::Node sink
where
  isSource(source) and
  isSink(sink) and
  DataFlow::localFlow(source, sink)
select sink, "Potential XSS vulnerability"
