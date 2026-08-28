return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = vim.fn.has("win32") == 1
				and "gcc -O3 -Wall -fpic -std=gnu99 -shared src/fzf.c -o build/libfzf.dll"
				or "make",
			cond = function()
				return vim.fn.executable("gcc") == 1 or vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
	},
	config = function()
		local Path = require("plenary.path")
		local uv = vim.uv or vim.loop

		-- Safe patch for plenary.path:readbyterange on Windows to handle locked/unreadable files gracefully
		Path.readbyterange = function(self, offset, length)
			local fd = uv.fs_open(self:_fs_filename(), "r", 438)
			if not fd then
				return nil
			end

			local stat_ok, stat = pcall(uv.fs_fstat, fd)
			if not stat_ok or not stat or stat.type ~= "file" then
				pcall(uv.fs_close, fd)
				return nil
			end

			if offset < 0 then
				offset = stat.size + offset
				if offset < 0 then
					offset = 0
				end
			end

			local data = ""
			while #data < length do
				local read_ok, read_chunk = pcall(uv.fs_read, fd, length - #data, offset)
				if not read_ok or not read_chunk or #read_chunk == 0 then
					break
				end
				data = data .. read_chunk
				offset = offset + #read_chunk
			end

			pcall(uv.fs_close, fd)
			return data
		end

		local telescope = require("telescope")

		telescope.setup({
			defaults = {
				path_display = { "truncate" },
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		})

		pcall(telescope.load_extension, "fzf")

	end,
}
