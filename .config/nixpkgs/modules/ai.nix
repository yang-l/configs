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
    ".claude/rules" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.claude/rules";
      recursive = true;
    };
  };

  home.activation.claude-skill-handoff = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/handoff && mkdir -p ~/.claude/skills/handoff && /Users/$USER/.nix-profile/bin/curl -sfL https://github.com/ykdojo/claude-code-tips/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/handoff claude-code-tips-main/skills/handoff'
  '';

  home.activation.claude-skill-council-review = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/council-review && mkdir -p ~/.claude/skills/council-review && /Users/$USER/.nix-profile/bin/curl -sfL https://github.com/ngmeyer/skills/archive/main.tar.gz | /usr/bin/tar xz --strip-components=4 -C ~/.claude/skills/council-review skills-main/skills/productivity/council-review'
  '';

  home.activation.claude-skill-diagram-design = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/diagram-design && mkdir -p ~/.claude/skills/diagram-design && /Users/$USER/.nix-profile/bin/curl -sfL https://github.com/cathrynlavery/diagram-design/archive/main.tar.gz | /usr/bin/tar xz --strip-components=3 -C ~/.claude/skills/diagram-design diagram-design-main/skills/diagram-design'
  '';

  home.activation.claude-skill-asd-ste100 = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x; rm -rf ~/.claude/skills/asd-ste100 && mkdir -p ~/.claude/skills/asd-ste100 && /Users/$USER/.nix-profile/bin/curl -sfL https://github.com/danyuchn/asd-ste100-skill/archive/master.tar.gz | /usr/bin/tar xz --strip-components=1 -C ~/.claude/skills/asd-ste100 asd-ste100-skill-master'
  '';

  home.activation.claude-diagram-export-command = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; mkdir -p ~/.claude/commands && /Users/$USER/.nix-profile/bin/curl -sf https://raw.githubusercontent.com/cathrynlavery/diagram-design/main/commands/export-diagram.md -o ~/.claude/commands/export-diagram.md'
  '';
}
