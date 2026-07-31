# nvim-config

A reproducible, Rust-focused Neovim setup. Cross-platform: **Linux/macOS**
(`install.sh`) and **Windows/PowerShell** (`install.ps1`). Designed to be
installed by a human **or by an AI agent**.

## What this sets up

- **Theme:** Ayu-dark (matches mdBook / The Rust Book "ayu" theme)
- **Absolute line numbers** (not relative)
- **Treesitter** syntax highlighting for Rust, Lua, Vim, Vimdoc, Query
- **Plugins** (managed by [lazy.nvim](https://github.com/folke/lazy.nvim), auto-bootstrapped):
  - `Shatur/neovim-ayu` — colorscheme
  - `nvim-lualine/lualine.nvim` — statusline
  - `nvim-tree/nvim-tree.lua` — file explorer
  - `nvim-telescope/telescope.nvim` — fuzzy finder (with `telescope-fzf-native`)
  - `nvim-treesitter/nvim-treesitter` — syntax highlighting

## Files

| File          | Platform            | Purpose                                          |
|---------------|---------------------|--------------------------------------------------|
| `init.lua`    | all                 | The Neovim config (single file)                  |
| `install.sh`  | Linux / macOS       | Installer: deps + config + plugin bootstrap      |
| `install.ps1` | Windows             | Same, via Scoop + PowerShell                     |
| `README.md`   | all                 | This file (also serves as agent instructions)    |

## How to install

### Linux / macOS

```bash
./install.sh
```

Auto-detects the package manager (pacman / apt / dnf / brew), installs system
dependencies, copies `init.lua` to `~/.config/nvim/init.lua`, bootstraps all
plugins, compiles Treesitter parsers, and verifies the theme.

### Windows (PowerShell)

Scoop is used as the package manager (no admin rights needed).

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install.ps1
```

Installs deps via Scoop (git, ripgrep, gcc/mingw, make, neovim, tree-sitter),
copies `init.lua` to `%LOCALAPPDATA%\nvim\init.lua`, bootstraps plugins, and
compiles Treesitter parsers.

### Manual / for an agent

1. **Install system deps** (all mandatory):
   - `neovim` >= 0.12 (nvim-treesitter main branch requires 0.12+)
   - `tree-sitter-cli` >= 0.26 (compiles parsers)
   - `ripgrep` (Telescope live grep)
   - a C compiler + `make` (for telescope-fzf-native and parser compilation)
   - `git`, `curl`, `tar`
2. **Copy the config:**
   - Linux/macOS: `mkdir -p ~/.config/nvim && cp init.lua ~/.config/nvim/init.lua`
   - Windows: copy to `%LOCALAPPDATA%\nvim\init.lua`
3. **Bootstrap plugins:** `nvim --headless "+Lazy! sync" +qa`
4. **Install Treesitter parsers:**
   ```bash
   nvim --headless \
     -c "lua require('nvim-treesitter').install({'rust','lua','vim','vimdoc','query'}):wait(300000)" \
     -c "qa"
   ```
5. **Verify:** `nvim --headless -c "lua print(vim.g.colors_name or 'NONE')" -c "qa"`
   should print `ayu`.

## Keybindings

| Key            | Action                            |
|----------------|-----------------------------------|
| `<Space>e`     | Toggle file explorer (nvim-tree)  |
| `<Space>ff`    | Find files (Telescope)            |
| `<Space>fg`    | Live grep (Telescope, needs rg)   |
| `<Space>fb`    | Switch buffers (Telescope)        |

Inside nvim-tree: `Enter` open, `a` create, `d` delete, `r` rename, `H` toggle hidden, `q` quit, `?` all keys.
Inside Telescope: type to filter, `Enter` open, `Esc` close.

> No in-editor terminal plugin by design — use a tmux/psmux pane (or your terminal's
> splits) for a shell. This keeps the config minimal and editor-agnostic.

## Verification checklist (for agents)

After install, confirm each item before declaring success:

1. `nvim --version | Select-Object -First 1` (Windows) / `nvim --version | head -1`
   (Linux) reports >= 0.12
2. Required tools on PATH: `nvim`, `tree-sitter`, `ripgrep`/`rg`, `gcc`, `make`,
   `git`, `curl`, `tar`
3. `nvim --headless -c "lua print(vim.g.colors_name or 'NONE')" -c "qa"` prints `ayu`
4. Plugin dir contains: `lazy.nvim`, `neovim-ayu`, `lualine.nvim`,
   `nvim-tree.lua`, `nvim-web-devicons`, `nvim-treesitter`, `plenary.nvim`,
   `telescope.nvim`, `telescope-fzf-native.nvim`
   - Linux: `~/.local/share/nvim/lazy/`
   - Windows: `~\AppData\Local\nvim-data\lazy\`
5. Open a `.rs` file: `nvim some_file.rs` — highlighting + absolute line numbers present.

## Troubleshooting

- **`Too many rounds of missing plugins` / plugin won't clone:** a repo URL in
  `init.lua` is wrong or the network blocked it. Check each entry under the
  `lazy.setup` table.
- **`module 'nvim-treesitter.configs' not found`:** you are reading docs for the
  OLD nvim-treesitter API. The plugin was rewritten; the main branch uses
  `require('nvim-treesitter').install{...}` and `vim.treesitter.start()` (as in
  this `init.lua`). Do NOT switch back to `configs.setup({ highlight = ... })`.
- **Treesitter parsers fail to compile:** ensure `tree-sitter-cli` AND a C
  compiler (`gcc`/`clang`/MSVC) are installed and on PATH.
- **Windows: `make` not found for telescope-fzf-native:** run
  `scoop install make gcc`, then re-open nvim and `:Lazy build telescope-fzf-native.nvim`.
- **Icons show as boxes in lualine/nvim-tree:** install a Nerd Font and set it in
  your terminal. Non-blocking — everything else works without it.
- **Debian/Ubuntu `neovim` too old (< 0.12):** use the official AppImage from
  https://github.com/neovim/neovim/releases (stable).

## Notes / customisation

- Theme variant: edit `require("ayu").setup({ mirage = ... })` and the
  `vim.cmd("colorscheme ayu-dark")` line in `init.lua` (`ayu-mirage` / `ayu-light`).
- More Treesitter languages: append to the `install { ... }` table **and** the
  `FileType` autocmd `pattern` list in `init.lua`.
- Line numbers are absolute; set `vim.o.relativenumber = true` for relative.
