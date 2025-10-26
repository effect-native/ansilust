per-cell data vs per-document data
what must be defined for each cell and what can be defined once for the entire document?

how do we handle XBin that defines a custom bitmap font as part of the document? I suspect that most terminal emulators won't be able to render that and therefore any utf8ansi renderer would be incapable of rendering it; unless maybe it could do something that only works in a subset of terminals that support custom butmap fonts and/or rendering arbitrary graphics

but if we're just rendering arbitrary graphics to the terminal, then why not just use the png renderer and slap a wrapper around it that outputs the png as a series of sixel graphics or iTerm2 inline images or whatever?
i dunno, we need to be opinionated about this because it'll have some kind of impact on the design of the IR
