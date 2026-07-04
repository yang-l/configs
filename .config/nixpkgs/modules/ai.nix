{ config, lib, inputs, pkgs, system, ... }:

{
  home.packages = [
    inputs.llm-agents.packages.${system}.agent-deck
    pkgs.fswatch
    pkgs.gh
  ];

  home.file = {
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.claude/CLAUDE.md";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.claude/settings.json";
    ".claude/agents" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.claude/agents";
      recursive = true;
    };
    ".claude/skills" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.claude/skills";
      recursive = true;
    };
  };

  home.activation.claude-research-code-command = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; mkdir -p ~/.claude/commands && /Users/$USER/.nix-profile/bin/curl -s https://raw.githubusercontent.com/humanlayer/humanlayer/main/.claude/commands/research_codebase.md -o ~/.claude/commands/research_codebase.md'
  '';

  home.activation.claude-autoresearch-command = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; mkdir -p ~/.claude/commands && /Users/$USER/.nix-profile/bin/curl -s https://raw.githubusercontent.com/krzysztofdudek/ResearcherSkill/refs/heads/main/researcher.md -o ~/.claude/commands/autoresearch.md'
  '';

  home.activation.claude-skill-creator = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/skill-creator && mkdir -p ~/.claude/skills/skill-creator && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/anthropics/skills/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/skill-creator skills-main/skills/skill-creator'
  '';

  home.activation.claude-skill-reddit-fetch = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/reddit-fetch && mkdir -p ~/.claude/skills/reddit-fetch && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ykdojo/claude-code-tips/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/reddit-fetch claude-code-tips-main/skills/reddit-fetch'
  '';

  home.activation.claude-skill-handoff = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/handoff && mkdir -p ~/.claude/skills/handoff && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ykdojo/claude-code-tips/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/handoff claude-code-tips-main/skills/handoff'
  '';

  home.activation.claude-skill-review-claudemd = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/review-claudemd && mkdir -p ~/.claude/skills/review-claudemd && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ykdojo/claude-code-tips/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/review-claudemd claude-code-tips-main/skills/review-claudemd'
  '';

  home.activation.claude-skill-council-review = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/council-review && mkdir -p ~/.claude/skills/council-review && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ngmeyer/skills/archive/main.tar.gz | /usr/bin/tar xz --strip-components=4 -C ~/.claude/skills/council-review skills-main/skills/productivity/council-review'
  '';
}
