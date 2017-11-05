# RETRO

This is a set of extensions for RRE.

# Console Input

~~~
:getc (-c) `1001 ;
~~~

---------------------------------------------------------------

# Floating Point

~~~
:n:to-float  (n-_f:-n)   #0 `-6000 ;
:s:to-float  (s-_f:-n)   #1 `-6000 ;
:f:to-string (f:n-__-s) s:empty dup #2 `-6000 ;
:f:+     (f:ab-c)    #3  `-6000 ;
:f:-     (f:ab-c)    #4 `-6000 ;
:f:*     (f:ab-c)    #5 `-6000 ;
:f:/     (f:ab-c)    #6 `-6000 ;
:f:floor (f:ab-c)    #7 `-6000 ;
:f:eq?   (f:ab-c)    #8 `-6000 ;
:f:-eq?  (f:ab-c)    #9 `-6000 ;
:f:lt?   (f:ab-c)   #10 `-6000 ;
:f:gt?   (f:ab-c)   #11 `-6000 ;
:f:depth (-n)       #12 `-6000 ;
:f:dup   (f:a-aa)   #13 `-6000 ;
:f:drop  (f:a-)     #14 `-6000 ;
:f:swap  (f:ab-ba)  #15 `-6000 ;
:f:over  (f:ab-aba) f:to-string f:dup s:to-float f:swap ;
:f:tuck  (f:ab-bab) f:swap f:over ;
:f:positive? #0 n:to-float f:gt? ;
:f:negative? #0 n:to-float f:lt? ;
:f:negate #-1 n:to-float f:* ;
:f:abs    f:dup f:negative? [ f:negate ] if ;
:f:log   (f:ab-c)  #16 `-6000 ;
:f:power   (f:ab-c)  #17 `-6000 ;
:f:to-number (f:a-__-n)  #18 `-6000 ;
:prefix:. (s-__f:-f)
  compiling? [ s:keep ] [ s:temp ] choose &s:to-float class:word ; immediate
:putf (f:-) f:to-string puts ;
~~~

---------------------------------------------------------------

# Gopher

RETRO has Gopher support via `gopher:get`.

Takes:

  destination
  server name
  port
  selector

Returns:

  number of characters read

~~~
:gopher:get `-6200 ;
~~~

---------------------------------------------------------------

# Scripting: Command Line Arguments

~~~
:sys:argc (-n) `-6100 ;
:sys:argv (n-s) s:empty swap `-6101 ;
~~~

# System Interaction

The `unix:` namespace contains words for interacting with the
host operating system.

`unix:system` runs another application using the system shell
and returns after execution is completed.

~~~
:unix:system (s-)    `-8000 ;
~~~

`unix:fork` forks the current process and returns a process
identifier.

~~~
:unix:fork   (-n)    `-8001 ;
~~~

`unix:exit` takes a return code and exits RRE, returning the
specified code.

~~~
:unix:exit   (n-)    `-8002 ;
~~~

`unix:getpid` returns the current process identifier.

~~~
:unix:getpid (-n)    `-8003 ;
~~~

This group is used to execute a new process in place of the
current one. These take a program and optionally 1-3 arguments.
They map to the execl() system call.

Example:

    '/usr/bin/cal '2 '2019 unix:exec2

~~~
:unix:exec0  (s-)    `-8004 ;
:unix:exec1  (ss-)   `-8005 ;
:unix:exec2  (sss-)  `-8006 ;
:unix:exec3  (ssss-) `-8007 ;
~~~

`unix:wait` waits for a child process to complete. This maps to
the wait() system call.

~~~
:unix:wait   (-n)    `-8008 ;
~~~

`unix:kill` terminates a process. Takes a process and a signal
to send.

~~~
:unix:kill (nn-)  `-8009 ;
~~~

~~~
:unix:popen (sn-n) `-8010 ;
:unix:pclose (n-) `-8011 ;
~~~

---------------------------------------------------------------

# File I/O

This implements words for interfacing with the POSIX file I/O words if
you are using an interface supporting them. All of these are in the
`file:` namespace.

These are pretty much direct wrappers for fopen(), fclose(), etc.

First up, constants for the file modes.

| # | Used For           |
| - | ------------------ | 
| R | Mode for READING   |
| W | Mode for WRITING   |
| A | Mode for APPENDING |

~~~
#0 'file:R const
#1 'file:W const
#2 'file:A const
#3 'file:R+ const
~~~

For opening a file, provide the file name and mode. This will return a
number identifying the file handle.

~~~
:file:open  (sm-h) `118 ;
~~~

Given a file handle, close the file.

~~~
:file:close (h-)   `119 ;
~~~

Given a file handle, read a character.

~~~
:file:read  (h-c)  `120 ;
~~~

Write a character to an open file.

~~~
:file:write (ch-)  `121 ;
~~~

Return the current pointer within a file.

~~~
:file:tell  (h-n)  `122 ;
~~~

Move the file pointer to the specified location.

~~~
:file:seek  (nh-)  `123 ;
~~~

Return the size of the opened file.

~~~
:file:size  (h-n)  `124 ;
~~~

Given a file name, delete the file.

~~~
:file:delete (s-)  `125 ;
~~~

Flush pending writes to disk.

~~~
:file:flush (f-)   `126 ;
~~~

Given a file name, return `TRUE` if it exists or `FALSE` otherwise.

~~~
:file:exists?  (s-f)
  file:R file:open dup n:-zero?
  [ file:close TRUE ]
  [ drop FALSE ] choose ;
~~~

With that out of the way, we can begin building higher level functionality.

The first of these reads a line from the file. This is read to `here`; move
it somewhere safe if you need to keep it around.

The second goes with it. The `for-each-line` word will invoke a combinator
once for each line in a file. This makes some things trivial. E.g., a simple
'cat' implementation could be as simple as:

  'filename [ puts nl ] file:for-each-line

~~~
{{
  'FID var
  'FSize var
  'Action var
  'Buffer var
  :-eof? (-f) @FID file:tell @FSize lt? ;
  :preserve (q-) &FID [ &FSize [ call ] v:preserve ] v:preserve ;
---reveal---
  :file:read-line (f-s)
    !FID
    [ here dup !Buffer buffer:set
      [ @FID file:read dup buffer:add
        [ ASCII:CR eq? ] [ ASCII:LF eq? ] [ ASCII:NUL eq? ] tri or or ] until
        buffer:get drop ] buffer:preserve
    @Buffer ;

  :file:for-each-line (sq-)
    [ !Action
      file:R file:open !FID
      @FID file:size !FSize
      [ @FID file:read-line @Action call -eof? ] while
      @FID file:close
    ] preserve ;
}}
~~~

`file:slurp` reads a file into a buffer.

~~~
{{
  'FID var
  'Size var
---reveal---
  :file:slurp (as-)
    [ file:R file:open !FID
      buffer:set
      @FID file:size !Size
      @Size [ @FID file:read buffer:add ] times
      @FID file:close
    ] buffer:preserve ;
}}
~~~
