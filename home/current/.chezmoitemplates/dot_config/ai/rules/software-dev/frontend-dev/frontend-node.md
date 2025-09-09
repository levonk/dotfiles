---
description: Frontend Development with Node.js
---

# Frontend Development with Node.js

This workflow provides guidelines for developing frontend applications using Node.js.

## Setup

1. Toolchain with mise (recommended):

```bash
# Install mise: https://mise.jdx.dev/[install]
# In the project, declare tools and install them
mise use -p node@lts bun@latest
mise install
```

1. Initialize a new Node.js project:

```bash
bun init --yes
```

1. Install essential development dependencies:

```bash
bun add -d webpack webpack-cli webpack-dev-server babel-loader @babel/core @babel/preset-env eslint prettier
```

3. Set up project structure:
```bash
mkdir -p src/{components,styles,utils} public
touch src/index.js src/index.html
```

## Development Workflow

1. Create webpack configuration:

```bash
touch webpack.config.js
```

1. Set up ESLint and Prettier:

```bash
bunx eslint --init
touch .prettierrc
```

1. Start development server:

```bash
bun run dev
```

## Testing

1. Install testing framework:

```bash
bun add -d jest @testing-library/react @testing-library/jest-dom
```

1. Run tests:

```bash
bun run test
```

## Building for Production

1. Build optimized assets:

```bash
bun run build
```

1. Preview production build:

```bash
bunx serve -s dist
```

## Deployment

1. Set up CI/CD pipeline using GitHub Actions or similar service
1. Configure deployment to your hosting provider
1. Set up monitoring and analytics

- Follow React patterns
- Use Typescript patterns
- Apply CSS guidelines
- Follow testing patterns
- Use linting rules
- Apply troubleshooting approaches
