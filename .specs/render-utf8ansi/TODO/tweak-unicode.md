zig build run -- reference/sixteencolors/fire-39/H4-2017.ANS > /tmp/H4-2017.utf8ansi
ansee --output /tmp/H4-2017.utf8ansi.png /tmp/H4-2017.utf8ansi
compare /tmp/H4-2017.utf8ansi.png to reference/sixteencolors/fire-39/H4-2017.ANS.png

notice how some of the characters are not well aligned relative to the baseline
this destroys the overall effect of the art
