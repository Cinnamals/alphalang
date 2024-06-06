[![LiU](https://www.ida.liu.se/mall11/images/logo-sv.png)](https://www.ida.liu.se/~TDP019/)

# TDP019
Construction of a computer language with Ruby as the engine. Created for the LiTH Course TDP019.

<b>Status:</b> [![pipeline status](https://gitlab.liu.se/matre652/tdp019/badges/main/pipeline.svg)](https://gitlab.liu.se/matre652/tdp019/commits/main)

### Install <b>[alphalang]</b>
```shell
gem install alphalang
alphalang -h
```

### Build from source
```shell
git clone git@gitlab.liu.se:matre652/tdp019.git && cd tdp019/project
gem build alphalang.gemspec
gem install alphalang-0.3.0.gem
alphalang lib/tester/demo_emoji.alpha --locale=emoji
alphalang demo.alpha
```

### Language Support Emacs

<i>Not completely done.</i>

Place the <a href="https://gitlab.liu.se/matre652/tdp019/-/blob/main/project/language-support/alphalang-mode.el?ref_type=heads">alphalang-mode.el</a> file in your ```~/.emacs.d/``` directory, or wherever your load-path is.

Then proceed to import alphalang-mode by pasting the following into your ```init.el```:

```emacs-lisp
(defun load-alphalang-mode ()
  (require 'alphalang-mode))

(load-alphalang-mode)
```

## Project Description
A programming language where you can change your keywords on the fly!
Did any keywords bother you in previous programming languages? Looking at you, ```elsif```.<br>
Well, with <b>[alphalang]</b>, you can change this to whatever you'd like. As long as it's <b>one_word</b>.

# Filestructure

```bash
.
├── dokument
│   ├── bnf
│   ├── dokumentation
│   │   └── images
│   ├── redovisning
│   └── specifikationer
├── LICENSE
├── project
│   ├── alphalang-0.3.0.gem
│   ├── alphalang.gemspec
│   ├── bin
│   │   └── alphalang
│   ├── demo.alpha
│   ├── Gemfile
│   ├── language-support
│   └── lib
│       ├── alpha.rb
│       ├── error_handler.rb
│       ├── locale_creator.rb
│       ├── locale_defaulter.rb
│       ├── locale_deleter.rb
│       ├── locale_lister.rb
│       ├── locales
│       ├── nodes
│       │   ├── basenodes.rb
│       │   ├── scopemanager.rb
│       │   └── stmtnodes.rb
│       ├── rdparse.rb
│       └── tester
│           ├── demo_de.alpha
│           ├── demo_emoji.alpha
│           ├── demo_sv.alpha
│           ├── fibonacci.alpha
│           └── test_unit.rb
└── README.md
```
