# RETRO 12

## Background

Retro is a dialect of Forth. It builds on the barebones Rx core, providing a much more flexible and useful language.

Retro has a history going back many years. It began as a 16-bit assembly implementation for x86 hardware, evolved into a 32-bit system with cmForth and ColorForth influences, and eventually started supporting mainstream OSes. Later it was rewritten for a small, portable virtual machine. Over the years the language implementation has varied substantially. This is the twelfth generation of Retro. It now targets a new virtual machine (called Nga), and is built over a barebones Forth kernel (called Rx).

### Namespaces

Various past releases have had different methods of dealing with the dictionary. Retro 12 has a single global dictionary, with a convention of using a namespace prefix for grouping related words.

| namespace  | words related to   |
| ---------- | ------------------ |
| ASCII      | ASCII Constants    |
| c          | characters         |
| compile    | compiler functions |
| d          | dictionary headers |
| err        | error handlers     |
| n          | numbers            |
| s          | strings            |
| v          | variables          |

### Prefixes

Prefixes are an integral part of Retro. These are single characters added to the start of a word which indicate to Retro how it should execute the word. These are processed at the start of interpreting a token.

| prefix | used for               |
| ------ | ---------------------- |
| :      | starting a definition  |
| &amp;  | obtaining pointers     |
| (      | stack comments         |
| `      | inlining bytecodes     |
| '      | strings                |
| #      | numbers                |
| &amp;  | pointers               |
| $      | characters             |

### Naming &amp; Style Conventions

* Names should start with their namespace (if appropriate)
* Word names should be lowercase
* Variable names should be Title case
* Constants should be UPPERCASE
* Names may not start with a prefix character
* Names returning a flag should end with a ?
* Words with an effect on the stack should have a stack comment

## Constants

Memory Map

| range           | contains                     |
| --------------- | ---------------------------- |
| 0 - 1470        | rx kernel                    |
| 1471 - 1535     | token input buffer           |
| 1536 +          | start of heap space          |
| 522751          | temporary strings (12 * 128) |
| 524287          | end of memory                |

````
:EOM       #-3 fetch ;
````

## Stack Comments

Retro provides a **(** prefix for stack comments. This will be used by all subsequent words so it comes first.

Example:

    (n-)

````
:prefix:( drop ;
  &class:macro
  &Dictionary fetch d:class store
````

## Dictionary

````
:d:last        (-d) &Dictionary fetch ;
:d:last<xt>    (-a) d:last d:xt fetch ;
:d:last<class> (-a) d:last d:class fetch ;
:d:last<name>  (-s) d:last d:name ;
````

## Changing Word Classes

In implementing **prefix:(** a messy sequence follows the definition:

    &class:macro &Dictionary fetch d:class store

This is used to change the class from **class:word** to **class:macro**. Doing this is ugly and not very readable. The next few words provide easier means of changing the class of the most recently defined word.

````
:reclass    (a-) d:last d:class store ;
:immediate  (-)  &class:macro reclass ;
:data       (-)  &class:data reclass ;
````

## Compiler

````
:here  (-a) &Heap fetch ;
:compile:lit  (a-) #1 , , ;
:compile:jump (a-) compile:lit #7 , ;
:compile:call (a-) compile:lit #8 , ;
:compile:ret  (-)  #10 , ;
````

## Stack Queries &amp; Cleaning

````
:depth (-n) #-1 fetch ;
:reset (...-) depth repeat 0; push drop pop #1 - again ;
````

## Stack Shufflers

The core Rx language provides a few basic stack shuffling words: **push**, **pop**, **drop**, **swap**, and **dup**. There are quite a few more that are useful. These are provided here.

````
:tuck      (xy-yxy)   dup push swap pop ;
:over      (xy-xyx)   push dup pop swap ;
:dup-pair  (xy-xyxy)  over over ;
:nip       (xy-y)     swap drop ;
:drop-pair (nn-)      drop drop ;
:?dup      (n-nn||n-n) dup 0; ;
````

## Inlining

````
:prefix:` (s-) &Compiler fetch [ s:to-number , ] [ drop ] choose ; immediate
````

## Support for Variables, Constants

These aren't really useful until the **s:** namespace is compiled later on. With strings and the **'** prefix:

| To create a                  | Use a form like    |
| ---------------------------- | ------------------ |
| Variable                     | 'Base var`         |
| Variable, with initial value | `#10 'Base var<n>` |
| Constant                     | `#-1 'TRUE const`  |

````
:d:create (s-)
  (s-) &class:data #0 d:add-header
  here d:last d:xt store ;
:var    (s-)  d:create #0 , ;
:var<n> (ns-) d:create , ;
:const  (ns-) d:create d:last d:xt store ;
````

## Constants

````
:TRUE  (-n) #-1 ;
:FALSE (-n)  #0 ;
````

## Comparators

````
:n:zero?      (n-f)   #0 eq? ;
:n:-zero?     (n-f)   #0 -eq? ;
:n:negative?  (n-f)   #0 lt? ;
:n:positive?  (n-f)   #-1 gt? ;
:n:strictly-positive?  (n-f)  #0 gt? ;
:n:even?      (n-f)  #2 /mod drop n:zero? ;
:n:odd?       (n-f)  #2 /mod drop n:-zero? ;
````

## Combinators

Retro makes use of anonymous functions called *quotations* for much of the execution flow and stack control. The words that operate on these quotations are called *combinators*.

**dip** executes a quotation after moving a value off the stack. The value is restored after execution completes. These are equivilent:

    #10 #12 [ #3 - ] dip
    #10 #12 push #3 - pop

````
:dip  (nq-n)  swap push call pop ;
````

**sip** is similar to dip, but leaves a copy of the value on the stack while the quotation is executed. These are equivilent:

    #10 [ #3 * ] sip
    #10 dup push #3 * pop

````
:sip  (nq-n)  push dup pop swap &call dip ;
````

Apply each quote to a copy of x

````
:bi  (xqq-)  &sip dip call ;
````

Apply q1 to x and q2 to y

````
:bi*  (xyqq-) &dip dip call ;
````

Apply q to x and y

````
:bi@  (xyq-)  dup bi* ;
````

Apply each quote to a copy of x

````
:tri  (xqqq-)  [ &sip dip sip ] dip call ;
````

Apply q1 to x, q2 to y, and q3 to z

````
:tri*  (xyzqqq-)  [ [ swap &dip dip ] dip dip ] dip call ;
````

Apply q to x, y, and z

````
:tri@ dup dup tri* ;
````

## Flow

Execute quote until quote returns a flag of 0.

````
:while  (q-)  [ repeat dup dip swap 0; drop again ] call drop ;
````

Execute quote until quote returns a flag of -1.

````
:until  (q-)  [ repeat dup dip swap #-1 xor 0; drop again ] call drop ;
````

The **times** combinator runs a quote (n) times.

````
:times  (q-)  swap [ repeat 0; #1 - push &call sip pop again ] call drop ;
````

**case** is a conditional combinator.

Example:

    :c:vowel?
      $a [ TRUE ] case
      $e [ TRUE ] case
      $i [ TRUE ] case
      $o [ TRUE ] case
      $u [ TRUE ] case
      drop FALSE ;

````
:case
  [ over eq? ] dip swap
  [ nip call TRUE ] [ drop FALSE ] choose 0; pop drop drop ;
````

## ...

````
:compiling?  (-f)  &Compiler fetch ;
````

````
:rot       (abc-bca)   [ swap ] dip swap ;
````

Short for *top of return stack*, this returns the top item on the address stack. As an analog to traditional Forth, this is equivilent to **R@**.

````
:tors (-n)  pop pop dup push swap push ;
````

## Math

The core Rx language provides addition, subtraction, multiplication, and a combined division/remainder. Retro expands on this.

````
:/         (nq-d)  /mod swap drop ;
:mod       (nq-r)  /mod drop ;
:*/        (nnn-n) push * pop / ;
:not       (n-n)   #-1 xor ;
:n:pow     (bp-n)  #1 swap [ over * ] times nip ;
:n:negate  (n-n)   #-1 * ;
:n:square  (n-n)   dup * ;
:n:sqrt    (n-n)   #1 [ repeat dup-pair / over - #2 / 0; + again ] call nip ;
:n:min     (nn-n)  dup-pair lt? [ drop ] [ nip ] choose ;
:n:max     (nn-n)  dup-pair gt? [ drop ] [ nip ] choose ;
:n:abs     (n-n)   dup n:negate n:max ;
:n:limit   (nlu-n) swap push n:min pop n:max ;
:n:inc     (n-n)   #1 + ;
:n:dec     (n-n)   #1 - ;
:n:between? (nul-) rot [ rot rot n:limit ] sip eq? ;
````

## Memory

````
:v:inc-by  (na-)   [ fetch + ] sip store ;
:v:dec-by  (na-)   [ fetch swap - ] sip store ;
:v:inc     (n-n)   #1 swap v:inc-by ;
:v:dec     (n-n)   #1 swap v:dec-by ;
:v:limit   (alu-)  push push dup fetch pop pop n:limit swap store ;
:v:on      (a-)    TRUE swap store ;
:v:off     (a-)    FALSE swap store ;
:allot     (n-)    &Heap v:inc-by ;
````

If you need to update a stored variable there are two typical forms:

    #1 'Next var<n>
    &Next fetch #10 * &Next store

Or:

    #1 'Next var<n>
    &Next [ fetch #10 * ] sip store

The **v:update-using** replaces this with:

    #1 'Next var<n>
    &Next [ #10 * ] v:update-using

It takes care of preserving the variable address, fetching the stored value, and updating with the resulting value.

````
:v:update-using (aq-) swap [ fetch swap call ] sip store ;
````

## Lexical Scope

The dictionary is a simple linked list. Retro allows for some control over what is visible using the **{{**, **---reveal---**, and **}}** words.

As an example:

    {{
      :increment dup fetch n:inc swap store ;
      :Value `0 ;
    ---reveal---
      :next-number &Value fetch &Value increment ;
    }}

Only the **next-number** function will remain visible once **}}** is executed.

````
:ScopeList `0 `0 ;
:{{ d:last dup &ScopeList store-next store ;
:---reveal--- d:last &ScopeList n:inc store ;
:}} &ScopeList fetch-next swap fetch eq? [ &ScopeList fetch &Dictionary store ] [ &ScopeList fetch [ &Dictionary repeat fetch dup fetch &ScopeList n:inc fetch -eq? 0; drop again ] call store ] choose ;
````

## Buffer

````
{{
  :Buffer `0 ; data
  :Ptr    `0 ; data
  :terminate (-) #0 &Ptr fetch store ;
---reveal---
  :buffer:start  (-a) &Buffer fetch ;
  :buffer:end    (-a) &Ptr fetch ;
  :buffer:add    (c-) buffer:end store &Ptr v:inc terminate ;
  :buffer:get    (-c) &Ptr v:dec buffer:end fetch terminate ;
  :buffer:empty  (-)  buffer:start &Ptr store terminate ;
  :buffer:size   (-n) buffer:end buffer:start - ;
  :buffer:set    (a-) &Buffer store buffer:empty ;
}}
````

## Incoming

**later** is a small tool for interleaving code execution paths. This is somewhat difficult to explain.

Let's look at an example:

    :a #1 later #3 ;
    :b a #2 ;

When *b* executes it begins by calling *a* which pushes #1 to the stack. **later** then returns control to *b*, which pushes #2 to the stack. When execution of *b* ends at the *;*, control returns to *a* which finishes executing by pushing the #3 to the stack.

You can use **later** to pass control back and forth:

    :a #1 later #2 ;
    :b a #33 * later + ;

````
:later pop pop swap push push ;
````

````
:copy   (aan-) [ &fetch-next dip store-next ] times drop drop ;
````

## Strings

Strings are zero terminated.

Temporary strings are allocated in a circular pool (at STRINGS).

````
:TempStrings ;   &class:data reclass  #12 &TempStrings store
:TempStringMax ; &class:data reclass #128 &TempStringMax store
:STRINGS   EOM &TempStrings fetch &TempStringMax fetch * - ;

{{
  :MAX-LENGTH #128 ;
  :s:Current `0 ; data

  :s:pointer (-p)  &s:Current fetch MAX-LENGTH * STRINGS + ;
  :s:next    (-)   &s:Current v:inc &s:Current fetch &TempStrings fetch eq? [ #0 &s:Current store ] if ;
---reveal---
  :s:temp (s-s) dup s:length n:inc s:pointer swap copy s:pointer s:next ;
  :s:empty (-s) s:pointer s:next ;
}}
````

Permanent strings are compiled into memory. To skip over them a helper function is used. When compiled into a definition this will look like:

    lit &s:skip
    call
    :stringbegins
    .data 98
    .data 99
    .data 100
    .data 0
    lit &stringbegins

The **s:skip** adjusts the Nga instruction pointer to skip to the code following the stored string.

````
:s:skip (-) pop [ fetch-next n:-zero? ] while n:dec push ;
:s:keep (s-s) compiling? [ &s:skip class:word ] if here [ s, ] dip class:data ;
````

````
:prefix:' compiling? [ s:keep ] [ s:temp ] choose ; immediate
````

**s:chop** removes the last character from a string.

````
:s:chop (s-s) s:temp dup s:length over + n:dec #0 swap store ;
````

**s:reverse** reverses the order of a string. E.g.,

    'hello'  ->  'olleh'

````
:s:reverse (s-s)
  dup s:temp buffer:set &s:length [ dup s:length + n:dec ] bi swap
  [ dup fetch buffer:add n:dec ] times drop buffer:start s:temp ;
````

Trimming removes leading (**s:trim-left**) or trailing (**s:trim-right**) spaces from a string. **s:trim** removes both leading and trailing spaces.

````
:s:trim-left (s-s) s:temp [ fetch-next [ #32 eq? ] [ n:zero? ] bi and ] while n:dec ;
:s:trim-right (s-s) s:temp s:reverse s:trim-left s:reverse ;
:s:trim (s-s) s:trim-right s:trim-left ;
````

**s:prepend** and **s:append** for concatenating strings together.

````
:s:prepend (ss-s)
  s:temp [ dup s:length + [ dup s:length n:inc ] dip swap copy ] sip ;
:s:append (ss-s) swap s:prepend ;
````

````
{{
  :Needle `0 ; data
---reveal---
  :s:has-char?  (sc-f)
   &Needle store
   repeat
     fetch-next
     dup n:zero? [ drop drop #0 #0 ] [ #-1 ] choose 0; drop
     &Needle fetch eq? [ #-1 #0 ] [ #-1 ] choose 0; drop
  again ;
}}
````

## s:filter

Return a new string, consisting of the characters from another string that are filtered by a quotation.

    'This_is_a_test [ chr:-vowel? ] s:filter

## s:map

Return a new string resulting from applying a quotation to each character in a source string.

    'This_is_a_test [ $_ [ chr:SPACE ] case ] s:map

````
{{
  'Source var
  'Q var
  :*Source &Source fetch ;
  :<Source> *Source fetch ;
  :run-filter &Q fetch call ;
---reveal---
  :s:filter (sq-s)
    &Q store  &Source store
    s:empty buffer:set
    *Source s:length
    [ <Source> run-filter [ <Source> buffer:add ] if
      &Source v:inc
    ] times
    buffer:start
  ;
  :s:map (sq-s)
    &Q store  &Source store
    s:empty buffer:set
    *Source s:length
    [ <Source> run-filter buffer:add
      &Source v:inc
    ] times
    buffer:start
  ;
}}
````


````
:s:substr (sfl-s)
  [ + s:empty ] dip [ over [ copy ] dip ] sip
  over [ + #0 swap store ] dip ;
````

Hash (using DJB2)

````
{{
  :<s:hash> repeat push #33 * pop fetch-next 0; swap push + pop again ;
---reveal---
  :s:hash  (s-n)  #5381 swap <s:hash> drop ;
}}
````

## ASCII Character Constants

````
:ASCII:NUL     (-c)  #0 ;
:ASCII:SOH     (-c)  #1 ;
:ASCII:STX     (-c)  #2 ;
:ASCII:ETX     (-c)  #3 ;
:ASCII:EOT     (-c)  #4 ;
:ASCII:ENQ     (-c)  #5 ;
:ASCII:ACK     (-c)  #6 ;
:ASCII:BEL     (-c)  #7 ;
:ASCII:BS      (-c)  #8 ;
:ASCII:HT      (-c)  #9 ;
:ASCII:LF      (-c)  #10 ;
:ASCII:VT      (-c)  #11 ;
:ASCII:FF      (-c)  #12 ;
:ASCII:CR      (-c)  #13 ;
:ASCII:SO      (-c)  #14 ;
:ASCII:SI      (-c)  #15 ;
:ASCII:DLE     (-c)  #16 ;
:ASCII:DC1     (-c)  #17 ;
:ASCII:DC2     (-c)  #18 ;
:ASCII:DC3     (-c)  #19 ;
:ASCII:DC4     (-c)  #20 ;
:ASCII:NAK     (-c)  #21 ;
:ASCII:SYN     (-c)  #22 ;
:ASCII:ETB     (-c)  #23 ;
:ASCII:CAN     (-c)  #24 ;
:ASCII:EM      (-c)  #25 ;
:ASCII:SUB     (-c)  #26 ;
:ASCII:ESC     (-c)  #27 ;
:ASCII:FS      (-c)  #28 ;
:ASCII:GS      (-c)  #29 ;
:ASCII:RS      (-c)  #30 ;
:ASCII:US      (-c)  #31 ;
:ASCII:SPACE   (-c)  #32 ;
:ASCII:DEL     (-c)  #127 ;
````

## Characters

````
:c:letter?      (c-f) $A $z n:between? ;
:c:lowercase?   (c-f) $a $z n:between? ;
:c:uppercase?   (c-f) $A $Z n:between? ;
:c:digit?       (c-f) $0 $9 n:between? ;
:c:whitespace?  (c-f)
  [ ASCII:SPACE eq? ]
  [ ASCII:HT    eq? ]
  [ [ ASCII:LF eq? ] [ ASCII:CR eq? ] bi or ] tri or or ;
:c:to-upper     (c-c) dup c:lowercase? 0; drop ASCII:SPACE - ;
:c:to-lower     (c-c) dup c:uppercase? 0; drop ASCII:SPACE + ;
:c:toggle-case  (c-c) dup c:lowercase? [ c:to-upper ] [ c:to-lower ] choose ;
:c:to-string    (c-s) '. s:temp [ store ] sip ;
:c:visible?     (c-f) #31 #126 n:between? ;
:c:vowel?       (c-f)
  c:to-lower
  $a [ TRUE ] case
  $e [ TRUE ] case
  $i [ TRUE ] case
  $o [ TRUE ] case
  $u [ TRUE ] case
  drop FALSE ;
:c:consonant?   (c-f)
  dup c:letter? [ c:vowel? not ] [ drop FALSE ] choose ;
````


````
:s:to-upper (s-s)
  [ c:to-upper ] s:map ;

:s:to-lower (s-s)
  [ c:to-lower ] s:map ;
````

## Number to String

Convert a decimal (base 10) number to a string.

````
{{
  :Value `0 ;
---reveal---
  :n:to-string  (n-s)
    here buffer:set dup &Value store n:abs
    [ #10 /mod swap $0 + buffer:add dup n:-zero? ] while drop
    &Value fetch n:negative? [ $- buffer:add ] if
    buffer:start s:reverse s:temp ;
}}
````

## Unsorted

Replace the old prefix:' with this one that can optionally turn underscores into spaces.

````
TRUE 's:RewriteUnderscores var<n>

{{
  :<string>
    &s:RewriteUnderscores fetch
    [ [ dup s:length
        [ dup fetch
          dup $_ eq? [ drop #32 ] if
          over store n:inc
        ] times drop
      ] sip
    ] if
    &prefix:' call ;
---reveal---
  :prefix:' <string> ; immediate
}}
````

````
:curry (vp-p) here [ swap compile:lit compile:call compile:ret ] dip ;
:does (q-)
  d:last<xt> swap curry d:last d:xt store &class:word reclass ;
````

````
:cons (nn-p) here [ swap , , ] dip ;

:s:for-each (sq-)
  [ repeat
      over fetch 0; drop
      dup-pair
      [ [ [ fetch ] dip call ] dip ] dip
      [ n:inc ] dip
    again
  ] call drop-pair ;

````

````
{{
  :SystemState `0 `0 `0 ;
---reveal---
  :mark
    &Heap  fetch &SystemState #0 + store
    d:last &SystemState #1 + store ;
  :sweep
    &SystemState #0 + fetch &Heap store
    &SystemState #1 + fetch &Dictionary store ;
}}
````

# Large Scale Stack Reshuffling

This is a bit of a hack, but very useful at times.

Assume you have a bunch of values:

    #3 #1 #2 #5

And you want to reorder them into something new:

    #1 #3 #5 #5 #2 #1

Rather than using a lot of shufflers, **reorder** simplfies this into:

    #3 #1 #2 #5
    'abcd  'baddcb reorder

````
{{
  'Values var #27 allot
  :from s:length dup [ [ &Values + store ] sip n:dec ] times drop ;
  :to dup s:length [ fetch-next $a -  n:inc &Values + fetch swap ] times drop ;
---reveal---
  :reorder (...ss-?) [ from ] dip to ;
}}
````

## I/O

Retro really only provides one I/O function in the standard interface: pushing a character to the output log.

````
:putc (c-) `1000 ;
````

This can be used to implement words that push other item to the log.

````
:nl   (-)  ASCII:LF putc ;
:puts (s-) [ putc ] s:for-each ;
:putn (n-) n:to-string puts ASCII:SPACE putc ;
````

## The End

## Legalities

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.

    Copyright (c) 2008 - 2017, Charles Childers
    Copyright (c) 2012 - 2013, Michal J Wallace
    Copyright (c) 2009 - 2011, Luke Parrish
    Copyright (c) 2009 - 2010, JGL
    Copyright (c) 2010 - 2011, Marc Simpson
    Copyright (c) 2011 - 2012, Oleksandr Kozachuk
    Copyright (c) 2010,        Jay Skeer
    Copyright (c) 2010,        Greg Copeland
    Copyright (c) 2011,        Aleksej Saushev
    Copyright (c) 2011,        Foucist
    Copyright (c) 2011,        Erturk Kocalar
    Copyright (c) 2011,        Kenneth Keating
    Copyright (c) 2011,        Ashley Feniello
    Copyright (c) 2011,        Peter Salvi
    Copyright (c) 2011,        Christian Kellermann
    Copyright (c) 2011,        Jorge Acereda
    Copyright (c) 2011,        Remy Moueza
    Copyright (c) 2012,        John M Harrison
    Copyright (c) 2012,        Todd Thomas
