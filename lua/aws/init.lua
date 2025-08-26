---@class aws
local M = {}


local util = require 'aws.util'
local cloudwatch = require 'aws.cloudwatch'


---@param opts aws.util.options
function M.setup(opts)
    util.options = vim.tbl_deep_extend('force', util.options, opts or {})
end

vim.api.nvim_create_user_command(
    'AwsSetRegion',
    util.set_region,
    { desc = 'Set a default AWS region for all commands' }
)

vim.api.nvim_create_user_command(
    'AwsCloudWatchTailGroup',
    cloudwatch.tail_log_group,
    { desc = 'Tail a CloudWatch Log Group', nargs = '*' }
)

vim.api.nvim_create_user_command(
    'AwsCloudWatchTailStream',
    cloudwatch.tail_log_stream,
    { desc = 'Tail a CloudWatch Log Stream', nargs = '*' }
)

vim.api.nvim_create_user_command(
    'AwsCloudWatchTailShow',
    cloudwatch.tail_log_list,
    { desc = 'Show Active CloudWatch Log Streams' }
)

vim.schedule(util.get_region)


return M
