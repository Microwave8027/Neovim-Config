return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = false,
	priority = 1000,
	opts = {
		variant = "main", -- "main" (dark rose), "moon" (cool dark), or "dawn" (light)
		dark_variant = "main",
		styles = {
			bold = true,
			italic = true,
			transparency = false,
		},
	},
	config = function(_, opts)
		require("rose-pine").setup(opts)
		vim.cmd("colorscheme rose-pine")
	end,
}
