return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
		},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			local mason = require("mason")
			local mason_lspconfig = require("mason-lspconfig")
			local lspconfig = require("lspconfig")

			mason.setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})

			-- Capabilities (integrate blink.cmp)
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok_blink, blink = pcall(require, "blink.cmp")
			if ok_blink then
				capabilities = blink.get_lsp_capabilities(capabilities)
			else
				local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
				if ok_cmp then
					capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
				end
			end

			-- Configure diagnostic display and signs
			vim.diagnostic.config({
				virtual_text = {
					spacing = 4,
					prefix = "●",
				},
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = {
					border = "rounded",
					source = "always",
				},
			})

			-- Setup diagnostic signs
			local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
			end

			-- Handlers for servers setup by mason-lspconfig
			mason_lspconfig.setup({
				ensure_installed = {
					"lua_ls",
					"pyright",
					"rust_analyzer",
					"clangd",
				},
				automatic_installation = true,
				handlers = {
					-- Default handler for installed servers
					function(server_name)
						lspconfig[server_name].setup({
							capabilities = capabilities,
						})
					end,

					-- Specific server customizations
					["lua_ls"] = function()
						lspconfig.lua_ls.setup({
							capabilities = capabilities,
							settings = {
								Lua = {
									diagnostics = {
										globals = { "vim" },
									},
									workspace = {
										checkThirdParty = false,
										library = {
											vim.env.VIMRUNTIME,
										},
									},
									telemetry = {
										enable = false,
									},
								},
							},
						})
					end,
					["pyright"] = function()
						lspconfig.pyright.setup({
							capabilities = capabilities,
							before_init = function(_, config)
								local venv = vim.env.VIRTUAL_ENV
								if not venv and config.root_dir then
									local match = vim.fs.find({ ".venv", "venv" }, {
										upward = true,
										path = config.root_dir,
										type = "directory",
									})[1]
									if match then
										venv = match
									end
								end

								if venv then
									local is_win = vim.fn.has("win32") == 1
									local py_path = is_win and vim.fs.joinpath(venv, "Scripts", "python.exe")
										or vim.fs.joinpath(venv, "bin", "python")
									if vim.uv.fs_stat(py_path) then
										config.settings = config.settings or {}
										config.settings.python = config.settings.python or {}
										config.settings.python.pythonPath = py_path
									end
								end
							end,
						})
					end,
				},
			})
		end,
	},
}
