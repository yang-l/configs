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
    ".claude/output-styles" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.claude/output-styles";
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

  home.activation.claude-skill-handoff = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/handoff && mkdir -p ~/.claude/skills/handoff && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ykdojo/claude-code-tips/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/handoff claude-code-tips-main/skills/handoff'
  '';

  home.activation.claude-skill-review-claudemd = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/review-claudemd && mkdir -p ~/.claude/skills/review-claudemd && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ykdojo/claude-code-tips/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/review-claudemd claude-code-tips-main/skills/review-claudemd'
  '';

  home.activation.claude-skill-council-review = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/council-review && mkdir -p ~/.claude/skills/council-review && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ngmeyer/skills/archive/main.tar.gz | /usr/bin/tar xz --strip-components=4 -C ~/.claude/skills/council-review skills-main/skills/productivity/council-review'
  '';

  home.activation.claude-skill-i-have-adhd = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/i-have-adhd && mkdir -p ~/.claude/skills/i-have-adhd && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/ayghri/i-have-adhd/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/i-have-adhd i-have-adhd-main/skills/i-have-adhd'
  '';

  home.activation.claude-skill-diagram-design = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/diagram-design && mkdir -p ~/.claude/skills/diagram-design && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/cathrynlavery/diagram-design/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/diagram-design diagram-design-main/skills/diagram-design'
  '';

  home.activation.claude-skill-asd-ste100 = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/asd-ste100 && mkdir -p ~/.claude/skills/asd-ste100 && /Users/$USER/.nix-profile/bin/curl -sL https://github.com/danyuchn/asd-ste100-skill/archive/master.tar.gz | /usr/bin/tar xz --strip-components=1 -C ~/.claude/skills/asd-ste100 asd-ste100-skill-master'
  '';

  home.activation.claude-diagram-export-command = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; mkdir -p ~/.claude/commands && /Users/$USER/.nix-profile/bin/curl -s https://raw.githubusercontent.com/cathrynlavery/diagram-design/main/commands/export-diagram.md -o ~/.claude/commands/export-diagram.md'
  '';
}
