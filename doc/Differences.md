# Differences

RETRO is not a traditional Forth. This document should help those familiar with other Forth systems get started with RETRO.

**Defining a Word**

In traditional Forth, a definition looks like:

    : foo ( a b -- c ) over * + ;

In RETRO there are no parsing words. We use prefixes instead. This becomes:

    :foo (ab-c) over * + ;

The `:` prefix starts a definition.

**Comments**

Comments start with `(`. Note that a comment can not contain a space.

In traditional Forth:

    ( This is a comment )
    \ So is this

In RETRO:

    (This_is_a_comment)
    (So_is_this

No closing parenthesis is needed. Note that as there is no parsing, spaces can not be used. RETRO will translate underscores into spaces automatically.

**Numbers**

In traditional Forth, numbers can be used directly:

    1 2 + 3 *

RETRO requires the use of a `#` prefix to identify them:

    #1 #2 + #3 *

**Character Constants**

In traditional Forth you can get the ASCII code for a character using CHAR or [CHAR]. E.g.,

    CHAR a

Once again, RETRO uses a prefix for this. In this case, `$`:

    $a

**Pointers**

In a traditional Forth, you would use ' or ['] to get a pointer. E.g.,

    ' words

RETRO uses the `&` prefix for this:

    &words

**Strings**

Traditional Forth has numerous words for creating strings, depending on the type and state. A typical thing might be:

    s" hello, world!"

RETRO uses a `'` prefix for strings. As with comments, use underscores instead of spaces:

    'hello,_world!

In RETRO strings are zero terminated.

**Conditionals**

A traditional Forth has IF/ELSE/THEN:

    IF do-true ELSE do-false THEN
    IF do-true THEN
    NOT IF do-false THEN

RETRO uses combinators for these.

    [ do-true ] [do-false ] choose
    [ do-true ] if
    [ do-false ] -if

Combinators are described in the QuotesAndCombinators document and the Glossary.
