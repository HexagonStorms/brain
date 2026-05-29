Run the test suite for the current project.

Detect the project type and run the appropriate test command:
- If `composer.json` exists: run `make unit`
- If `package.json` exists: run `npm test`
- If neither: ask the user what the test command is

Show the full output. If tests fail, identify the failing test and the likely cause.
Do not attempt to fix failures automatically — report them clearly first.
