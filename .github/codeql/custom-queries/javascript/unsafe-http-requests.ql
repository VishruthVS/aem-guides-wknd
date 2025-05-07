/**
 * @name Unsafe HTTP requests
 * @description Detects HTTP requests that might not include proper security headers
 * @kind problem
 * @problem.severity warning
 * @id javascript/unsafe-http-requests
 * @tags security
 *       api
 */

import javascript
import semmle.javascript.dataflow.DataFlow
import semmle.javascript.security.dataflow.RequestForgeryCustomizations

/**
 * Identifies direct network request calls
 */
predicate isNetworkRequest(CallExpr call) {
  call.getCalleeName() = "request" or
  call.getCalleeName() = "fetch" or
  exists(MemberExpr m | m = call.getCallee() |
    m.getPropertyName() = "request" or
    m.getPropertyName() = "post" or
    m.getPropertyName() = "get" or
    m.getPropertyName() = "put" or
    m.getPropertyName() = "delete"
  )
}

/**
 * Check if the request appears to contain a CSRF token
 */
predicate hasCSRFProtection(CallExpr call) {
  exists(ObjectExpr obj | 
    obj.flowsTo(call.getAnArgument()) and
    exists(Property p | p = obj.getAProperty() |
      p.getName().toLowerCase().matches("%csrf%") or
      p.getName().toLowerCase().matches("%token%")
    )
  )
}

/**
 * Finds network requests without CSRF protection except for GET requests
 * which are generally safe from CSRF attacks
 */
from CallExpr call
where 
  isNetworkRequest(call) and
  not hasCSRFProtection(call) and
  not (
    exists(MemberExpr m | m = call.getCallee() | m.getPropertyName() = "get") or
    exists(ObjectExpr obj | obj.flowsTo(call.getAnArgument()) |
      exists(Property p | p = obj.getAProperty() |
        p.getName() = "method" and p.getInit().toString().toLowerCase() = "\"get\""
      )
    )
  )
select call, "This HTTP request might not include CSRF protection"