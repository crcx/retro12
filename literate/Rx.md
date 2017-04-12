    ____  _   _
    || \\ \\ //
    ||_//  )x(
    || \\ // \\ 2017.04
    a minimalist forth for nga

*Rx* (*retro experimental*) is a minimal Forth implementation for the
Nga virtual machine. Like Nga this is intended to be used within a
larger supporting framework adding I/O and other desired functionality.
Various example interface layers are included.

## General Notes on the Source

Rx is developed using a literate tool called *unu*. This allows easy
extraction of fenced code blocks into a separate file for later
compilation. Developing in a literate approach is beneficial as it
makes it easier for me to keep documentation current and lets me
approach the code in a more structured manner.

The source is written in Naje, the standard assembler for Nga.

## In the Beginning...

All code built with the Nga toolchain starts with a jump to the main
entry point. With cell packing, this takes two cells. We can take
advantage of this knowledge to place a couple of variables at the
start so they can be easily identified and interfaced with external
tools. This is important as Nga allows for a variety of I/O models to
be implemented and I don't want to tie Rx into any one specific model.

Here's the initial memory map:

| Offset | Contains                    | Notes              |
| ------ | --------------------------- | ------------------ |
| 0      | lit call nop nop            | Compiled by *Naje* |
| 1      | Pointer to main entry point | Compiled by *Naje* |
| 2      | Dictionary                  |                    |
| 3      | Heap                        |                    |

Naje, the Nga assembler, compiles the initial instructions automatically.
The two variables need to be declared next, so:

````
:Dictionary
  .ref 9999
:Heap
  .data 1536
:Version
  .data 201704
````

Both of these are pointers. `Dictionary` points to the most recent
dictionary entry. (See the *Dictionary* section at the end of this
file.) `Heap` points to the next free memory address. This is hard
coded to an address beyond the end of the Rx kernel. It'll be fine
tuned as development progresses. See the *Interpreter &amp; Compiler*
section for more on this.

## Nga Instruction Set

The core Nga instruction set consists of 27 instructions. Rx begins by
assigning each to a separate function. These are not intended for direct
use; in Rx the compiler will fetch the opcode values to use from these
functions when compiling. Some of them will also be wrapped in normal
functions later.

````
:_nop
  .data 0
  ret
:_lit
  .data 1
  ret
:_dup
  .data 2
  ret
:_drop
  .data 3
  ret
:_swap
  .data 4
  ret
:_push
  .data 5
  ret
:_pop
  .data 6
  ret
:_jump
  .data 7
  ret
:_call
  .data 8
  ret
:_ccall
  .data 9
  ret
:_ret
  .data 10
  ret
:_eq
  .data 11
  ret
:_neq
  .data 12
  ret
:_lt
  .data 13
  ret
:_gt
  .data 14
  ret
:_fetch
  .data 15
  ret
:_store
  .data 16
  ret
:_add
  .data 17
  ret
:_sub
  .data 18
  ret
:_mul
  .data 19
  ret
:_divmod
  .data 20
  ret
:_and
  .data 21
  ret
:_or
  .data 22
  ret
:_xor
  .data 23
  ret
:_shift
  .data 24
  ret
:_zret
  .data 25
  ret
:_end
  .data 26
  ret
````

Nga also allows for multiple instructions to be packed into a single
memory location (called a *cell*). Rx doesn't take advantage of this
yet, with the exception of calls. Since calls take a value from the
stack, a typical call (in Naje assembly) would look like:

    lit &bye
    call

Without packing this takes three cells: one for the lit, one for the
address, and one for the call. Packing drops it to two since the
lit/call combination can be fit into a single cell. We define the
opcode for this here so that the compiler can take advantage of the
space savings.

````
:_packedcall
  .data 2049
  ret
````

## Stack Shufflers

These add additional operations on the stack elements that'll keep
later code much more readable.

````
:over
  push
    dup
  pop
  swap
  ret
:dup-pair
  lit &over
  call
  lit &over
  call
  ret
````

## Memory

The basic memory accesses are handled via `fetch` and `store`. These
two functions provide slightly easier access to linear sequences of data.

`fetch-next` takes an address and fetches the stored value. It returns
the next address and the stored value.

````
:fetch-next
  dup
  lit 1
  add
  swap
  fetch
  ret
