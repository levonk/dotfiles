Feature: Git Configuration Management
  As a developer using the dotfiles system
  I want consistent Git configuration
  So that my Git workflow is reliable and efficient

  Background:
    Given the dotfiles Git configuration is installed
    And the user has Git installed

  Scenario: Modular Git configuration loading
    Given the modular Git configuration exists
    When Git reads the configuration
    Then all configuration modules should be included
    And aliases should be loaded from aliases.gitconfig
    And core settings should be loaded from core.gitconfig
    And diff/merge tools should be loaded from diff-merge.gitconfig
    And no configuration conflicts should exist

  Scenario: Git ignore file consistency
    Given both dot_gitglobalignore and globalignore exist
    When the Git ignore configuration is checked
    Then dot_gitglobalignore should be a hard link to globalignore
    And both files should have identical content
    And Git should recognize the global ignore patterns

  Scenario: Commit template availability
    Given the Git commit template is configured
    When a user creates a new commit
    Then the commit template should be loaded from commit-template.md
    And the template should provide helpful commit guidelines
    And no .txt template duplicates should exist

  Scenario: Git configuration validation
    Given the Git configuration is loaded
    When Git commands are executed
    Then all configured aliases should work correctly
    And diff tools should be properly configured
    And merge tools should be properly configured
    And no Git configuration errors should occur
