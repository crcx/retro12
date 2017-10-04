# Roo: A Block Editor UI for RETRO

This is an interface layer for RETRO built around a block editor. This
has some interesting features:

- gopher backed block storage (with server written in RETRO)
- modal editing (ala *vi*)
- editor commands are just words in the dictionary

Limitations:

- requires a terminal supporting ANSI escape sequences
- requires a wrapper script (bin/roo-launcher) to setup/restore
  terminal i/o modes
- requires an active internet connection

So getting started, some configuration settings for the server side:

~~~
:SERVER (-sn)  'forthworks.com #8008 ;
~~~

`SERVER` returns the server url and port.

Next, create a buffer to store the currently loaded block. With the
server-side storage I don't need to keep more than the current block
in memory.

A block is 1024 bytes; this includes one additional to use a terminator.
Doing this allows the block to be passed to `s:evaluate` as a string.

~~~
'Block d:create
  #1025 allot
~~~

I also define a variable, `Current-Block`, which holds the number of
the currently loaded block.

~~~
'Current-Block var
~~~

With that done, it's now time for a word to load a block from the server.

~~~
:selector<get>  (-s)  @Current-Block '/r/%n s:with-format ;
:load-block     (-)   &Block SERVER selector<get> gopher:get drop ;
~~~

........................................................................

~~~
'Cursor-Row var
'Cursor-Col var

:cursor-left   (-)  &Cursor-Col v:dec ;
:cursor-right  (-)  &Cursor-Col v:inc ;
:cursor-up     (-)  &Cursor-Row v:dec ;
:cursor-down   (-)  &Cursor-Row v:inc ;
~~~

........................................................................

The block display is kept minimalistic. Each line is bounded by a single
vertical bar (|) on the right edge, and there is a separatator line at
the bottom to indicate the base of the block. To the left of this is a
single number, indicating the current block number.

So it looks like:

    (blank)                                                         |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
                                                                    |
    ----------------------------------------------------------------+ 29

The cursor display will be platform specific.

~~~
:position-cursor (-)
  ASCII:ESC putc @Cursor-Col @Cursor-Row '[%n;%nH s:with-format puts ;

:clear-display (-)
  ASCII:ESC putc '[2J puts
  ASCII:ESC putc '[H puts ;

:display-block (-)
  clear-display
  &Block #16 [ #64 [ fetch-next putc ] times $| putc nl ] times drop
  #64 [ $- putc ] times $+ putc sp @Current-Block putn nl
  dump-stack
  position-cursor ;
~~~

........................................................................

Handling of keys is essential to using Roo. I chose to use a method that
I borrowed from Sam Falvo II's VIBE editor and leverage the dictionary
for key handlers.

In Roo a key handler is a word in the `roo:` namespace. A word like:

    roo:c:a

Will implement a handler called when 'a' is typed in command mode. And

    roo:i:`

Would implement a handler for the '`' key in insert mode.

In command mode keys not matching a handler are ignored. For words that
do match up to a control word, the word will be called. In insert mode,
any keys not mapped to a word will be inserted into the block at the
current position.

My default keymap will be (subject to change!):

    TAB  Switch modes
    h    Cursor left
    j    Cursor down
    k    Cursor up
    l    Cursor right
    H    Previous block
    L    Next block
    e    Evaluate block

~~~
#0 !Current-Block load-block

:handler-for (s-a) 'roo:c:_ [ #6 + store ] sip d:lookup ;

:roo:c:H &Current-Block v:dec load-block ;
:roo:c:L &Current-Block v:inc load-block ;
:roo:c:h cursor-left ;
:roo:c:j cursor-down ;
:roo:c:k cursor-up ;
:roo:c:l cursor-right ;
:roo:c:e &Block s:evaluate ;
:roo:c:q `26 ;

:keys
  handler-for 0; d:xt fetch call ;

:go
  repeat
    display-block
    getc keys
  again ;

go
~~~