````

`store-next` takes a value and an address. It stores the value to the
address and returns the next address.

````
:store-next
  dup
  lit 1
  add
  push
    store
  pop
  ret
````

## Strings

The kernel needs two basic string operations for dictionary searches:
obtaining the length and comparing for equality.

Strings in Rx are zero terminated. This is a bit less elegant than
counted strings, but the implementation is quick and easy.

First up, string length. The process here is trivial:

* Make a copy of the starting point
* Fetch each character, comparing to zero

  * If zero, break the loop
  * Otherwise discard and repeat

* When done subtract the original address from the current one
* Then subtract one (to account for the zero terminator)

````
:count
  lit &fetch-next
  call
  zret
  drop
  lit &count
  jump
:s:length
  dup
  lit &count
  call
  lit 1
  sub
  swap
  sub
  ret
````

String comparisons are harder.

````
:get-set
  fetch
  swap
  fetch
  ret
:next-set
  lit 1
  add
  swap
  lit 1
  add
  ret
:compare
  push
    push
      lit &dup-pair
      call
      lit &get-set
      call
      eq?
    pop
    and
    push
      lit &next-set
      call
    pop
  pop
  lit 1
  sub
  zret
  lit &compare
  jump
:s:compare:mismatched
  drop
  drop
  lit 0
  dup
  ret
:s:eq
  lit &dup-pair
  call
  lit &s:length
  call
  swap
  lit &s:length
  call
  neq?
  lit &s:compare:mismatched
  ccall
  zret
  dup
  lit &s:length
  call
  lit -1
  swap
  lit &compare
  call
  push
    drop
    drop
  pop
  ret
````

## Conditionals

The Rx kernel provides three conditional forms:

    flag true-pointer false-pointer choose
    flag true-pointer if
    flag false-pointer -if

Implement `choose`, a conditional combinator which will execute one of
two functions, depending on the state of a flag. We take advantage of
a little hack here. Store the pointers into a jump table with two
fields, and use the flag as the index. Default to the *false* entry,
since a *true* flag is -1.

````
:choice:true
  .data 0
:choice:false
  .data 0
:choose
  lit &choice:false
  store
  lit &choice:true
  store
  lit &choice:false
  add
  fetch
  call
  ret
````

Next the two *if* forms. Note that I allow *-if* to fall through
into *if*. This saves two cells of memory.

````
:-if
  push
    lit 0
    eq?
  pop
:if
  ccall
  ret
````

## Interpreter & Compiler

### Compiler Core

The heart of the compiler is `comma` which stores a value into memory
and increments a variable (`Heap`) pointing to the next free address.
`here` is a helper function that returns the address stored in `Heap`.

````
:comma
  lit &Heap
  fetch
  lit &store-next
  call
  lit &Heap
  store
  ret
````

With these we can add a couple of additional forms. `comma:opcode` is
used to compile VM instructions into the current defintion. This is
where those functions starting with an underscore come into play. Each
wraps a single instruction. Using this we can avoid hard coding the
opcodes.

This performs a jump to the `comma` word instead of using a `call/ret`
to save a cell and slightly improve performance.

````
:comma:opcode
  fetch
  lit &comma
  jump
````

`comma:string` is used to compile a string into the current definition.
As with `comma:opcode`, this uses a `jump` to eliminate the final tail
call.

````
:($)
  lit &fetch-next
  call
  zret
  lit &comma
  call
  lit &($)
  jump
:comma:string
  lit &($)
  call
  drop
  lit 0
  lit &comma
  jump
````

With the core functions above it's now possible to setup a few more
things that make compilation at runtime more practical.

First, a variable indicating whether we should compile or run a function.
This will be used by the *word classes*.

````
:Compiler
  .data 0
````

````
:t-;
  lit &_ret
  lit &comma:opcode
  call
  lit 0
  lit &Compiler
  store
  ret
````

### Word Classes

Rx is built over the concept of *word classes*. Word classes are a way
to group related words, based on their compilation and execution
behaviors. A special word, called a *class handler*, is defined to
handle an execution token passed to it on the stack. The compiler uses
a variable named class to set the default class when compiling a word.
We'll take a closer look at class later. Rx provides several classes
with differing behaviors:

`class:data` provides for dealing with data structures.

