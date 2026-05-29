# PR Review - Senior Software Engineer Analysis

You are conducting a senior-level code review for the currently checked out branch. Please analyze the git diff and provide comprehensive feedback following these guidelines:

## Analysis Framework

### 1. SOLID Principles Compliance
- **S**ingle Responsibility: Are classes/functions doing one thing well?
- **O**pen/Closed: Is code open for extension, closed for modification?
- **L**iskov Substitution: Can derived classes replace base classes seamlessly?
- **I**nterface Segregation: Are interfaces focused and cohesive?
- **D**ependency Inversion: Does code depend on abstractions, not concretions?

### 2. Code Quality Assessment
- **Performance**: Identify bottlenecks, inefficient algorithms, memory leaks
- **Security**: Check for vulnerabilities, input validation, authentication issues
- **Maintainability**: Code readability, documentation, complexity
- **Testing**: Test coverage, test quality, edge cases
- **Error Handling**: Proper exception handling and graceful degradation

### 3. Automatiq Conventions
- PHPDoc on all public methods (PHP), no inline `//` comments
- Business logic in UseCase classes, not Controllers
- Exchange ID fields used correctly (`remote_id`, `short_id`, `tm_event_id`)
- No invented endpoints or assumed class signatures

### 4. Technical Debt
- Highlight areas that increase technical debt
- Suggest improvements where the change touches genuinely problematic existing code

## Review Structure

### Critical Issues (Must Fix)
- Security vulnerabilities
- Broken functionality
- Wrong exchange ID usage
- Invented endpoints or hallucinated class names

### Recommended Changes (Should Fix)
- Code quality issues directly related to the diff
- Convention violations

### Informational (FYI)
- Broader patterns worth knowing about
- Things that are fine in this PR but worth a future conversation

## Instructions

1. Run `git diff main` or `git diff HEAD~1` to see the changes
2. Analyze against the framework above
3. Provide specific, actionable feedback with line references
4. Be constructive — explain why something matters, not just that it's wrong
