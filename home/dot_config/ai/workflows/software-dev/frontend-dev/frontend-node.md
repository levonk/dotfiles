---
description: Frontend Development with Node.js
---

# Frontend Development with Node.js

This workflow provides guidelines for developing frontend applications using Node.js.

## Setup

1. Initialize a new Node.js project:
```bash
npm init -y
```

2. Install essential development dependencies:
```bash
npm install --save-dev webpack webpack-cli webpack-dev-server babel-loader @babel/core @babel/preset-env eslint prettier
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

2. Set up ESLint and Prettier:
```bash
npx eslint --init
touch .prettierrc
```

3. Start development server:
```bash
npm run dev
```

## Testing

1. Install testing framework:
```bash
npm install --save-dev jest @testing-library/react @testing-library/jest-dom
```

2. Run tests:
```bash
npm test
```

## Building for Production

1. Build optimized assets:
```bash
npm run build
```

2. Preview production build:
```bash
npx serve -s dist
```

## Deployment

1. Set up CI/CD pipeline using GitHub Actions or similar service
2. Configure deployment to your hosting provider
3. Set up monitoring and analytics
