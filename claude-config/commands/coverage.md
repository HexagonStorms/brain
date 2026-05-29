Generate a test coverage report for the current project.

Detect the project type and run the appropriate coverage command:
- If `composer.json` exists: run `make coverage` if available, otherwise `./vendor/bin/phpunit --coverage-text`
- If `package.json` exists: run `npm run coverage` if available, otherwise `npx jest --coverage`
- If neither: ask the user what the coverage command is

Show the output. Highlight:
- Overall coverage percentage
- Any files or classes with low coverage (under 80%)
- Untested public methods that look business-critical

Do not attempt to write tests automatically — report the gaps clearly first.
