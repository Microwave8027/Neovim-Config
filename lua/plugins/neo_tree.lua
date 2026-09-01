return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons", -- optional, but recommended
		},
		lazy = false, -- neo-tree will lazily load itself
		config = function()
			require("neo-tree").setup({
				opts = {
					window = {
						position = "right",
					},
					event_handlers = {
						{
							event = "file_opened",
							handler = function(file_path)
								-- Automatically close Neo-tree once a file is opened
								require("neo-tree.command").execute({ action = "close" })
							end,
						},
					},
				},
				filesystem = {
					commands = {
						-- Override single-item delete to skip confirmation prompt
						delete = function(state)
							local node = state.tree:get_node()
							if not node then return end

							vim.fn.delete(node.path, "rf")
							require("neo-tree.sources.manager").refresh(state.name)
						end,

						-- Override visual/multi-select delete to skip confirmation prompt
						delete_visual = function(state, selected_nodes)
							for _, node in ipairs(selected_nodes) do
							vim.fn.delete(node.path, "rf")
							end
							require("neo-tree.sources.manager").refresh(state.name)
						end,
					},
				},
			})
		end,
	},
}
