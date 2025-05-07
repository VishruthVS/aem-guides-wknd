/**
 * @name Lines containing Hello
 * @description Find lines of code that contain the text "Hello"
 * @kind problem
 * @problem.severity recommendation
 * @id js/lines-with-hello
 * @tags maintainability
 * @precision medium
 */

import javascript

from Line l
where l.getText().matches("%Hello%")
select l, "This line contains 'Hello'"

/**
 * @name Lines containing import
 * @description Find lines of code that contain the text "import"
 * @kind problem
 * @problem.severity recommendation
 * @id js/lines-with-import
 * @tags maintainability
 * @precision medium
 */

import javascript

from Line l
where l.getText().matches("%import %")
select l, "This line contains an import statement"