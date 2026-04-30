{ config, lib, inputs, system, ... }:

{
  home.packages = [
    inputs.llm-agents.packages.${system}.agent-deck
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
}
