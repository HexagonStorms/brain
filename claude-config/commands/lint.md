Run the linter for the current project.

Detect the project type and run the appropriate lint command:
- If `composer.json` exists: run `./bin/php-cs-fixer fix --dry-run` or `make lint` if available
- If `package.json` exists: run `npm run lint`
- If neither: ask the user what the lint command is

Show the output. If there are fixable issues, ask before auto-fixing.
