local M = {}
local fzf_lua_ok, fzf_lua = pcall(require, 'fzf-lua')

-- unpack is going to be deprecated soon
local table_unpack = table.unpack or unpack -- 5.1 compatibility

if not fzf_lua_ok or not fzf_lua.live_grep then
  function M.search_notes(_, _, _)
    vim.notify("fzf-lua or fzf-lua.live_grep could not be loaded. Please ensure fzf-lua is correctly installed and updated.")
  end

  return M
end

local fzf_options = {
  ['--ansi'] = '',  -- Interpret ANSI color codes (though rg --color=never should prevent them)
  ['--multi'] = '', -- Allow selecting multiple items with Tab
  ['--info'] = 'inline',
  ['--tiebreak'] = 'length,begin',
}

local function key_handler(selected, note_key)
  local query = fzf_lua.get_last_query()
  vim.call("ZK_note_handler", { query, note_key, table_unpack(selected) })
end

function M.search_notes(_, create_note_key, yank_key, rg_options)
  fzf_lua.live_grep({
    prompt = 'Search> ',
    grep_cmd = "rg",
    grep_opts = table.concat(rg_options, " "),
    search_paths = vim.g.zk_search_paths,
    actions = {
      ['default'] = require('fzf-lua.actions').file_jump,
      [create_note_key] = function(selected, _)
        key_handler(selected, create_note_key)
      end,
      [yank_key] = function(selected, _)
        key_handler(selected, yank_key)
      end
    },

    fzf_opts = fzf_options,
  })
end

return M
