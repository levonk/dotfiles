# BDD Feature Tests for Dotfiles Shell Configuration
# Managed by chezmoi | https://github.com/levonk/dotfiles

Feature: Shell Configuration Loading
  As a developer using the dotfiles
  I want shell configurations to load correctly
  So that I have a consistent development environment

  Background:
    Given I have a clean shell environment
    And the dotfiles are properly installed

  Scenario: Basic shell configuration loading
    Given I start a new shell session
    When the shell configuration loads
    Then all essential modules should be sourced successfully
    And no error messages should be displayed
    And the PATH should include custom directories

  Scenario: Cross-platform compatibility
    Given I am on a supported platform
    When I load the shell configuration
    Then platform-specific settings should be applied correctly
    And path separators should be appropriate for the platform
    And clipboard integration should work for the platform

  Scenario: Shell availability detection
    Given various shells may or may not be available
    When the shell availability detection runs
    Then available shells should be correctly identified
    And a fallback shell should be selected
    And missing shells should be handled gracefully

  Scenario: Tool availability checking
    Given modern CLI tools may or may not be installed
    When tool availability is checked
    Then available tools should be cached for performance
    And missing essential tools should generate warnings
    And fallback commands should be used when appropriate

  Scenario: Performance optimization
    Given the shell configuration includes performance features
    When I start multiple shell sessions
    Then module loading should be cached appropriately
    And lazy loading should work for optional modules
    And startup time should be reasonable (< 2 seconds)

  Scenario: Error handling and recovery
    Given some configuration files may be missing or corrupted
    When the shell configuration attempts to load
    Then errors should be handled gracefully
    And informative error messages should be displayed
    And the shell should remain functional with fallbacks

Feature: Git Configuration
  As a developer using Git
  I want Git to be configured consistently
  So that my workflow is efficient and reliable

  Scenario: Git aliases functionality
    Given Git is installed and configured
    When I use custom Git aliases
    Then they should execute the correct commands
    And provide helpful output formatting
    And work across different Git versions

  Scenario: Git ignore patterns
    Given I'm working in various project types
    When Git checks files for tracking
    Then common build artifacts should be ignored
    And IDE-specific files should be ignored
    And platform-specific files should be ignored

Feature: Editor Configuration
  As a developer using various editors
  I want consistent code formatting
  So that code style is uniform across projects

  Scenario: EditorConfig support
    Given I open files in supported editors
    When I edit code files
    Then indentation should follow project conventions
    And line endings should be consistent
    And trailing whitespace should be handled appropriately

  Scenario: Language-specific formatting
    Given I'm working with different programming languages
    When I edit files of various types
    Then each language should use appropriate formatting rules
    And modern frameworks should be supported
    And configuration files should have proper formatting
