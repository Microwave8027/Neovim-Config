return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local ts = require("nvim-treesitter")
		ts.setup()

		local ok_installed, installed = pcall(ts.get_installed)
		if ok_installed and type(installed) == "table" then
			local needed = { "c", "rust", "python", "lua", "vim", "vimdoc", "query", "markdown" }
			local missing = {}
			for _, lang in ipairs(needed) do
				if not vim.list_contains(installed, lang) then
					table.insert(missing, lang)
				end
			end
			if #missing > 0 then
				ts.install(missing)
			end
		end
	end,
}
