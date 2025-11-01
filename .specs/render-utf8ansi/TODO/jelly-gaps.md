reference/sixteencolors/fire-43/US-JELLY.ANS

zig build run -- reference/sixteencolors/fire-43/US-JELLY.ANS > /tmp/US-JELLY.utf8ansi
ansee --output /tmp/US-JELLY.utf8ansi.png /tmp/US-JELLY.utf8ansi

it's rendering more correctly via ansee than via ghostty or alacritty
notice in the ansee output of our /tmp/US-JELLY.utf8ansi there are a bunch of box characters
maybe this is a character that ghostty and alacritty don't render, therefore screwing up the alignment?

cat  /tmp/us_jelly_analysis.ans; ansilove  /tmp/us_jelly_analysis.ans; zig build run --  /tmp/us_jelly_analysis.ans >  /tmp/us_jelly_analysis.utf8ansi; cat  /tmp/us_jelly_analysis.utf8ansi; ansee --output  /tmp/us_jelly_analysis.utf8ansi.png  /tmp/us_jelly_analysis.utf8ansi; open  /tmp/us_jelly_analysis.ans.png; open  /tmp/us_jelly_analysis.utf8ansi.png
