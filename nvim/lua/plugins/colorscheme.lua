return {
  {
    "Shatur/neovim-ayu",
    opts = {
      mirage = true,
    },
    config = function(_, opts)
      require("ayu").setup(opts)
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-mirage",
    },
  },
}
