{
  description = "Personal Neovim configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Neovim nightly overlay
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    # Track upstream main for OpenCode v2 support.
    opencode-nvim = {
      url = "github:nickjvandyke/opencode.nvim";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      neovim-nightly-overlay,
      opencode-nvim,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      mkSystem =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ neovim-nightly-overlay.overlays.default ];
          };

          treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
            p.bash
            p.c
            p.css
            p.dockerfile
            p.go
            p.html
            p.javascript
            p.json
            p.lua
            p.markdown
            p.markdown_inline
            p.nix
            p.python
            p.query
            p.regex
            p.rust
            p.sql
            p.toml
            p.tsx
            p.typescript
            p.vim
            p.vimdoc
            p.yaml
          ]);

          opencodeNvim = pkgs.vimUtils.buildVimPlugin {
            pname = "opencode.nvim";
            version = "main";
            src = opencode-nvim;
          };

          universalPlugins =
            with pkgs.vimPlugins;
            [
              blink-cmp
              catppuccin-nvim
              conform-nvim
              gitsigns-nvim
              harpoon2
              lazygit-nvim
              lualine-nvim
              mini-icons
              oil-nvim
              render-markdown-nvim
              snacks-nvim
              telescope-fzf-native-nvim
              telescope-nvim
              nvim-lspconfig
              nvim-web-devicons
              undotree
              which-key-nvim
            ]
            ++ [ treesitter opencodeNvim ];

          universalTools = with pkgs; [
            fd
            git
            lazygit
            opencode
            ripgrep
          ];

          lspPackages = with pkgs; [
            ccls
            dockerfile-language-server
            gopls
            lua-language-server
            nixd
            pyright
            ruff
            rust-analyzer
            typescript-language-server
            vscode-langservers-extracted
          ];

          formatterPackages = with pkgs; [
            beautysh
            clang-tools
            go
            isort
            nixfmt
            pgformatter
            prettier
            ruff
            rustfmt
            stylua
            tombi
            xmlformat
          ];

          neovimConfig = pkgs.stdenv.mkDerivation {
            name = "nvimConfig";
            version = "0.1.0";
            src = ./src;

            installPhase = ''
              mkdir -p $out
              cp -r ./* $out/.
            '';
          };

          mkNeovim =
            extraTools:
            pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
              plugins = universalPlugins;

              wrapperArgs = [
                "--suffix"
                "PATH"
                ":"
                (pkgs.lib.makeBinPath (universalTools ++ extraTools))
              ];

              luaRcContent = ''
                vim.opt.runtimepath:prepend("${neovimConfig}")
                dofile("${neovimConfig}/init.lua")
              '';
            };

          full = mkNeovim (lspPackages ++ formatterPackages);
          lite = mkNeovim [ ];
        in
        {
          packages = {
            default = full;
            inherit full lite;
          };

          checks =
            if system == "x86_64-linux" then
              {
                full-startup = pkgs.runCommand "nvim-full-startup-check" { } ''
                  export HOME=$(mktemp -d)
                  env -i HOME="$HOME" TERM=xterm-256color ${full}/bin/nvim --headless \
                    '+lua assert(vim.fn.executable("rg") == 1, "rg missing")' \
                    '+lua assert(vim.fn.executable("git") == 1, "git missing")' \
                    '+lua assert(vim.fn.executable("nixd") == 1, "nixd missing")' \
                    '+lua assert(vim.fn.executable("nixfmt") == 1, "nixfmt missing")' \
                    '+lua require("conform")' \
                    '+lua require("gitsigns")' \
                    '+lua require("opencode")' \
                    '+quitall'
                  touch $out
                '';

                opencode-integration = pkgs.runCommand "nvim-opencode-integration-check" { } ''
                  export HOME="$TMPDIR/home"
                  export OPENCODE_TEST_LOG="$TMPDIR/opencode-processes.log"
                  mkdir -p "$HOME" "$TMPDIR/fake-bin"

                  cat > "$TMPDIR/fake-bin/opencode" <<'EOF'
                  #!${pkgs.runtimeShell}
                  printf '%s\\n' "$$" >> "$OPENCODE_TEST_LOG"
                  trap 'exit 0' TERM INT HUP
                  while :; do
                    ${pkgs.coreutils}/bin/sleep 1
                  done
                  EOF
                  chmod +x "$TMPDIR/fake-bin/opencode"

                  PATH="$TMPDIR/fake-bin:$PATH" ${full}/bin/nvim --headless \
                    -c "lua dofile('${./tests/opencode.lua}')"
                  touch $out
                '';

                lite-startup = pkgs.runCommand "nvim-lite-startup-check" { } ''
                  export HOME=$(mktemp -d)
                  env -i HOME="$HOME" TERM=xterm-256color ${lite}/bin/nvim --headless \
                    '+lua assert(vim.fn.executable("rg") == 1, "rg missing")' \
                    '+lua assert(vim.fn.executable("git") == 1, "git missing")' \
                    '+lua assert(vim.fn.executable("nixd") == 0, "nixd should not be bundled in lite")' \
                    '+lua assert(vim.fn.executable("nixfmt") == 0, "nixfmt should not be bundled in lite")' \
                    '+lua require("conform")' \
                    '+quitall'
                  touch $out
                '';
              }
            else
              { };

          devShell = pkgs.mkShell {
            packages = with pkgs; [
              luajit
              stylua
              lua-language-server
            ];
          };
        };

      perSystem = builtins.listToAttrs (
        map (system: {
          name = system;
          value = mkSystem system;
        }) systems
      );
    in
    {
      packages = builtins.mapAttrs (_: value: value.packages) perSystem;
      checks = builtins.mapAttrs (_: value: value.checks) perSystem;
      devShells = builtins.mapAttrs (_: value: { default = value.devShell; }) perSystem;
    };
}
