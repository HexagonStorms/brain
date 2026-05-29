Auto-format code in the current project.

Detect the project type and run the appropriate formatter:
- If `composer.json` exists: run `./bin/php-cs-fixer fix` if available, otherwise `make format` or `make cs-fix`
- If `package.json` exists: run `npm run format` if available, otherwise `npx prettier --write .`
- If neither: ask the user what the format command is

Show which files were changed. If the formatter is not installed or the command is not found, explain how to install it for this stack.

Do not modify files manually — only use the project's own formatter.
