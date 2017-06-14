# Changelog

# 2017.6

The 2017.6 release focuses on stability, environment improvements, and expanding functionality.

New Documentation:

- basic architecture
- comparison w/classic Forth
- notes on user interface
- notes on syntax
- notes on quotes, combinators
- notes on namespaces
- notes on naming conventions
- notes on hyperstatic global environment
- iOS specific additions to the language

Updated & New Examples:

- 99 bottles of beer
- autopsy: debugging tool
- two player chess game
- greatest common divisor
- least common multiple
- fibonacci sequence
- factorials
- rosetta code: palindrome detection
- rosetta code: 1d cellular automata

Language Additions:

- added clock: namespace
  - clock:year
  - clock:month
  - clock:day
  - clock:hour
  - clock:minute
  - clock:second

- expanded file: namespace
  - file:for-each
  - file:list-all
  - file:with
  - file:size-of-named
  - file:spew
  - file:copy
  - file:slurp

- added ui: namespace
  - ui:get-input

- added net: namespace
  - net:http:get
  - net:gopher:get

User Interface:

- Added share sheet for exporting documents
- Minor rendering fixes in the editor
- Corrected several bugs with dark mode

Internals:

- added facilities to allow for pausing
  instruction processing during certain
  I/O events
- Rewrote opcode processor for files,
  pasteboard
- Fixed all uses of deprecated APIs in
  the Nga <-> I/O bridge

------------------------------

# 2017.5

- bump to 2017.5
  - rewrote s:to-number to be significantly smaller and faster
  - additions
    - .s
    - v:preserve
    - set:contains?
    - set:contains-string?
    - set:dup
    - set:filter
    - set:from-results
    - set:for-each
    - set:map
    - set:nth
    - set:reverse
- fixed reported bugs in editor
- added additional Markdown syntax support in the editor

------------------------------

# 2017.4

The big news is the addition of the Listener. Located in the output pane, this makes it possible to directly interact with the Retro system in an interactive fashion.

Image:

- bump to 2017.4
- adds d:for-each
- hand optimized kernel
- rewrote many s: functions for faster string operations
- fixed some bugs

Interface:

- Dropped the darker theme due to bugs
- New icon, splash screen
- Separated file view & output view buttons
- Added Listener

iOS Specific:

- added support for clearing the output

Documentation:

- updated doc|Glossary to reflect the most recent changes
- minor updates to reflect UI changes

Examples:

- Minor updates

------------------------------

# 2017.3

Interface:

- change color of backgrounds for code blocks
- add quick button for vertical bar |

------------------------------

# 2017.2

Internal improvements:

- faster loading of image file
- undo / redo in editor
- code is saved automatically now
- massive increase in memory limits

This release includes the following source modules:

- module|Buffer
- module|Characters
- module|Files
- module|FormattedStringOutput
- module|RML
- module|Strings

The following examples are included:

- example|99Bottles
- example|Autopsy
- example|Chess
- example|DumpImage
- example|GreatestCommonDivisor
- example|IterativeFibonacci
- example|LeastCommonMultiple
- example|RecursiveFactorial
- example|RecursiveFibonacci

The following documentation files are provided:

- doc|Changelog
- doc|CopyrightNotices
- doc|Glossary
- doc|UserInterface

------------------------------

# 2017.1

- New color scheme
- Larger text
- Small improvements to the Files view
- Latest image file
- Single character names can now be the same as a single prefix character:
- Removed documentation: namespace
- Added separate documentation files
- Background execution of code (no longer freezes UI)
