vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

local function normalize_path(path)
  if not path or path == "" then
    return ""
  end
  local expanded = vim.fn.fnamemodify(path, ":p")
  local normalized = vim.fs.normalize(expanded)
  if vim.fn.has("win32") == 1 then
    normalized = normalized:lower()
  end
  return normalized
end

local function is_buf_in_harpoon(bufnr)
  local ok, harpoon = pcall(require, "harpoon")
  if not ok or not harpoon then
    return false
  end

  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  if buf_name == "" then
    return false
  end

  local target_path = normalize_path(buf_name)
  if target_path == "" then
    return false
  end

  local lists_to_check = {}

  local ok_list, list = pcall(function()
    return harpoon:list()
  end)
  if ok_list and list then
    table.insert(lists_to_check, list)
  end

  if type(harpoon.lists) == "table" then
    for _, l in pairs(harpoon.lists) do
      if l and l ~= list then
        table.insert(lists_to_check, l)
      end
    end
  end

  for _, l in ipairs(lists_to_check) do
    local items = l.items
    if type(items) == "table" then
      for _, item in ipairs(items) do
        local raw_path = ""
        if type(item) == "string" then
          raw_path = item
        elseif type(item) == "table" then
          raw_path = item.value or item.filename or item.name or ""
        end

        if raw_path ~= "" and normalize_path(raw_path) == target_path then
          return true
        end
      end
    end
  end

  return false
end

local function is_file_on_disk(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false
  end
  local uv = vim.uv or vim.loop
  local stat = uv.fs_stat(name)
  return stat ~= nil
end

local function auto_save_buf(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  if not vim.bo[bufnr].modified or vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return
  end

  pcall(function()
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent! update")
    end)
  end)
end

local function clean_buffers()
  -- Auto-save any inactive modified buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local is_visible = #vim.fn.win_findbuf(bufnr) > 0
      if not is_visible then
        auto_save_buf(bufnr)
      end
    end
  end

  -- Clean inactive/hidden buffers not meeting requirements
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_visible = #vim.fn.win_findbuf(bufnr) > 0
      local in_harpoon = is_buf_in_harpoon(bufnr)

      -- Buffer must satisfy at least one requirement:
      -- 1. Marked in Harpoon
      -- 2. Visible in an active window
      if not is_visible and not in_harpoon then
        local buftype = vim.bo[bufnr].buftype
        local buflisted = vim.bo[bufnr].buflisted

        -- Ignore unlisted plugin helper buffers (e.g. notifications, floating popups)
        if buflisted or buftype == "" or vim.api.nvim_buf_get_name(bufnr) == "" then
          local on_disk = is_file_on_disk(bufnr)
          if not on_disk then
            -- Remove new file not on disk
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
          elseif not vim.bo[bufnr].modified then
            -- Remove inactive buffer with no changes
            pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
          end
        end
      end
    end
  end
end

local augroup = vim.api.nvim_create_augroup("BufferLifecycleManager", { clear = true })

vim.api.nvim_create_autocmd({ "FocusLost" }, {
  group = augroup,
  callback = function(args)
    auto_save_buf(args.buf)
  end,
})

local cleanup_timer = nil
vim.api.nvim_create_autocmd({ "FocusLost", "BufHidden" }, {
  group = augroup,
  callback = function()
    if cleanup_timer then
      cleanup_timer:stop()
    end
    cleanup_timer = vim.defer_fn(function()
      clean_buffers()
      cleanup_timer = nil
    end, 1000)
  end,
})

-- Python Virtual Environment Auto-Activation
local function activate_python_venv(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local dir = (bufname ~= "") and vim.fs.dirname(bufname) or vim.fn.getcwd()

  local match = vim.fs.find({ ".venv", "venv" }, {
    upward = true,
    path = dir,
    type = "directory",
  })[1]

  if not match then
    return
  end

  local is_win = vim.fn.has("win32") == 1
  local bin_dir = is_win and vim.fs.joinpath(match, "Scripts") or vim.fs.joinpath(match, "bin")
  local python_exe = is_win and vim.fs.joinpath(bin_dir, "python.exe") or vim.fs.joinpath(bin_dir, "python")

  if not vim.uv.fs_stat(python_exe) then
    return
  end

  local norm_match = normalize_path(match)
  local norm_current = vim.env.VIRTUAL_ENV and normalize_path(vim.env.VIRTUAL_ENV) or nil

  if norm_current == norm_match then
    return
  end

  -- Update PATH: remove previous venv bin if present, prepend new bin
  local path_sep = is_win and ";" or ":"
  local old_bin = vim.env.VIRTUAL_ENV
    and (is_win and vim.fs.joinpath(vim.env.VIRTUAL_ENV, "Scripts") or vim.fs.joinpath(vim.env.VIRTUAL_ENV, "bin"))
  local norm_old_bin = old_bin and normalize_path(old_bin) or nil
  local norm_new_bin = normalize_path(bin_dir)

  local raw_paths = vim.split(vim.env.PATH or "", path_sep, { trimempty = true })
  local filtered_paths = {}
  for _, p in ipairs(raw_paths) do
    local np = normalize_path(p)
    if np ~= norm_old_bin and np ~= norm_new_bin then
      table.insert(filtered_paths, p)
    end
  end
  table.insert(filtered_paths, 1, bin_dir)

  vim.env.PATH = table.concat(filtered_paths, path_sep)
  vim.env.VIRTUAL_ENV = match
  vim.g.python3_host_prog = python_exe

  vim.notify("Activated virtualenv: " .. match, vim.log.levels.INFO, { title = "Python Venv" })
end

local venv_augroup = vim.api.nvim_create_augroup("PythonVenvManager", { clear = true })

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = venv_augroup,
  callback = function(args)
    if vim.bo[args.buf].filetype == "python" then
      activate_python_venv(args.buf)
    end
  end,
})

vim.api.nvim_create_user_command("VenvActivate", function()
  activate_python_venv()
end, { desc = "Activate Python virtual environment from current file/dir" })

