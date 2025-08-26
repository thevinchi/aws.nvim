
# aws.nvim

A Neovim plugin for interacting with AWS services.

**NOTE:** The `main` branch is stable, but the project is in early development. Therefore this plugin is currently only targetted at `tmux` users like me. Though I absolutely plan to add support for regular nvim termial buffers (but likely this will come after support for the [folke/snacks.nvim](https://github.com/folke/snacks.nvim) terminal because it's way easier and pretty and I already require it as a dependency).

## Features

*   Tail AWS CloudWatch logs directly within Neovim.
*   Each live tail is spawned in a new `tmux` pane for easy management.
*   Interactive pickers for selecting log groups and streams.
*   List and preview active log tails without leaving Neovim.

## Requirements

*   [aws-cli](https://aws.amazon.com/cli/)
*   [neovim >= 0.8.0](https://github.com/neovim/neovim/releases/tag/v0.8.0)
*   [folke/snacks.nvim](https://github.com/folke/snacks.nvim) (for the `AwsCloudWatchTailShow` command)
*   `tmux`

## 📦 Installation

Using `lazy.nvim`:

```lua
return {
    'thevinchi/aws.nvim',
    opts = {},
    dependencies = {
        'folke/snacks.nvim'
    },
    keys = {
        { '<leader>A',   '',                                             desc = 'AWS' },
        { '<leader>Ar',  '<cmd>AwsSetRegion<CR>',                        desc = 'Set default Region' },
        { '<leader>Ac',  '',                                             desc = 'CloudWatch' },
        { '<leader>Acg', '<cmd>AwsCloudWatchTailGroup<CR>',              desc = 'Tail a Log Group' },
        { '<leader>AcG', '<cmd>AwsCloudWatchTailGroup interactive<CR>',  desc = 'Tail a Log Group interactively' },
        { '<leader>Acs', '<cmd>AwsCloudWatchTailStream interactive<CR>', desc = 'Tail a Log Stream interactively' },
        { '<leader>Acl', '<cmd>AwsCloudWatchTailShow<CR>',               desc = 'List live tails' },
    }
}
```

## 🚀 Usage

### Commands
 
*   `:AwsSetRegion`: Set the default AWS region for all commands.
*   `:AwsCloudWatchTailGroup [interactive]`: Tail a CloudWatch Log Group. Opens a picker to select a log group. If `interactive` is passed, the tail will start in interactive mode.
*   `:AwsCloudWatchTailStream [interactive]`: Tail a CloudWatch Log Stream. Opens pickers to select a log group and then a log stream. If `interactive` is passed, the tail will start in interactive mode.
*   `:AwsCloudWatchTailShow`: Show active CloudWatch log tails in a picker with previews. This allows you to quickly view the current contents of each live tail feed without leaving Neovim.

## Roadmap

*   **EC2 Instance Management**: Fetch a list of EC2 instances and connect to them using `aws ssm start-session`.
*   **ECS Integration**: Execute commands and tail logs from containers running in ECS tasks.
*   **Terminal Support**: Add support for the `terminal` component of `snacks.nvim` as an alternative to `tmux`.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## 📄 License

MIT
