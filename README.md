# simple-note.nvim

Local-first note workflow for Neovim: vault, daily notes, templates, TOML frontmatter, and a dashboard entry.

> Status: usable, tested with Neovim 0.12.6 and AstroNvim v6.
> The plugin is intentionally small: a light startup module, with the command core loaded on first real use.
>
> Wiki: https://github.com/isaccseter/simple-note.nvim/wiki

## Features

- Open a vault, preferring recently used files inside it
- Daily / today notes with offset and optional suffix
- Create notes from a template, including nested note paths
- Apply a template to the current note, merging TOML frontmatter
- Insert a TOML frontmatter block at the top of the current Markdown file
- Snacks dashboard entry (`v` by default)
- `:Snote <Tab>` completion for subcommands and template names
- `:Snote reload` without restarting Neovim

## Requirements

- Neovim 0.10+ (tested on 0.12.6)
- Optional: [`snacks.nvim`](https://github.com/folke/snacks.nvim) for the dashboard entry
- Optional: `markdown-frontmatter-complete.nvim` for blink.cmp frontmatter completion

`simple-note.nvim` has no dependency on the MFC plugin. `:Snote reload` will also reload MFC if it is installed and loaded.

## Installation

### lazy.nvim

```lua
{
  "isaccseter/simple-note.nvim",
  name = "simple-note.nvim",
  main = "simple-note",
  lazy = false, -- the light module must be present at startup for the dashboard entry
  opts = {
    vault = vim.fn.expand "~/SCH",
    welcome = true,
    welcome_action = "today",
  },
}
```

`lazy = false` does **not** load the command core at startup. The plugin loads `config`, `commands`, and `welcome` only; `simple-note.core` and `simple-note.templates` are loaded on first `:Snote` or template completion.

### Welcome disabled

If you do not want a dashboard entry, use lazy command loading:

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

The Lazy `cmd` stub still makes `:Snote <Tab>` work: completion loads the plugin and then returns subcommands/template names.

## Quick start

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

- `:Snote daily` with no argument creates/opens **yesterday**.
- `:Snote daily 0` is today; `1` is tomorrow; `-1` is yesterday.
- `:Snote new` without a title uses `Untitle` unless the template provides `basename`.
- `:Snote template` applies to the **current file**, which must be inside the vault.

## Commands

| Command | Arguments | Description |
| --- | --- | --- |
| `:Snote vault` | none | Prefer recently used files inside the vault; otherwise create/open `Untitle.md`. Changes cwd to the vault root and opens in a new tab. |
| `:Snote today` | `[input]` | Create/open today's daily note. `input` is the last sanitized path segment; it becomes `-input` in `basename`. |
| `:Snote daily` | `[n] [input]` | Daily note with integer offset. Default `n = -1` (yesterday). `input` is the last path segment. |
| `:Snote homepage` | none | Open the configured homepage in a new tab and change cwd to its directory. |
| `:Snote frontmatter` | none | Insert a TOML frontmatter block at the top of the current Markdown file. |
| `:Snote new` | `[title]` | Create from `defaultnew_template`. `title` may contain `/` for subdirectories. |
| `:Snote ntemplate` | `<template> [title]` | Create from a named template. The template must exist; it is not auto-created. |
| `:Snote template` | `<template>` | Apply a template to the current file inside the vault, merging frontmatter and appending body. |
| `:Snote reload` | none | Reload SNn modules, rescan templates, and reload/rebuild MFC if present. Does not refresh the welcome page. |

### Notes

- All commands that create notes open a **new tab** and move cwd to the vault root.
- `new` / `ntemplate` place the cursor on the last line after opening.
- `new` renames duplicates by appending `-1`, `-2`, ...
- Final file names starting with `.` are rejected.
- Absolute paths and `..` are rejected.
- `title` paths are sanitized segment by segment; allowed characters include letters, digits, CJK, `-`, `_`, `.`, `(`, `)`, `[`, `]`.
- Date formatting is literal token replacement: `YYYY`, `YY`, `MM`, `DD`, `HH`, `mm`, `ss`. There is no format validation or repair.

## Configuration

Defaults are in `lua/simple-note/config.lua`.

| Option | Default | Description |
| --- | --- | --- |
| `vault` | `nil` | Vault root. `nil`/empty falls back to `~/Vault`. |
| `homepage` | `nil` | Relative path to the homepage. Required by `:Snote homepage`. |
| `welcome` | `true` | Add the Snacks dashboard entry. |
| `welcome_action` | `"today"` | `today`, `homepage`, or `last`. `last` behaves like opening the vault. |
| `welcome_key` | `"v"` | Dashboard key. |
| `welcome_label` | `"Open My Vault"` | Dashboard label. |
| `welcome_icon` | `"󰉋"` | Dashboard icon. |
| `notice_missing_welcome` | `true` | Notify once if Snacks is unavailable. |
| `daily_dir` | `"Daily"` | Daily notes directory, relative to the vault. |
| `templates_dir` | `"Templates"` | Template directory, relative to the vault. |
| `daily_template` | `"daily.md"` | Default daily template. Created if missing. |
| `defaultnew_template` | `"default-new.md"` | Default new-note template. Created if missing. |
| `frontmatter_extensions` | `{ "md" }` | Extensions accepted by `:Snote frontmatter`. |
| `substitute_key` | `{ "status", "created", "type" }` | Keys that should be overwritten instead of merged/appended. |
| `date_format` | `"YYYY-MM-DD"` | Used by `{{date}}` and daily target dates. |
| `time_format` | `"HH:mm"` | Used by `{{time}}`. |
| `timestamp_format` | `"YYYY-MM-DD HH:mm"` | Used by `{{timestamp}}`. |

The vault, `Daily/`, and `Templates/` directories are created on first command use. Startup does not touch them.

## Templates

Templates live under `Templates/` in the vault and must be TOML-frontmatter Markdown:

```markdown
+++
type = "project"
created = {{date}}
tags = ["project"]
basename = "{{title}}"
+++

## Goal
```

### Variables

| Variable | Meaning |
| --- | --- |
| `{{date}}` | Current date using `date_format`. |
| `{{date:YYYY/MM/DD}}` | Current date using a custom token format. |
| `{{time}}` | Current time using `time_format`. |
| `{{time:HH:mm}}` | Current time using a custom token format. |
| `{{timestamp}}` | Current time using `timestamp_format`; does not accept an argument. |
| `{{input}}` | Last path segment / title input; available for `new`, `ntemplate`, `today`, `daily`. |
| `{{hinput}}` | `-input`, or empty when input is empty. |
| `{{uinput}}` | `_input`, or empty when input is empty. |
| `{{title}}` | File stem after the target path is known. |
| `{{daily_date}}` | Daily target date; available only for `today`/`daily`, otherwise left literal. |

Unknown variables and invalid forms remain as literal `{{...}}` text.

### `basename`

`basename` is template-only metadata:

- It is removed from the generated file's frontmatter.
- It controls the note file name for `new`, `ntemplate`, `today`, and `daily`.
- If omitted, `new`/`ntemplate` use the title (or `Untitle`), and daily uses the target date.
- It is rendered with the same variables, then sanitized.
- A final name starting with `.` is rejected.

The current file's `basename` is **retained** by `:Snote template`; only the template's `basename` is metadata.

### Applying templates

`:Snote template <name>` merges the template frontmatter into the current file:

- Template has `+++` block and current file has none: create a frontmatter block at the top. Keys may be empty. A blank line is inserted between the new block and the original content.
- Template has no block: do not add one.
- Missing key: add it before the first table header.
- Key in `substitute_key`: replace the current value.
- Boolean on either side: replace with the template value.
- Both arrays: append template elements.
- Current array + template scalar: append the scalar.
- Current scalar + template array: convert to an array and append.
- Both scalars: convert the current value to an array and append.
- Complex current value or complex template value: skip that key.
- Body: append template body at the end; add a blank line only if the result is non-empty and does not already end with a blank line.
- YAML frontmatter (`---` on line 1) is rejected. TOML frontmatter must use `+++`.
- Malformed/unterminated frontmatter is rejected before modifying the buffer.

`:Snote template` does not save the buffer automatically. Review and `:write` yourself.

## Welcome page

SNn appends one entry to `Snacks.config.dashboard.preset.keys` at startup:

```lua
{ key = "v", desc = "Open My Vault  ", icon = "󰉋", action = ":Snote today" }
```

- If Snacks is not installed/loaded, it notifies once (unless `notice_missing_welcome = false`) and retries on `VimEnter`.
- `welcome = false` disables both the entry and the missing-Snacks notice.
- `:Snote reload` does not rebuild the welcome entry; reopen Neovim to refresh it.

## Loading and reload

- `lazy = false`: light module at startup (`config`, `commands`, `welcome`).
- `simple-note.core` and `simple-note.templates` are loaded on first real command or template completion.
- `:Snote reload` clears `simple-note.*` from `package.loaded`, re-runs setup with the saved opts, rescans templates on next core load, and reloads/rebuilds MFC if available.

## Development

```sh
cd ~/.config/nvim/.works
mise run check
```

Tests use temporary vaults and never touch `~/SCH`:

```sh
nvim --headless -i NONE \
  -c "luafile $PWD/simple-note.nvim/lua/simple-note/tests/p8_review.lua" +qa
```

- `p1_smoke.lua`: light loading, command framework, completion
- `p2_smoke.lua`: vault/daily/new/frontmatter
- `p3_smoke.lua`: template merge, arrays, comments, YAML, tables
- `p4_smoke.lua`: welcome, completion, reload
- `p8_review.lua`: oldfiles, no-basename daily, no-title new, blank reuse, missing homepage
