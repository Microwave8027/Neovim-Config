local keymap = vim.keymap.set

keymap("n", "<leader>fe", function()
	require("snacks").explorer()
end) -- Access the snack explorer
keymap("i", "jk", "<Esc>") -- Switches from normal insert to normal mode
keymap("n", "<leader>l", "$") -- Jumps to the end of the line
keymap("n", "<leader>w", vim.cmd.write, { desc = "save and write to disk" }) -- Writes the file to disk
keymap("n", "<leader>c", "<cmd>e<Space>$MYVIMRC<cr>", { desc = "open config file" })
keymap("n", "<leader>h", ":%s/", { desc = "look for words" })

-- Telescope
keymap("n", "<leader>ff", function()
	require("telescope.builtin").find_files()
end, { desc = "find files" })

-- Undo tree
keymap("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Open the undotree window" })

-- Harpoon v2
local harpoon = require("harpoon")
vim.keymap.set("n", "<leader>dh", function()
	harpoon:list():remove()
	vim.notify("Removed " .. vim.fn.expand("%:t") .. " from Harpoon")
end, { desc = "Harpoon remove current file" })
keymap("n", "<leader>a", function()
	require("harpoon"):list():add()
	vim.notify("Added " .. vim.fn.expand("%:t") .. " from harpoon")
end, { desc = "Harpoon add file" })
keymap("n", "<leader>hm", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon menu" })
keymap("n", "<leader>ll", function()
	require("harpoon"):list():next()
end, { desc = "Harpoon next" })
keymap("n", "<leader>hh", function()
	require("harpoon"):list():prev()
end, { desc = "Harpoon prev" })

-- Diagnostics & LSP Controls
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
keymap("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show Diagnostic Float" })
keymap("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic LocList" })
keymap("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP Server(s)" })

-- LSP Keymaps (Buffer-local on attach)
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(event)
		local map = function(mode, keys, func, desc)
			keymap(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		local telescope_ok, telescope_builtin = pcall(require, "telescope.builtin")

		if telescope_ok then
			map("n", "gd", telescope_builtin.lsp_definitions, "Goto Definition")
			map("n", "gr", telescope_builtin.lsp_references, "Goto References")
			map("n", "gi", telescope_builtin.lsp_implementations, "Goto Implementation")
			map("n", "gt", telescope_builtin.lsp_type_definitions, "Type Definition")
			map("n", "<leader>ds", telescope_builtin.lsp_document_symbols, "Document Symbols")
			map("n", "<leader>ws", telescope_builtin.lsp_dynamic_workspace_symbols, "Workspace Symbols")
		else
			map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
			map("n", "gr", vim.lsp.buf.references, "Goto References")
			map("n", "gi", vim.lsp.buf.implementation, "Goto Implementation")
			map("n", "gt", vim.lsp.buf.type_definition, "Type Definition")
		end

		map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
		map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
		map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
		map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
		map({ "n", "v" }, "<leader>f", function()
			local ok_conform, conform = pcall(require, "conform")
			if ok_conform then
				conform.format({ async = true, lsp_format = "fallback" })
			else
				vim.lsp.buf.format({ async = true })
			end
		end, "Format Buffer")
	end,
})
