-- Neovim config: Rust-focused setup with Ayu (Rust Book) theme
-- Absolute line numbers, Treesitter highlighting, lazy.nvim, lualine,
-- nvim-tree (file explorer), telescope (fuzzy finder).

-- Basic options
vim.o.number = true
vim.o.relativenumber = false
vim.o.termguicolors = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.g.mapleader = " "
vim.o.hidden = true -- keep terminals in background when closed (toggleterm)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  -- Colorscheme: Ayu (matches mdBook/Rust Book "ayu" dark theme)
  {
    "Shatur/neovim-ayu",
    lazy = false,
    priority = 1000,
    config = function()
      require("ayu").setup({ mirage = false })
      vim.cmd("colorscheme ayu-dark")
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "ayu_dark" } },
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({})
    end,
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    },
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({})
      pcall(require("telescope").load_extension, "fzf")
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
    },
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  },

  -- Terminal (bottom, toggleable) + cargo keybinds
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping = false, -- we map <leader>t manually (avoids insert-mode space conflicts)
      direction = "horizontal", -- bottom terminal
      size = 15,
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
      close_on_exit = false, -- keep terminal open so cargo errors stay visible
    },
    keys = {
      { "<leader>t",  "<cmd>ToggleTerm<cr>",                 desc = "Toggle bottom terminal" },
      { "<leader>cb", '<cmd>TermExec cmd="cargo build"<cr>', desc = "cargo build" },
      { "<leader>cc", '<cmd>TermExec cmd="cargo check"<cr>', desc = "cargo check" },
      { "<leader>cr", '<cmd>TermExec cmd="cargo run"<cr>',   desc = "cargo run" },
      { "<leader>ct", '<cmd>TermExec cmd="cargo test"<cr>',  desc = "cargo test" },
      { "<leader>cl", '<cmd>TermExec cmd="cargo clippy"<cr>',desc = "cargo clippy" },
    },
  },
})

-- Install Treesitter parsers (no-op if already installed)
require("nvim-treesitter").install { "rust", "lua", "vim", "vimdoc", "query" }

-- Enable Treesitter highlighting
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust", "lua", "vim", "vimdoc", "query" },
  callback = function() vim.treesitter.start() end,
})

-- Terminal mode: Esc / jk to return to normal mode
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*toggleterm#*",
  callback = function()
    local opts = { buffer = 0 }
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
    vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
  end,
})
