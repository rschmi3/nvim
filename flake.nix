{
  description = "Personal Neovim configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # Neovim nightly overlay
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      neovim-nightly-overlay,
    }:
    let
      system = "x86_64-linux";
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
          opencode-nvim
          render-markdown-nvim
          snacks-nvim
          telescope-fzf-native-nvim
          telescope-nvim
          nvim-lspconfig
          nvim-web-devicons
          undotree
          which-key-nvim
        ]
        ++ [ treesitter ];

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

      # Neovim nightly plus essentials
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

    in
    {
      packages.${system} = rec {
        default = full;
        full = mkNeovim (lspPackages ++ formatterPackages);
        lite = mkNeovim [ ];
      };

      checks.${system} = {
        full-startup = pkgs.runCommand "nvim-full-startup-check" { } ''
          export HOME=$(mktemp -d)
          env -i HOME="$HOME" TERM=xterm-256color ${self.packages.${system}.full}/bin/nvim --headless \
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

        lite-startup = pkgs.runCommand "nvim-lite-startup-check" { } ''
          export HOME=$(mktemp -d)
          env -i HOME="$HOME" TERM=xterm-256color ${self.packages.${system}.lite}/bin/nvim --headless \
            '+lua assert(vim.fn.executable("rg") == 1, "rg missing")' \
            '+lua assert(vim.fn.executable("git") == 1, "git missing")' \
            '+lua assert(vim.fn.executable("nixd") == 0, "nixd should not be bundled in lite")' \
            '+lua assert(vim.fn.executable("nixfmt") == 0, "nixfmt should not be bundled in lite")' \
            '+lua require("conform")' \
            '+quitall'
          touch $out
        '';
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            luajit
            stylua
            lua-language-server
          ];
        };
      };
    };
}
