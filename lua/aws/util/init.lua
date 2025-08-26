---@class aws.util
---@field default_region nil|string
local M = {}

M.default_region = nil

---@class aws.util.options
---@field terminals string -- choices:[tmux|snacks|nvim]
M.options = {
    terminals = 'tmux'
}

---@param msg string
function M.error(msg) vim.schedule(function() vim.notify(msg, vim.log.levels.ERROR) end) end

---@param msg string
function M.warn(msg) vim.schedule(function() vim.notify(msg, vim.log.levels.WARN) end) end

---@param msg string
function M.info(msg) vim.schedule(function() vim.notify(msg, vim.log.levels.INFO) end) end

---@param opts? { callback?:function }
function M.set_region(opts)
    vim.ui.input({ prompt = 'Enter AWS region: ', default = M.default_region }, function(input)
        if not input or input == '' then return M.warn('No region was set') end

        vim.system({ 'aws', 'ec2', 'describe-regions', '--region-names', input }, { text = true }, function(result)
            if result.code ~= 0 then return M.error(result.stderr or result.stdout or 'Invalid Region') end

            local output = vim.json.decode(result.stdout)
            if output.Regions[1].OptInStatus == 'not-opted-in' then
                return M.error('Your AWS account has not opted-in to that Region')
            end

            if opts and opts.callback then
                vim.schedule_wrap(opts.callback)(output.Regions[1].RegionName)
            else
                M.default_region = output.Regions[1].RegionName
                M.info('Default Region set to ' .. M.default_region)
            end
        end)
    end)
end

function M.get_region()
    vim.system({ 'aws', 'configure', 'get', 'region' }, { text = true }, function(result)
        if result.code ~= 0 then return end
        M.default_region = string.gsub(result.stdout, '[\r\n]', '')
    end)
end

return M
