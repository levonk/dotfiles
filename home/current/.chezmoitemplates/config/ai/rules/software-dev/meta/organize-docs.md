# Documentation Organization Guidelines

## Directory Structure

- `general/` - General software development guidelines and best practices
- `frontend-dev/` - Frontend-specific guidelines (React, Vue, etc.)
- `backend-dev/` - Backend-specific guidelines (Node.js, Python, etc.)
- `devops/` - DevOps, infrastructure, and deployment guidelines
- `security/` - Security best practices and guidelines
- `testing/` - Testing strategies and best practices
- `meta/` - Documentation about documentation

## File Naming Conventions

- Use kebab-case for all file names
- End markdown files with `.md`
- For language/framework-specific files, include the language/tech in the name (e.g., `react-best-practices.md`)

## Content Guidelines

- Start each file with frontmatter containing at least a `description`
- Use clear, descriptive headings
- Include examples when possible
- Keep lines under 100 characters for better readability
- Use code blocks with syntax highlighting
- Link to related documents
- Keep content up-to-date

## Template Files

Template files (`.tmpl`) should be used when the content needs to be processed by a template engine. They should:

- Include all necessary frontmatter
- Use template syntax appropriate for the target system
- Be well-documented with comments
- Include example usage if not obvious

## Versioning

- Use semantic versioning for significant changes
- Document breaking changes clearly
- Include a changelog for major updates

## Review Process

- All documentation should be peer-reviewed
- Keep feedback constructive and specific
- Update documentation as part of the development process, not as an afterthought
