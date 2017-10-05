#/bin/sh
stty cbreak
cat >/tmp/_roo.forth << 'EOF'


# Roo: A Block Editor UI for RETRO

This is an interface layer for RETRO built around a block editor. This
has some interesting features:

- gopher backed block storage (with server written in RETRO)
- modal editing (ala *vi*)
- editor commands are just words in the dictionary

Limitations:

- requires a terminal supporting ANSI escape sequences
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

With that done, it's now time for a word to load a block from the
server.

~~~
:selector<get>  (-s)  @Current-Block '/r/%n s:with-format ;
:load-block     (-)   &Block SERVER selector<get> gopher:get drop ;
~~~

Then the other side, saving a block to the server.

~~~
:selector<set>  (-s)  &Block @Current-Block '/s/%n/%s s:with-format ;
:save-block     (-)   here SERVER selector<set> gopher:get drop ;
~~~

........................................................................

The `Mode` variable will be used to track the current mode. I have
chosen to implement two modes: command ($C) and insert ($I).

Command mode will be used for all non-entry related options, including
(but not limited to) cursor movement, block navigation, and code
evaluation.

So with two modes I only need one variable to track which mode is
active, and a single word to switch back and forth between them.

~~~
$C 'Mode var<n>
:toggle-mode (-)  @Mode $C eq? [ $I ] [ $C ] choose !Mode ;
~~~

........................................................................

I need a way to keep track of where in the block the user currently is.
So two variables: one for the row and one for the column:

~~~
'Cursor-Row var
'Cursor-Col var
~~~

To ensure that the cursor stays within the block, I am implementing a
`constrain` word to limit the range of the cursor. Thanks to `v:limit`
this is really easy.

~~~
:constrain (-)
  &Cursor-Row #0 #15 v:limit
  &Cursor-Col #0 #63 v:limit ;
~~~

And then the words to adjust the cursor positioning:

~~~
:cursor-left   (-)  &Cursor-Col v:dec constrain ;
:cursor-right  (-)  &Cursor-Col v:inc constrain ;
:cursor-up     (-)  &Cursor-Row v:dec constrain ;
:cursor-down   (-)  &Cursor-Row v:inc constrain ;
~~~

The other bit related to the cursor is a word to decide the offset into
the block. This will be used to aid in entering text.

~~~
:cursor-position  (-n)  @Cursor-Row #64 * @Cursor-Col + ;
~~~

~~~
:insert-character (c-) cursor-position &Block + store cursor-right ;
~~~

........................................................................

The block display is kept minimalistic. Each line is bounded by a single
vertical bar (|) on the right edge, and there is a separatator line at
the bottom to indicate the base of the block. To the left of this is a
single number, indicating the current block number. This is followed by
the mode indicator.

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
    ----------------------------------------------------------------+ 29C

The cursor display will be platform specific.

~~~
:position-cursor (-)
  @Cursor-Col @Cursor-Row [ n:inc ] bi@ ASCII:ESC '%c[%n;%nH s:with-format puts ;

:clear-display (-)
  ASCII:ESC putc '[2J puts
  ASCII:ESC putc '[H puts ;

:display-block (-)
  clear-display
  &Block #16 [ #64 [ fetch-next putc ] times $| putc nl ] times drop
  #64 [ $- putc ] times $+ putc sp @Current-Block putn @Mode putc nl
  dump-stack nl
  @Cursor-Row putn $, putc @Cursor-Col putn $: putc sp cursor-position putn
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
#139 !Current-Block load-block

:handler-for (s-a)
  @Mode $C eq? [ 'roo:c:_ ]
               [ 'roo:i:_ ] choose [ #6 + store ] sip d:lookup ;

:roo:c:H &Current-Block v:dec load-block ;
:roo:c:L &Current-Block v:inc load-block ;
:roo:c:h cursor-left ;
:roo:c:j cursor-down ;
:roo:c:k cursor-up ;
:roo:c:l cursor-right ;
:roo:c:` toggle-mode ;
:roo:i:` toggle-mode save-block ;

'Completed var
:roo:c:q &Completed v:on ;

:roo:c:e &Block s:evaluate ;

:call<dt>  (d-)  d:xt fetch call ;

:keys (c-)
  dup handler-for
  @Mode $I -eq? [ nip 0; call<dt> ]
                [ dup n:zero? [ drop insert-character ]
                              [ nip call<dt>          ] choose ] choose ;

:go
  [ display-block getc keys @Completed ] until ;

go
~~~

........................................................................


EOF
rre /tmp/_roo.forth
rm -f /tmp/_roo.forth
stty -cbreak