| interpret            | compile                       |
| -------------------- | ----------------------------- |
| leave value on stack | compile value into definition |

````
:class:data
  lit &Compiler
  fetch
  zret
  drop
  lit &_lit
  lit &comma:opcode
  call
  lit &comma
  jump
````

`class:word` handles most functions.

| interpret            | compile                       |
| -------------------- | ----------------------------- |
| call a function      | compile a call to a function  |

````
:class:word:interpret
  jump
:class:word:compile
  lit &_packedcall
  lit &comma:opcode
  call
  lit &comma
  jump
:class:word
  lit &Compiler
  fetch
  lit &class:word:compile
  lit &class:word:interpret
  lit &choose
  jump
````

`class:primitive` is a special class handler for functions that
correspond to Nga instructions.

| interpret            | compile                                     |
| -------------------- | ------------------------------------------- |
| call the function    | compile the instruction into the definition |

````
:class:primitive
  lit &Compiler
  fetch
  lit &comma:opcode
  lit &class:word:interpret
  lit &choose
  jump
````

`class:macro` is the class handler for *compiler macros*. These are
functions that always get called. They can be used to extend the
language in interesting ways.

| interpret            | compile                       |
| -------------------- | ----------------------------- |
| call the function    | call the function             |

````
:class:macro
  jump
````

The class mechanism is not limited to these classes. You can write
custom classes at any time. On entry the custom handler should take the
XT passed on the stack and do something with it. Generally the handler
should also check the `Compiler` state to determine what to do in either
interpretation or compilation.

### Dictionary

Rx has a single dictionary consisting of a linked list of headers. The
current form of a header is shown in the chart below. Pay special
attention to the accessors. Each of these words corresponds to a field
in the dictionary header. When dealing with dictionary headers, it is
recommended that you use the accessors to access the fields since it is
expected that the exact structure of the header will change over time.

| field | holds                                       | accessor |
| ----- | ------------------------------------------- | -------- |
| link  | link to the previous entry, 0 if last entry | d:link   |
| xt    | link to start of the function               | d:xt     |
| class | link to the class handler function          | d:class  |
| name  | zero terminated string                      | d:name   |

The initial dictionary is constructed at the end of this file. It'll
take a form like this:

    :0000
      .ref 0
      .ref _add
      .ref class:word
      .string +
    :0001
      .ref 0000
      .ref _sub
      .ref class:word
      .string -

Each label will contain a reference to the prior one, the internal
function name, its class, and a string indicating the name to expose
to the Rx interpreter.

Rx will store the pointer to the most recent entry in a variable
called `Dictionary`. For simplicity, we just assign the last entry
an arbitrary label of 9999. This is set at the start of the source.
(See *In the Beginning...*)

Rx provides accessor functions for each field. Since the number of
fields (or their ordering) may change over time, using these reduces
the number of places where field offsets are hard coded.

````
:d:link
  ret
:d:xt
  lit 1
  add
  ret
:d:class
  lit 2
  add
  ret
:d:name
  lit 3
  add
  ret
````

A traditional Forth has `create` to make a new dictionary entry
pointing to the next free location in `Heap`. Rx has `newentry` which
serves as a slightly more flexible base. You provide a string for the
name, a pointer to the class handler, and a pointer to the start of
the function. Rx does the rest.

````
:newentry
  lit &Heap
  fetch
  push
    lit &Dictionary
    fetch
    lit &comma
    call
    lit &comma
    call
    lit &comma
    call
    lit &comma:string
    call
  pop
  lit &Dictionary
  store
  ret
````

Rx doesn't provide a traditional create as it's designed to avoid
assuming a normal input stream and prefers to take its data from the
stack.

### Dictionary Search

````
:Which
  .data 0
:Needle
  .data 0

:found
  lit &Which
  store
  lit &_nop
  ret

:find
  lit 0
  lit &Which
  store
  lit &Dictionary
  fetch
:find_next
  zret
  dup
  lit &d:name
  call
  lit &Needle
  fetch
  lit &s:eq
  call
  lit &found
  ccall
  fetch
  lit &find_next
  jump
:d:lookup
  lit &Needle
  store
  lit &find
  call
  lit &Which
  fetch
  ret
````

### Number Conversion

