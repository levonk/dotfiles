Feature: Shell Configuration Management
  As a user of the dotfiles system
  I want reliable shell environment setup
  So that my development environment works consistently

  Background:
    Given the dotfiles repository is properly installed
    And the user has a valid HOME directory

  Scenario: ZSH environment initialization
    Given the user starts a new zsh session
    When the zsh configuration is loaded
    Then ZDOTDIR should be set to "$HOME/.config/shells/zsh"
    And the zsh configuration directory should exist
    And XDG environment variables should be properly sourced
    And no error messages should be displayed

  Scenario: Bash environment initialization
    Given the user starts a new bash session
    When the bash configuration is loaded
    Then XDG environment variables should be properly sourced
    And shared shell utilities should be available
    And no error messages should be displayed

  Scenario: XDG variables centralization
    Given the XDG environment file exists
    When any shell sources the XDG configuration
    Then XDG_CONFIG_HOME should be set to "$HOME/.config"
    And XDG_DATA_HOME should be set to "$HOME/.local/share"
    And XDG_CACHE_HOME should be set to "$HOME/.cache"
    And XDG_STATE_HOME should be set to "$HOME/.local/state"
    And all XDG directories should exist or be created

  Scenario: Error handling for missing files
    Given a shell configuration file is missing
    When the shell attempts to source it
    Then an appropriate warning should be logged
    And the shell should continue loading other configurations
    And the user should be notified of the missing file

  Scenario: Path safety with special characters
    Given directories with spaces in their names exist
    When shell configurations are sourced
    Then all file paths should be properly quoted
    And no "file not found" errors should occur
    And all configurations should load successfully
