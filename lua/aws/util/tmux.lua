---@class aws.util.tmux
local M = {}

local util = require 'aws.util'

---@class tmux_pane
---@field id string
---@field window string
---@field title string
---@field start_command string
---@field tty string

---@class tmux_panes
---@field group string
---@field panes tmux_pane[]


---@overload fun(opts: {group:string}): tmux_panes|nil
---@overload fun(opts: {group:string, command:string}): tmux_pane|nil
local function get_panes_in_window(opts)
    local command = {
        'tmux',
        'list-panes',
        '-s',
        '-F',
        '#{pane_id}\t#{window_id}\t#{pane_title}\t#{pane_start_command}\t#{pane_tty}',
        '-f',
        string.format(
            '#{&&:#{==:#{pane_start_path},%s},#{m/r:^"?%s,#{pane_start_command}}}',
            vim.env.PWD or vim.fn.getcwd(),
            opts.group
        )
    }

    local result = vim.system(command, { text = true }):wait()

    if result.code ~= 0 then
        return util.error(result.stderr or result.stdout or 'Error getting tmux panes')
    end

    ---@type tmux_panes
    local tmux_panes = { group = opts.group, panes = {} }
    for line in string.gmatch(result.stdout, '[^\r\n]+') do
        local id, window, title, start_command, tty = string.match(line, '^(.+)\t(.+)\t"?([^"]+)"?\t"?([^"]+)"?\t(.+)$')
        if not opts.command or opts.command == start_command then
            table.insert(tmux_panes.panes, {
                id = id,
                window = window,
                title = title,
                command = start_command,
                tty = tty,
            })
        end
    end

    if not opts.command then
        return tmux_panes
    elseif not tmux_panes.panes then
        return nil
    else
        return tmux_panes.panes[1]
    end
end


---@param opts {group: string, title:string, command:string, callback?:function, pane?:tmux_pane}
function M.open(opts)
    local pane = opts.pane or get_panes_in_window { group = opts.group, command = opts.command }

    local command
    if not pane then
        command = { 'tmux', 'split-window', '-d', opts.command }
    else
        command = { 'tmux', 'select-window', '-t', pane.window, ';', 'select-pane', '-t', pane.id }
    end

    local result = vim.system(command, { text = true }):wait()

    if result.code ~= 0 then
        return util.error(result.stderr or result.stdout or 'Error opening tmux pane')
    end

    if not pane then
        pane = get_panes_in_window { group = opts.group, command = opts.command }
        if pane then
            result = vim.system({ 'tmux', 'select-pane', '-t', pane.id, '-T', opts.title }, { text = true }):wait()
        end
    end

    if opts.callback then vim.schedule(opts.callback) end
end

---@param opts {group: string}
---@return tmux_panes|nil
function M.list(opts)
    return get_panes_in_window { group = opts.group }
end

---@param opts {pane: tmux_pane}
---@return string|nil
function M.capture(opts)
    local result = vim.system({ 'tmux', 'capture-pane', '-t', opts.pane.id, '-pJ' }, { text = true }):wait()

    if result.code ~= 0 then
        return util.error(result.stderr or result.stdout or 'Error opening tmux pane')
    end

    return result.stdout
end

return M
