# Nix Neovim

Lua-first Neovim configuration packaged with Nix and Neovim nightly.

Nix provides Neovim, plugins, Treesitter parsers, and command-line tools. Lua
provides the editor configuration, plugin setup, LSP configuration, formatting,
keymaps, and integrations.

## Requirements

- Nix with flakes enabled
- `x86_64-linux`, `aarch64-linux`, or Apple Silicon macOS (`aarch64-darwin`)
- `direnv` is optional

The flake currently targets Linux x86_64, Linux aarch64, and Apple Silicon
macOS. Intel macOS is not supported by the current nixpkgs unstable input.

## Packages

The flake provides two Neovim variants:

- `full`: includes language servers and formatters
- `lite`: includes universal tools and relies on project environments for language-specific tools

Build or run a package:

```sh
nix build .#full
./result/bin/nvim

nix build .#lite
./result/bin/nvim
```

The default package is `full`:

```sh
nix build
```

## Development

Enter the development shell for Lua tooling:

```sh
nix develop
```

The shell includes LuaJIT, StyLua, and the Lua language server. With direnv,
the shell is loaded automatically through `.envrc`.

Run the flake checks:

```sh
nix flake check
```

The checks build both variants and run headless startup tests in clean
environments. They verify startup, plugin loading, universal tools, and the
full-only language-server and formatter tools.

## Features

- Catppuccin Macchiato
- Oil file navigation
- Telescope file search, buffers, help, and custom multigrep
- Treesitter highlighting, folding, and indentation
- Blink completion
- Native Neovim LSP configuration with `nvim-lspconfig` definitions
- Conform formatting with format-on-save
- Gitsigns
- Harpoon
- Undotree
- Render Markdown
- Snacks terminals and input/picker support
- LazyGit integration
- OpenCode integration
- Which Key

The two scratchpad terminals use:

- `<A-r>` for Scratch-1
- `<A-t>` for Scratch-2

Scratchpad terminals are mutually exclusive, preserve their shell sessions
while hidden, and use floating windows with rounded borders.

## Layout

```text
flake.nix       Nix package definitions and tool/plugin wiring
flake.lock      Locked flake inputs
src/init.lua    Configuration entrypoint
src/lua/config  Core options, keymaps, and autocmds
src/lua/lsp     Language-server setup and LSP keymaps
src/lua/plugins Plugin configuration
```

Plugins and Treesitter parsers are supplied by Nix rather than installed by a
Lua plugin manager. The configuration is currently eager-loaded; lazy loading
is intentionally deferred.

## OpenCode

OpenCode is configured for local use through `opencode.nvim` and Snacks. The
plugin handles server discovery and sessions, while Snacks manages a locally
started OpenCode terminal.
