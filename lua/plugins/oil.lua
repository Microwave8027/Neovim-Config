return {
	"stevearc/oil.nvim",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {},
	-- Optional dependencies
	-- dependencies = { { "nvim-mini/mini.icons", opts = {} } },
	dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
	config = function()
		require("oil").setup({
			default_file_explorer = true,
			delete_to_trash = true,
			keymaps = {
				["<leader>b"] = { "actions.parent", mode = "n" },
				["<leader>fe"] = { "actions.close", mode = "n" },
				["<CR>"] = { "actions.select", opts = { close = true } },
			},
			use_default_keymaps = true,
			float = {
				padding = 6,
				max_width = 140,
				max_height = 70,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
				preview_split = "right",
			},
		})
	end,
}
