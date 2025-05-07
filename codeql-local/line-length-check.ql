/**
 * @name Long Lines
 * @description Finds lines that exceed 120 characters, which may affect code readability
 * @kind problem
 * @problem.severity error
 * @precision very-high
 * @id js/long-lines
 * @tags maintainability
 *       readability
 */

import javascript

from Line l, File f
where 
  l.getTopLevel().getFile() = f and
  f.getAbsolutePath().matches("%/ui.frontend/%") and
  l.getText().length() > 120
select l, "Line exceeds 120 characters (length: " + l.getText().length() + ")"