This code converts a zero terminated string into a number. The approach
is very simple:

* Store an internal multiplier value (-1 for negative, 1 for positive)
* Clear an internal accumulator value
* Loop:

  * Fetch the accumulator value
  * Multiply by 10
  * For each character, convert to a numeric value and add to the
    accumulator
  * Store the updated accumulator

* When done, take the accumulator value and the modifier and multiply
  them to get the final result

At this time Rx only supports decimal numbers.

````
:to-number:Mod
  .data 0
:to-number:Acc
  .data 0
:to-number:char>digit
  lit 48
  sub
  ret
:to-number:scale
  lit &to-number:Acc
  fetch
  lit 10
  mul
  ret
:to-number:convert
  lit &fetch-next
  call
  zret
  lit &to-number:char>digit
  call
  lit &to-number:scale
  call
  add
  lit &to-number:Acc
  store
  lit &to-number:convert
  jump
:to-number:prepare
  lit 1
  lit &to-number:Mod
  store
  lit 0
  lit &to-number:Acc
  store
  dup
  fetch
  lit 45
  eq?
  zret
  drop
  lit -1
  lit &to-number:Mod
  store
  lit 1
  add
  ret
:s:to-number
  lit &to-number:prepare
  call
  lit &to-number:convert
  call
  drop
  lit &to-number:Acc
  fetch
  lit &to-number:Mod
  fetch
  mul
  ret
````

### Token Processing

An input token has a form like:

    <prefix-char>string

Rx will check the first character to see if it matches a known prefix.
If it does, it will pass the string (without the token) to the prefix
handler. If not, it will attempt to find the token in the dictionary.

Prefixes are handled by functions with specific naming conventions. A
prefix name should be:

    prefix:<prefix-char>

Where <prefix-char> is the character for the prefix. These should be
compiler macros (using the `class:macro` class) and watch the `compiler`
state to decide how to deal with the token. To find a prefix, Rx stores
the prefix character into a string named `prefixed`. It then searches
for this string in the dictionary. If found, it sets an internal
variable (`prefix:handler`) to the dictionary entry for the handler
function. If not found, `prefix:handler` is set to zero. The check,
done by `prefix?`, also returns a flag.

````
:prefix:no
  .data 32
  .data 0
:prefix:handler
  .data 0
:prefixed
  .string prefix:_
:prefix:prepare
  fetch
  lit &prefixed
  lit 7
  add
  store
  ret
:prefix:has-token?
  dup
  lit &s:length
  call
  lit 1
  eq?
  zret
  drop
  drop
  lit &prefix:no
  ret
:prefix?
  lit &prefix:has-token?
  call
  lit &prefix:prepare
  call
  lit &prefixed
  lit &d:lookup
  call
  dup
  lit &prefix:handler
  store
  lit 0
  neq?
  ret
````

Rx uses prefixes for important bits of functionality including parsing
numbers (prefix with `#`), obtaining pointers (prefix with `&`), and
starting new functions (using the `:` prefix).

I use `jump` for tail call eliminations here.

