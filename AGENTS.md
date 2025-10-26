inspired by the legendary ansilove project
this new ansilust project is split into multiple modules:

- ansilust-ir -- intermediate representation schema
  - supports every format from the wild west of sixteencolors-archive
  - supports ansimation
  - supports modern utf8ansi text like Ghostty, Alacritty, Kitty, etc

- parsers output intermediate representation
  - BBS art parser -- inspired by ansilove
  - utf8ansi parser -- inspired by ghostty

- utf8ansi renderer -- reads intermediate representation and outputs utf8ansi
- html canvas renderer -- reads intermediate representation and outputs html canvas draw calls
