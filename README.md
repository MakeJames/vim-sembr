# Semantic Linebreaks in Vim

Bring the power of [sembr](https://sembr.org/) to Vim!

## ToC

- [What are Semantic Linebreaks?](#what-are-semantic-linebreaks)
- [What is vim-sembr?](#what-is-vim-sembr)
- [Usage](#usage)
- [Installation](#installation)
- [Contributing](#contributing)

## What are Semantic Linebreaks?

Semantic Linebreaks is a convention that makes it easier to read
and edit text by breaking lines into substantial units of thought.

By distributing text across multiple lines,
it becomes easier to see the structure of the text
and make changes discretely.

This is particularly useful in version control systems like Git,
where changes are tracked line by line.
In long blocks of text, a single word change can be hard to review.

When writing prose,
semantic linebreaks can help you focus on the content
and structure of your writing.
Generally speaking, clear, concise sentences are easier to read
and understand.
By distributing text across multiple lines,
it becomes easy to identify and fix long, convoluted sentences.

## What is vim-sembr?

Vim ships with several built-in commands for formatting text.

For long lines of text, `wrap` and `nowrap`,
are available to control how text is displayed in the editor.
Either as a single line or wrapped to fit the width of the window.

Crude formatting commands like `gq` and `gw` are available.
These commands can be used to reformat text to fit within a specified width.

This plugin provides a more nuanced approach to formatting text in Vim.

- Break lines at semantic boundaries
- Re-join lines, that were previously broken, into a single line
- Respect line indentation and whitespace for code blocks and lists
- Convert whole buffers or selected text
- Configure the maximum line with (default: 80 characters)

## Usage

Use `:SemBr` to apply SemBr formatting to the current buffer,
or provide a range to format only part of it:

```vim
:10,20SemBr
```

## Installation

This repository is compatible with most Vim plug in managers.

To manually install, clone this repository into your Vim plug in directory.

```sh
git clone https://github.com/makejames/vim-sembr.git ~/.vim/pack/plugins/start/vim-sembr
```

## Contributing

This is a work in progress.

If you would like to suggest a feature or raise a problem,
please open an issue on GitHub.

If you would like to make a code contribution,
please fork the repository and submit a pull request.