| prefix | used for          | example |
| ------ | ----------------- | ------- |
| #      | numbers           | #100    |
| $      | ASCII characters  | $e      |
| &      | pointers          | &swap   |
| :      | definitions       | :foo    |
| (      | Comments          | (n-)    |

````
:prefix:(
  drop
  ret
:prefix:#
  lit &s:to-number
  call
  lit &class:data
  jump
:prefix:$
  fetch
  lit &class:data
  jump
:prefix::
  lit &class:word
  lit &Heap
  fetch
  lit &newentry
  call
  lit &Heap
  fetch
  lit &Dictionary
  fetch
  lit &d:xt
  call
  store
  lit -1
  lit &Compiler
  store
  ret
:prefix:&
  lit &d:lookup
  call
  lit &d:xt
  call
  fetch
  lit &class:data
  jump
````

### Quotations

Quotations are anonymous, nestable blocks of code. Rx uses them for
control structures and some aspects of data flow. A quotation takes a
form like:

    [ #1 #2 ]
    #12 [ square #144 eq? [ #123 ] [ #456 ] choose ] call

Begin a quotation with `[` and end it with `]`.

````
:t-[
  lit &Heap
  fetch
  lit 3
  add
  lit &Compiler
  fetch
  lit -1
  lit &Compiler
  store
  lit &_lit
  lit &comma:opcode
  call
  lit &Heap
  fetch
  lit 0
  lit &comma
  call
  lit &_jump
  lit &comma:opcode
  call
  lit &Heap
  fetch
  ret
:t-]
  lit &_ret
  lit &comma:opcode
  call
  lit &Heap
  fetch
  swap
  lit &_lit
  lit &comma:opcode
  call
  lit &comma
  call
  swap
  store
  lit &Compiler
  store
  lit &Compiler
  fetch
  zret
  drop
  drop
  ret
````

## Lightweight Control Structures

Rx provides a couple of functions for simple flow control apart from
using quotations. These are `repeat`, `again`, and `0;`. An example of
using them:

    :s:length dup repeat fetch-next 0; drop again swap - #1 - ;

These can only be used within a definition or quotation. If you need
to use them interactively, wrap them in a quote and `call` it.

````
:repeat
  lit &Heap
  fetch
  ret
:again
  lit &_lit
  lit &comma:opcode
  call
  lit &comma
  call
  lit &_jump
  lit &comma:opcode
  jump
:t-0;
  lit &Compiler
  fetch
  zret
  drop
  lit &_zret
  lit &comma:opcode
  jump
````

````
:t-push
  lit &Compiler
  fetch
  zret
  drop
  lit &_push
  lit &comma:opcode
  jump

:t-pop
  lit &Compiler
  fetch
  zret
  drop
  lit &_pop
  lit &comma:opcode
  jump
````

## Interpreter

The *interpreter* is what processes input. What it does is:

* Take a string
* See if the first character has a prefix handler

  * Yes: pass the rest of the string to the prefix handler for
         processing
  * No: lookup in the dictionary

    * Found: pass xt of word to the class handler for processing
    * Not found: report error via `err:notfound`

First up, the handler for dealing with words that are not found. This
is defined here as a jump to the handler for the Nga *NOP* instruction.
It is intended that this be hooked into and changed.

As an example, in Rx code, assuming an I/O interface with some support
for strings and output:

    [ $? putc space 'word not found' puts ]
    &err:notfound #1 + store

````
:err:notfound
  lit &_nop
  jump
````

`call:dt` takes a dictionary token and pushes the contents of the `d:xt`
field to the stack. It then calls the class handler stored in `d:class`.

````
:call:dt
  dup
  lit &d:xt
  call
  fetch
  swap
  lit &d:class
  call
  fetch
  jump
````

````
:input:source
  .data 0
:interpret:prefix
  lit &prefix:handler
  fetch
  zret
  lit &input:source
  fetch
  lit 1
  add
  swap
  lit &call:dt
  jump

:interpret:word
  lit &Which
  fetch
  lit &call:dt
  jump

:interpret:noprefix
  lit &input:source
  fetch
  lit &d:lookup
  call
  lit 0
  neq?
  lit &interpret:word
  lit &err:notfound
  lit &choose
  jump

:interpret
  dup
  lit &input:source
  store
  lit &prefix?
  call
  lit &interpret:prefix
  lit &interpret:noprefix
  lit &choose
  jump
````

## The Initial Dictionary

The dictionary is a linked list. This sets up the initial dictionary.
Maintenance of this bit is annoying, but it generally shouldn't be
necessary to change this unless you are adding new functions to the
Rx kernel. 

````
:0000
  .data 0
  .ref _dup
  .ref class:primitive
  .string dup
:0001
  .ref 0000
  .ref _drop
  .ref class:primitive
  .string drop
:0002
  .ref 0001
  .ref _swap
  .ref class:primitive
  .string swap
:0003
  .ref 0002
  .ref _call
  .ref class:primitive
  .string call
:0004
  .ref 0003
  .ref _eq
  .ref class:primitive
  .string eq?
:0005
  .ref 0004
  .ref _neq
  .ref class:primitive
  .string -eq?
:0006
  .ref 0005
  .ref _lt
  .ref class:primitive
  .string lt?
:0007
  .ref 0006
  .ref _gt
  .ref class:primitive
  .string gt?
:0008
  .ref 0007
  .ref _fetch
  .ref class:primitive
  .string fetch
:0009
  .ref 0008
  .ref _store
  .ref class:primitive
  .string store
:0010
  .ref 0009
  .ref _add
  .ref class:primitive
  .string +
:0011
  .ref 0010
  .ref _sub
  .ref class:primitive
  .string -
:0012
  .ref 0011
  .ref _mul
  .ref class:primitive
  .string *
:0013
  .ref 0012
  .ref _divmod
  .ref class:primitive
  .string /mod
:0014
  .ref 0013
  .ref _and
  .ref class:primitive
  .string and
:0015
  .ref 0014
  .ref _or
  .ref class:primitive
  .string or
:0016
  .ref 0015
  .ref _xor
  .ref class:primitive
  .string xor
:0017
  .ref 0016
  .ref _shift
  .ref class:primitive
  .string shift
:0018
  .ref 0017
  .ref t-push
  .ref class:macro
  .string push
:0019
  .ref 0018
  .ref t-pop
  .ref class:macro
  .string pop
:0020
  .ref 0019
  .ref t-0;
  .ref class:macro
  .string 0;
:0021
  .ref 0020
  .ref fetch-next
  .ref class:word
  .string fetch-next
:0022
  .ref 0021
  .ref store-next
  .ref class:word
  .string store-next
:0023
  .ref 0022
  .ref s:to-number
  .ref class:word
  .string s:to-number
:0024
  .ref 0023
  .ref s:eq
  .ref class:word
  .string s:eq?
:0025
  .ref 0024
  .ref s:length
  .ref class:word
  .string s:length
:0026
  .ref 0025
  .ref choose
  .ref class:word
  .string choose
:0027
  .ref 0026
  .ref if
  .ref class:word
  .string if
:0028
  .ref 0027
  .ref -if
  .ref class:word
  .string -if
:0029
  .ref 0028
  .ref prefix:(
  .ref class:macro
  .string prefix:(
:0030
  .ref 0029
  .ref Compiler
  .ref class:data
  .string Compiler
:0031
  .ref 0030
  .ref Heap
  .ref class:data
  .string Heap
:0032
  .ref 0031
  .ref comma
  .ref class:word
  .string ,
:0033
  .ref 0032
  .ref comma:string
  .ref class:word
  .string s,
:0034
  .ref 0033
  .ref t-;
  .ref class:macro
  .string ;
:0035
  .ref 0034
  .ref t-[
  .ref class:macro
  .string [
:0036
  .ref 0035
  .ref t-]
  .ref class:macro
  .string ]
:0037
  .ref 0036
  .ref Dictionary
  .ref class:data
  .string Dictionary
:0038
  .ref 0037
  .ref d:link
  .ref class:word
  .string d:link
:0039
  .ref 0038
  .ref d:xt
  .ref class:word
  .string d:xt
:0040
  .ref 0039
  .ref d:class
  .ref class:word
  .string d:class
:0041
  .ref 0040
  .ref d:name
  .ref class:word
  .string d:name
:0042
  .ref 0041
  .ref class:word
  .ref class:word
  .string class:word
:0043
  .ref 0042
  .ref class:macro
  .ref class:word
  .string class:macro
:0044
  .ref 0043
  .ref class:data
  .ref class:word
  .string class:data
:0045
  .ref 0044
  .ref newentry
  .ref class:word
  .string d:add-header
:0046
  .ref 0045
  .ref prefix:#
  .ref class:macro
  .string prefix:#
:0047
  .ref 0046
  .ref prefix::
  .ref class:macro
  .string prefix::
:0048
  .ref 0047
  .ref prefix:&
  .ref class:macro
  .string prefix:&
:0049
  .ref 0048
  .ref prefix:$
  .ref class:macro
  .string prefix:$
:0050
  .ref 0049
  .ref repeat
  .ref class:macro
  .string repeat
:0051
  .ref 0050
  .ref again
  .ref class:macro
  .string again
:0052
  .ref 0051
  .ref interpret
  .ref class:word
  .string interpret
:0053
  .ref 0052
  .ref d:lookup
  .ref class:word
  .string d:lookup
:0054
  .ref 0053
  .ref class:primitive
  .ref class:word
  .string class:primitive
:0055
  .ref 0054
  .ref Version
  .ref class:data
  .string Version
:9999
  .ref 0055
  .ref err:notfound
  .ref class:word
  .string err:notfound
````

## Appendix: Words, Stack Effects, and Usage

| Word            | Stack     | Notes                                             |
| --------------- | --------- | ------------------------------------------------- |
| dup             | n-nn      | Duplicate the top item on the stack               |
| drop            | nx-n      | Discard the top item on the stack                 |
| swap            | nx-xn     | Switch the top two items on the stack             |
| call            | p-        | Call a function (via pointer)                     |
| eq?             | nn-f      | Compare two values for equality                   |
| -eq?            | nn-f      | Compare two values for inequality                 |
| lt?             | nn-f      | Compare two values for less than                  |
| gt?             | nn-f      | Compare two values for greater than               |
| fetch           | p-n       | Fetch a value stored at the pointer               |
| store           | np-       | Store a value into the address at pointer         |
| +               | nn-n      | Add two numbers                                   |
| -               | nn-n      | Subtract two numbers                              |
| *               | nn-n      | Multiply two numbers                              |
| /mod            | nn-mq     | Divide two numbers, return quotient and remainder |
| and             | nn-n      | Perform bitwise AND operation                     |
| or              | nn-n      | Perform bitwise OR operation                      |
| xor             | nn-n      | Perform bitwise XOR operation                     |
| shift           | nn-n      | Perform bitwise shift                             |
| fetch-next      | a-an      | Fetch a value and return next address             |
| store-next      | na-a      | Store a value to address and return next address  |
| push            | n-        | Move value from data stack to address stack       |
| pop             | -n        | Move value from address stack to data stack       |
| 0;              | n-n OR n- | Exit word (and `drop`) if TOS is zero             |
| s:to-number     | s-n       | Convert a string to a number                      |
| s:eq?           | ss-f      | Compare two strings for equality                  |
| s:length        | s-n       | Return length of string                           |
| choose          | fpp-?     | Execute *p1* if *f* is -1, or *p2* if *f* is 0    |
| if              | fp-?      | Execute *p* if flag *f* is true (-1)              |
| -if             | fp-?      | Execute *p* if flag *f* is false (0)              |
| Compiler        | -p        | Variable; holds compiler state                    |
| Heap            | -p        | Variable; points to next free memory address      |
| ,               | n-        | Compile a value into memory at `here`             |
| s,              | s-        | Compile a string into memory at `here`            |
| ;               | -         | End compilation and compile a *return* instruction|
| [               | -         | Begin a quotation                                 |
| ]               | -         | End a quotation                                   |
| Dictionary      | -p        | Variable; points to most recent header            |
| d:link          | p-p       | Given a DT, return the address of the link field  |
| d:xt            | p-p       | Given a DT, return the address of the xt field    |
| d:class         | p-p       | Given a DT, return the address of the class field |
| d:name          | p-p       | Given a DT, return the address of the name field  |
| class:word      | p-        | Class handler for standard functions              |
| class:primitive | p-        | Class handler for Nga primitives                  |
| class:macro     | p-        | Class handler for immediate functions             |
| class:data      | p-        | Class handler for data                            |
| d:add-header    | saa-      | Add an item to the dictionary                     |
| prefix:#        | s-        | # prefix for numbers                              |
| prefix::        | s-        | : prefix for definitions                          |
| prefix:&        | s-        | & prefix for pointers                             |
| prefix:$        | s-        | $ prefix for ASCII characters                     |
| repeat          | -a        | Start an unconditional loop                       |
| again           | a-        | End an unconditional loop                         |
| interpret       | s-?       | Evaluate a token                                  |
| d:lookup        | s-p       | Given a string, return the DT (or 0 if undefined) |
| err:notfound    | -         | Handler for token not found errors                |

## Legalities

Rx is Copyright (c) 2016-2017, Charles Childers

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

My thanks go out to Michal J Wallace, Luke Parrish, JGL, Marc Simpson,
Oleksandr Kozachuk, Jay Skeer, Greg Copeland, Aleksej Saushev, Foucist,
Erturk Kocalar, Kenneth Keating, Ashley Feniello, Peter Salvi, Christian
Kellermann, Jorge Acereda, Remy Moueza, John M Harrison, and Todd Thomas.
All of these great people helped in the development of Retro 10 & 11,
without which Rx wouldn't have been possible.
