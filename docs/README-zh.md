# simple-note.nvim

Neovim 本地笔记工作流：vault、日记、模板、TOML frontmatter 和 Snacks 欢迎页入口。

> 状态：可用；已在 Neovim 0.12.6 + AstroNvim v6 验证。
> 插件刻意保持轻量：启动只加载轻量模块，命令核心在首次实际使用时加载。

## 功能

- 打开 vault，优先最近打开过的库内文件
- 今天/日记，支持偏移天数和可选后缀
- 从模板新建笔记，支持子目录
- 对当前笔记增量套用模板，合并 TOML frontmatter
- 在当前 Markdown 文件顶部插入 TOML frontmatter
- Snacks dashboard 入口（默认 `v`）
- `:Snote <Tab>` 补全子命令和模板名
- `:Snote reload`，无需重启 Neovim

## 要求

- Neovim 0.10+（已在 0.12.6 验证）
- 可选：[`snacks.nvim`](https://github.com/folke/snacks.nvim)，用于欢迎页入口
- 可选：`markdown-frontmatter-complete.nvim`，用于 blink.cmp frontmatter 补全

`simple-note.nvim` 不依赖 MFC。已安装 MFC 时，`:Snote reload` 会顺带重载/重建 MFC。

## 安装

### lazy.nvim

```lua
{
  "isaccseter/simple-note.nvim",
  name = "simple-note.nvim",
  main = "simple-note",
  lazy = false, -- 启动时要加载轻量模块，才能注册欢迎页入口
  opts = {
    vault = vim.fn.expand "~/SCH",
    welcome = true,
    welcome_action = "today",
  },
}
```

`lazy = false` 不会在启动时加载命令核心。启动只加载 `config`、`commands`、`welcome`；`simple-note.core` 和 `simple-note.templates` 在首次 `:Snote` 或模板补全时才加载。

### 关闭欢迎页

```lua
{
  "isaccseter/simple-note.nvim",
  name = "simple-note.nvim",
  main = "simple-note",
  lazy = true,
  cmd = { "Snote" },
  opts = { vault = vim.fn.expand "~/SCH", welcome = false },
}
```

Lazy 的 `cmd` stub 仍然支持 `:Snote <Tab>`：补全会加载插件，然后返回子命令/模板名。

## 快速开始

```vim
:Snote vault
:Snote today
:Snote today morning
:Snote daily
:Snote daily 0
:Snote daily 1
:Snote daily 0 review
:Snote new Project/Idea
:Snote ntemplate project "New Project"
:Snote template meeting
:Snote homepage
:Snote frontmatter
```

- `:Snote daily` 无参数是**昨天**
- `:Snote daily 0` 今天，`1` 明天，`-1` 昨天
- `:Snote new` 没有 title 时用 `Untitle`，除非模板提供 `basename`
- `:Snote template` 作用于**当前文件**，当前文件必须在 vault 内

## 命令

| 命令 | 参数 | 说明 |
| --- | --- | --- |
| `:Snote vault` | 无 | 优先最近打开的库内文件；否则创建/打开 `Untitle.md`。`cd` 到 vault 根目录，在新 tab 打开。 |
| `:Snote today` | `[input]` | 创建/打开今天的日记。`input` 取最后一个清洗后的路径段，在 `basename` 中变成 `-input` 后缀。 |
| `:Snote daily` | `[n] [input]` | 带整数偏移的日记。默认 `n = -1`（昨天）。`input` 只取最后一段。 |
| `:Snote homepage` | 无 | 打开配置的 homepage，`cd` 到文件所在目录，在新 tab 打开。 |
| `:Snote frontmatter` | 无 | 在当前 Markdown 文件顶部插入 TOML frontmatter 块。 |
| `:Snote new` | `[title]` | 从 `defaultnew_template` 新建。`title` 可含 `/` 表示子目录。 |
| `:Snote ntemplate` | `<template> [title]` | 从指定模板新建。模板必须存在，不会自动创建。 |
| `:Snote template` | `<template>` | 对 vault 内的当前文件套用模板，合并 frontmatter 并追加正文。 |
| `:Snote reload` | 无 | 重载 SNn 模块、重扫模板，并在已安装时重载/重建 MFC。不刷新欢迎页。 |

### 说明

- 所有会创建笔记的命令都会开**新 tab**，并把 cwd 切到 vault 根目录。
- `new` / `ntemplate` 打开后光标在最后一行。
- `new` 重名时追加 `-1`、`-2`……
- 最终文件名以 `.` 开头会被拒绝。
- 绝对路径和 `..` 会被拒绝。
- `title` 路径按段清洗；允许字母、数字、CJK、`-`、`_`、`.`、`(`、`)`、`[`、`]`。
- 日期格式是字面 token 替换：`YYYY`、`YY`、`MM`、`DD`、`HH`、`mm`、`ss`。不做格式校验或修复。

## 配置

默认值在 `lua/simple-note/config.lua`。

| 配置 | 默认 | 说明 |
| --- | --- | --- |
| `vault` | `nil` | vault 根目录。`nil`/空时回退到 `~/Vault`。 |
| `homepage` | `nil` | homepage 的相对路径，`:Snote homepage` 需要。 |
| `welcome` | `true` | 注册 Snacks dashboard 入口。 |
| `welcome_action` | `"today"` | `today`、`homepage` 或 `last`；`last` 等同打开 vault。 |
| `welcome_key` | `"v"` | 欢迎页按键。 |
| `welcome_label` | `"Open My Vault"` | 欢迎页文字。 |
| `welcome_icon` | `"󰉋"` | 欢迎页图标。 |
| `notice_missing_welcome` | `true` | Snacks 不可用时提示一次。 |
| `daily_dir` | `"Daily"` | 日记目录，相对 vault。 |
| `templates_dir` | `"Templates"` | 模板目录，相对 vault。 |
| `daily_template` | `"daily.md"` | 默认日记模板，缺失时自动创建。 |
| `defaultnew_template` | `"default-new.md"` | 默认新建模板，缺失时自动创建。 |
| `frontmatter_extensions` | `{ "md" }` | `:Snote frontmatter` 接受的后缀。 |
| `substitute_key` | `{ "status", "created", "type" }` | 套用模板时直接替换、不追加成数组的 key。 |
| `date_format` | `"YYYY-MM-DD"` | `{{date}}` 和日记目标日期使用。 |
| `time_format` | `"HH:mm"` | `{{time}}` 使用。 |
| `timestamp_format` | `"YYYY-MM-DD HH:mm"` | `{{timestamp}}` 使用。 |

vault、`Daily/`、`Templates/` 在首次命令使用时创建。启动不碰它们。

## 模板

模板放在 vault 的 `Templates/` 下，必须是 TOML frontmatter 的 Markdown：

```markdown
+++
type = "project"
created = {{date}}
tags = ["project"]
basename = "{{title}}"
+++

## Goal
```

### 变量

| 变量 | 说明 |
| --- | --- |
| `{{date}}` | 当前日期，使用 `date_format`。 |
| `{{date:YYYY/MM/DD}}` | 当前日期，自定义 token 格式。 |
| `{{time}}` | 当前时间，使用 `time_format`。 |
| `{{time:HH:mm}}` | 当前时间，自定义 token 格式。 |
| `{{timestamp}}` | 当前时间，使用 `timestamp_format`；不接受参数。 |
| `{{input}}` | 最后一个路径段/title input；**只在 `basename` 内解析**。 |
| `{{hinput}}` | `-input`；**只在 `basename` 内解析**，input 为空时为空。 |
| `{{uinput}}` | `_input`；**只在 `basename` 内解析**，input 为空时为空。 |
| `{{title}}` | 目标文件确定后的文件名主干。 |
| `{{daily_date}}` | 日记目标日期；只在 `today`/`daily` 有值，其他命令原样保留。 |

未知变量和无效形式原样保留为 `{{...}}`。

`{{input}}`、`{{hinput}}`、`{{uinput}}` 是特殊变量：**只在渲染 `basename` 时解析**。出现在 frontmatter 或正文中时，仍然保留为字面 `{{input}}` / `{{hinput}}` / `{{uinput}}`。

### `basename`

`basename` 是模板专用元数据：

- 从生成文件的 frontmatter 中删除。
- 决定 `new`、`ntemplate`、`today`、`daily` 的文件名。
- 省略时：`new`/`ntemplate` 用 title 或 `Untitle`；日记用目标日期。
- 用同样的变量渲染，然后清洗。
- 最终名以 `.` 开头会被拒绝。

当前文件自己的 `basename` 在 `:Snote template` 中**保留**；只有模板的 `basename` 是元数据。

### 套用模板

`:Snote template <name>` 把模板 frontmatter 合并到当前文件：

- 模板有 `+++` 块、当前文件没有：在顶部创建块，key 可以为空；块和原内容之间插入一个空行。
- 模板没有块：不添加。
- 当前缺少的 key：在第一个 table header 之前添加。
- `substitute_key` 中的 key：替换当前值。
- 任一侧是 boolean：替换为模板值。
- 两边都是数组：追加模板元素。
- 当前是数组、模板是标量：追加标量。
- 当前是标量、模板是数组：转成数组再追加。
- 两边都是标量：把当前值转成数组再追加。
- 当前值或模板值是复杂值：跳过该 key。
- 正文：追加到末尾；只有结果非空且末尾不是空行时才补一个空行。
- 首行 `---` 的 YAML frontmatter 会被拒绝；TOML 必须用 `+++`。
- frontmatter 格式错误/未闭合时，在修改缓冲区之前中止。

`:Snote template` 不会自动保存；请检查后自己 `:write`。

## 欢迎页

SNn 在启动时向 `Snacks.config.dashboard.preset.keys` 追加一个条目：

```lua
{ key = "v", desc = "Open My Vault  ", icon = "󰉋", action = ":Snote today" }
```

- Snacks 未安装/未加载时提示一次（除非 `notice_missing_welcome = false`），并在 `VimEnter` 重试。
- `welcome = false` 同时关闭入口和缺 Snacks 提示。
- `:Snote reload` 不重建欢迎页条目；重启 Neovim 才会刷新。

## 加载与 reload

- `lazy = false`：启动加载轻量模块（`config`、`commands`、`welcome`）。
- `simple-note.core` 和 `simple-note.templates` 在首次真实命令或模板补全时加载。
- `:Snote reload` 清掉 `package.loaded` 中的 `simple-note.*`，用保存的 opts 重新 setup，下次核心加载时重扫模板，并在可用时重载/重建 MFC。

## 开发

```sh
cd ~/.config/nvim/.works
mise run check
```

测试使用临时 vault，不会碰 `~/SCH`：

```sh
nvim --headless -i NONE \
  -c "luafile $PWD/simple-note.nvim/lua/simple-note/tests/p8_review.lua" +qa
```

- `p1_smoke.lua`：轻量加载、命令框架、补全
- `p2_smoke.lua`：vault/daily/new/frontmatter
- `p3_smoke.lua`：模板合并、数组、注释、YAML、table
- `p4_smoke.lua`：欢迎页、补全、reload
- `p8_review.lua`：oldfiles、无 basename 日记、无 title 新建、空行复用、缺失 homepage
