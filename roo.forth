# Roo: A Block Editor UI for RETRO

This is an interface layer for RETRO built around a block editor. This
has some interesting features:

- gopher backed block storage (with server written in RETRO)
- modal editing (ala *vi*)
- editor commands are just words in the dictionary

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

~~~
:display-cursor (-)
  ASCII:ESC putc @Cursor-Col @Cursor-Row '[%n;%nH s:with-format puts ;

:display-block (-)
  ASCII:ESC putc '[2J puts
  ASCII:ESC putc '[H puts
  &Block #16 [ #64 [ fetch-next putc ] times $| putc nl ] times drop
  #64 [ $- putc ] times $+ putc sp @Current-Block putn nl
  display-cursor ;
~~~

~~~
#0 !Current-Block load-block

:handler-for (s-a) 'roo:_ [ #4 + store ] sip d:lookup ;

:roo:n &Current-Block v:inc load-block ;
:roo:d &Current-Block v:dec load-block ;
:roo:i cursor-up ;
:roo:j cursor-left ;
:roo:k cursor-down ;
:roo:l cursor-right ;
:roo:q `26 ;

:keys
  handler-for 0; d:xt fetch call ;

:go
  repeat
    display-block
    getc keys
  again ;

go
~~~
