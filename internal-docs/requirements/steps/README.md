# Step Definitions

This directory contains step definitions for BDD test automation.

## Structure

- `shell_steps.sh`: Shell-specific step definitions using bats framework
- `git_steps.sh`: Git configuration step definitions
- `performance_steps.sh`: Performance testing step definitions
- `common_steps.sh`: Shared step definitions and utilities

## Test Framework

The step definitions are designed to work with:
- **bats**: Bash Automated Testing System for shell script testing
- **cucumber**: For more complex BDD scenarios (optional)

## Usage

To run the tests:

```bash
# Install bats if not already installed
npm install -g bats

# Run all tests
bats internal-docs/requirements/steps/*.sh

# Run specific test category
bats internal-docs/requirements/steps/shell_steps.sh
```

## Writing New Steps

When adding new step definitions:
1. Follow the existing naming conventions
2. Include proper error handling and cleanup
3. Use descriptive assertion messages
4. Document any test dependencies or setup requirements
