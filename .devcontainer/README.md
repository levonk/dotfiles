# DevContainer for Dotfiles Testing

This directory contains a comprehensive development container configuration for automated testing of the dotfiles repository.

## 🎯 Purpose

- **Automated Testing**: Run comprehensive shell configuration tests in an isolated environment
- **Cross-Platform Validation**: Test dotfiles functionality across different environments
- **Performance Benchmarking**: Measure shell startup times and configuration loading performance
- **Development Environment**: Provide a consistent testing environment for contributors

## 📁 Files Overview

### Core Configuration
- **`devcontainer.json`**: Main devcontainer configuration with VS Code integration
- **`Dockerfile`**: Multi-stage Ubuntu-based container with testing dependencies
- **`docker-compose.yml`**: Docker Compose configuration for standalone testing
- **`docker-compose.override.yml`**: Development-specific overrides and additional services
- **`Makefile`**: Convenient commands for container management
- **`setup.sh`**: Post-creation setup script for environment initialization
- **`README.md`**: This documentation file

## 🚀 Quick Start

### Prerequisites
- Docker installed and running
- VS Code with Dev Containers extension

### Usage

#### VS Code DevContainer
1. Open the dotfiles repository in VS Code
2. Press `F1` and select "Dev Containers: Reopen in Container"
3. Wait for container build and setup (first run takes ~2-3 minutes)
4. Tests will run automatically on container startup

#### Docker Compose (Standalone)
```bash
# Quick start - build and run development environment
make up

# Run automated CI tests
make test

# Start interactive development environment
make dev

# Run specific test suites
make test-bats          # Run bats tests only
make test-performance   # Run performance benchmarks

# Start Bash-specific testing environment
make bash-dev

# Clean up everything
make clean
```

### Manual Testing

#### Inside Container (VS Code or Compose)
```bash
# Run all shell configuration tests
bats tests/shell-tests.bats

# Run with debug output
DEBUG_MODULE_LOADING=1 bats tests/shell-tests.bats

# Test shell startup performance
time zsh -c 'source ~/.zshrc && exit'
time bash -c 'source ~/.bashrc && exit'

# Run comprehensive test suite
tests/devcontainer-test.sh
```

#### Using Docker Compose
```bash
# Run tests without entering container
make test-interactive

# Execute specific commands
make exec CMD="bats tests/shell-tests.bats"
make exec CMD="tests/devcontainer-test.sh"

# Debug session with full output
make debug

# Check container status
make status
```

## 🔧 Container Features

### Installed Software
- **Base**: Ubuntu 22.04 LTS
- **Shells**: bash, zsh (with zsh as default)
- **Testing**: bats-core testing framework
- **Tools**: chezmoi, git, curl, wget, vim, nano
- **Development**: build-essential, performance monitoring tools

### Environment Variables
- `DOTFILES_TEST_MODE=true`: Enables test-specific behavior
- `DEBUG_MODULE_LOADING=1`: Enables detailed module loading debug output
- `SHELL=/bin/zsh`: Sets zsh as the default shell

### VS Code Integration
- **Extensions**: ShellCheck, Shell Format, Bash Debug, Test Adapter
- **Settings**: Configured for shell development and testing
- **Terminal**: Default zsh profile with bash fallback

## 🧪 Test Suite

The automated test suite includes:

1. **Shell Configuration Tests**: Validates core shell functionality using bats
2. **Performance Tests**: Measures shell startup times for bash and zsh
3. **Git Configuration**: Validates git configuration and VCS utilities
4. **Local Scripts**: Tests custom bin scripts and utilities
5. **Platform Detection**: Validates cross-platform compatibility utilities
6. **Performance Utilities**: Tests caching and optimization features

### Test Output
- Real-time console output with status indicators
- Detailed log files in `/tmp/dotfiles-test-YYYYMMDD-HHMMSS.log`
- Performance timing for each test suite
- Comprehensive summary report

## 🔍 Debugging

### Debug Mode
```bash
# Enable comprehensive debug output
export DEBUG_MODULE_LOADING=1
export DEBUG_SOURCING=1

# Run shell with debug output
zsh -x
```

