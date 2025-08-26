---@class aws.cloudwatch
local M = {}

local util = require 'aws.util'
local tmux = require 'aws.util.tmux'

local options = util.options

---@class log_group
---@field logGroupName string
---@field logGroupArn string
---@field logGroupClass string

---@class log_groups
---@field logGroups log_group[]

---@class log_stream
---@field logStreamName string
---@field logStreamArn string
---@field logStreamTimestamp string

---@class log_streams
---@field logStreams log_stream[]

---@param opts { region:string, callback:function }
local function pick_log_group(opts)
    util.info('Querying AWS for CloudWatch Log Groups\nRegion: ' .. opts.region)

    vim.system({ 'aws', '--region', opts.region, 'logs', 'list-log-groups' }, { text = true }, function(result)
        if result.code ~= 0 then
            return util.error(result.stderr or result.stdout or 'Unable to list-log-groups')
        end

        ---@type log_groups
        local log_groups = vim.json.decode(result.stdout)

        vim.schedule(function()
            vim.ui.select(
                log_groups.logGroups,
                {
                    prompt = 'Select a Log Group',
                    format_item = function(item) return item.logGroupName end,
                },
                function(item) vim.schedule_wrap(opts.callback)(item) end
            )
        end)
    end)
end

---@param opts { region:string, log_group:log_group, callback:function }
local function pick_log_stream(opts)
    util.info(
        'Querying AWS for CloudWatch Log Streams\nRegion: ' ..
        opts.region .. '\nLog Group: ' .. opts.log_group.logGroupName
    )

    local command = {
        'aws',
        '--region',
        opts.region,
        'logs',
        'describe-log-streams',
        '--log-group-identifier',
        opts.log_group.logGroupArn,
        '--order-by',
        'LastEventTime',
        '--descending'
    }

    vim.system(command, { text = true }, function(result)
        if result.code ~= 0 then
            return util.error(result.stderr or result.stdout or 'Unable to describe-log-streams')
        end

        local output = vim.json.decode(result.stdout)

        ---@type log_streams
        local log_streams = { logStreams = {} }
        for _, stream in ipairs(output.logStreams) do
            if stream.lastEventTimestamp then
                table.insert(log_streams.logStreams, {
                    logStreamName = stream.logStreamName,
                    logStreamArn = stream.arn,
                    logStreamTimestamp = stream.lastEventTimestamp
                })
            end
        end

        vim.schedule(function()
            vim.ui.select(
                log_streams.logStreams,
                {
                    prompt = 'Select a Log Stream',
                    format_item = function(item)
                        return string.format(
                            '%s (%s)',
                            item.logStreamName,
                            os.date('%Y-%m-%d %H:%M:%S', item.logStreamTimestamp / 1000)
                        )
                    end,
                },
                function(item) vim.schedule_wrap(opts.callback)(item) end
            )
        end)
    end)
end

---@param opts {region:string, log_group:log_group, log_stream?:log_stream, interactive:boolean}
local function tail(opts)
    local terminal_group = 'aws logs start-live-tail'

    local terminal_command = terminal_group ..
        ' --region ' .. opts.region .. ' --log-group-identifiers ' .. opts.log_group.logGroupArn

    local terminal_title = opts.log_group.logGroupName
    if opts.log_stream then
        terminal_title = opts.log_stream.logStreamName
        terminal_command = terminal_command .. ' --log-stream-names ' .. opts.log_stream.logStreamName
    end

    if opts.interactive then
        terminal_command = terminal_command .. ' --mode interactive'
    else
        terminal_command = terminal_command .. ' --mode print-only'
    end

    tmux.open { group = terminal_group, title = terminal_title, command = terminal_command }
end

---@param args vim.api.keyset.create_user_command.command_args
function M.tail_log_group(args)
    ---@type boolean
    local interactive
    if args.fargs[1] then interactive = true else interactive = false end

    local function set_group(region)
        pick_log_group {
            region = region,
            callback = function(log_group)
                tail { region = region, log_group = log_group, interactive = interactive }
            end,
        }
    end

    util.set_region { callback = set_group }
end

---@param args vim.api.keyset.create_user_command.command_args
function M.tail_log_stream(args)
    ---@type boolean
    local interactive
    if args.fargs[1] then interactive = true else interactive = false end

    local function set_stream(region, log_group)
        pick_log_stream {
            region = region,
            log_group = log_group,
            callback = function(log_stream)
                tail { region = region, log_group = log_group, log_stream = log_stream, interactive = interactive }
            end,
        }
    end

    local function set_group(region)
        pick_log_group {
            region = region,
            callback = function(log_group) set_stream(region, log_group) end,
        }
    end

    util.set_region { callback = set_group }
end

function M.tail_log_list()
    local panes = tmux.list({ group = 'aws logs start-live-tail' })
    if not panes then
        return util.warn('No CloudWatch tails are active')
    end

    local picker = require 'snacks.picker'

    local items = {}
    for idx, item in ipairs(panes.panes) do
        table.insert(items, {
            formatted = item.title,
            text = idx .. ' ' .. item.title,
            item = item,
            idx = idx,
        })
    end


    picker.pick {
        title = 'CloudWatch Live Tails',
        items = items,
        format = picker.format.ui_select(nil, #items),
        preview = function(ctx)
            ctx.preview:reset()
            ctx.preview:set_title(ctx.item.item.title)

            local capture = tmux.capture { pane = ctx.item.item }
            if not capture then
                ctx.preview:notify('Unable to capture pane from tmux')
            else
                ctx.preview:set_lines(vim.split(capture, '\n'))
            end
        end,
        focus = 'list',
        layout = { preset = "sidebar" },
        actions = {
            confirm = function(_picker, item)
                _picker:close()
                vim.schedule_wrap(tmux.open) { pane = item.item }
            end,
        },
    }
end

return M
