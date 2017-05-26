    ____   ____ ______ ____    ___
    || \\ ||    | || | || \\  // \\
    ||_// ||==    ||   ||_// ((   ))
    || \\ ||___   ||   || \\  \\_//
    a personal, minimalistic forth

## Interfaces

RETRO has several options for user interfaces.

-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

## RRE

RRE, *run retro and exit* is the basic interface to RETRO. Designed for
scripting and CGI tasks, it embeds the ngaImage into the executable so
only a single binary is needed to run programs.

Usage:

    rre sourcefile

The code in *sourcefile* will be run, after which RETRO will exit.

Sources are in Markdown format, with Retro code in fenced blocks. E.g.,

    # Test

    This adds a `s:dup` word.

    ````
    :s:dup (s-ss) dup s:temp ;
    ````

-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

## REPL

The REPL is a barebones interactive environment for RETRO. You provide
input and it will process it and display results.

To use this the ngaImage needs to be in the current working directory.

Usage:

    repl

-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

## KANGA

KANGA is a new, curses based interface for RETRO. It provides a user
interface modeled after one used around 2001 when RETRO ran as a native
operating system on x86 hardware.

To use this you will need a copy of the ngaImage in the current working
directory.

Usage:

    kanga

Notes on the interface:

The UI is fullscreen. It appears roughly as follows:

    +---------------------------------------------+
    | output area                                 |
    |                                             |
    |                                             |
    |                                             |
    |                                             |
    +---------------------------------------------+
    | input area              | stack items       |
    +---------------------------------------------+

Input appears in the lower left corner. It is processed as each token
is entered. The top four or five stack items appear to the right of
the input area. And output is displayed above the input area. Press
ESC to exit.