### Log Files
- Container setup: Check VS Code terminal output
- Test execution: `/tmp/dotfiles-test-*.log`
- Shell debug: Use `zsh -x` or `bash -x`

### Common Issues
1. **Missing configurations**: Check if `home/` directory structure is complete
2. **Permission errors**: Ensure scripts are executable (`chmod +x`)
3. **Path issues**: Verify `~/.local/bin` is in PATH

## 🏗️ Architecture

### Container Lifecycle
1. **Build**: Dockerfile installs system dependencies and creates user
2. **Create**: `setup.sh` copies configurations and sets up environment
3. **Start**: `test.sh` runs automated test suite
4. **Development**: Interactive shell with full dotfiles environment

### File Mapping
```
/workspace/              # Mounted dotfiles repository
├── home/               # Source dotfiles configurations
├── tests/              # Bats test files
└── .devcontainer/      # Container configuration

/home/vscode/           # Container user home
├── .config/shells/     # Copied shell configurations
├── .config/git/        # Copied git configurations
├── .local/bin/         # Copied utility scripts
└── .local/share/       # Copied data files
```

## 🐳 Docker Compose Architecture

The Docker Compose setup provides multiple deployment options:

### Services
- **`dotfiles-test`**: Main interactive development environment with zsh
- **`dotfiles-ci`**: Automated CI runner that executes tests and exits
- **`dotfiles-bash-test`**: Bash-specific testing environment (via override)

### Volumes
- **`dotfiles-home`**: Persists user configurations between runs
- **`dotfiles-cache`**: Caches downloaded dependencies and build artifacts
- **`dotfiles-local`**: Stores local user data and customizations
- **`dotfiles-bash-home`**: Separate bash environment data

### Configuration Files
- **`docker-compose.yml`**: Base configuration with production-ready settings
- **`docker-compose.override.yml`**: Development overrides with additional services
- **`Makefile`**: Convenient command shortcuts for all operations

### Available Commands
```bash
# Development
make dev          # Interactive zsh environment
make bash-dev     # Interactive bash environment
make debug        # Debug mode with verbose output

# Testing
make test         # Automated CI tests
make test-bats    # Bats framework tests only
make test-performance  # Performance benchmarks

# Management
make build        # Build containers
make clean        # Remove containers and volumes
make status       # Show running containers
make logs         # View container logs
```

## 🔄 Continuous Integration

The devcontainer complements the existing GitHub Actions CI/CD pipeline:

- **Local Development**: Use devcontainer/compose for interactive testing and debugging
- **CI/CD**: GitHub Actions for automated testing on push/PR
- **Cross-Platform**: Devcontainer provides Linux environment, CI tests multiple platforms
- **Standalone Testing**: Docker Compose enables testing without VS Code dependency

## 🛠️ Customization

### Adding New Tests
1. Add test cases to `tests/shell-tests.bats`
2. Update `test.sh` to include new test suites
3. Modify `setup.sh` if additional setup is required

### Container Modifications
1. Update `Dockerfile` for system-level changes
2. Modify `devcontainer.json` for VS Code integration
3. Update `docker-compose.yml` for service configuration
4. Enhance `docker-compose.override.yml` for development features
5. Add new commands to `Makefile` for convenience
6. Enhance `setup.sh` for environment configuration

### Performance Tuning
- Adjust container resource limits in `devcontainer.json`
- Optimize `setup.sh` for faster initialization
- Use multi-stage builds in `Dockerfile` for smaller images

## 📚 Related Documentation

- [Main README](../README.md): Overall dotfiles documentation
- [Test Documentation](../tests/): Bats testing framework details
- [GitHub Actions](../.github/workflows/): CI/CD pipeline configuration
- [Internal Docs](../internal-docs/): Detailed implementation guides

## 🤝 Contributing

When contributing to the devcontainer configuration:

1. Test changes locally before committing
2. Update this README for significant changes
3. Ensure backward compatibility with existing workflows
4. Follow the DRY principle for repeated configurations
5. Add appropriate error handling and logging

---

**Note**: This devcontainer is designed to work seamlessly with the existing dotfiles architecture, including the performance-optimized `entrypointrc.sh`, modular configurations, and cross-platform utilities.
