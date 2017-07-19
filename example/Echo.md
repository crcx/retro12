#!/usr/bin/env rre

This is a simple `echo` style example.

Being run as a shell script, the first two arguments will be the
name of the runtime (`rre`) and the script name (`Echo.md`). So
actual data to display starts as the third argument. (This is
#2, since indexing is zero based).

We begin by specifying the initial argument and getting the
number of arguments after this.

~~~
#2 sys:argc #2 -
~~~

Then a simple loop:

- duplicate the argument number
- get the argument as a string
- display it, followed by a space
- increment the argument number

~~~
[ dup sys:argv puts sp n:inc ] times
~~~

And at the end, discard the argument number and inject a
newline.

~~~
drop nl
~~~
