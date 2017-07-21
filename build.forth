#!/usr/bin/env rre

~~~
'FID var
'FSize var
'Action var
'Buffer d:create
  #32768 allot

:read-line (-)
  [ &Buffer buffer:set
    [ @FID file:read dup buffer:add
      [ #10 eq? ] [ #13 eq? ] [ #0 eq? ] tri or or ] until
      buffer:get drop ] buffer:preserve ;

:file:for-each-line (qs-)
  file:R file:open !FID !Action
  @FID file:size !FSize
  [ read-line Buffer @Action call @FID file:tell @FSize lt? ] while
  @FID file:close ;


[ dup #0 #6 s:substr
  '//USES [ 'Uses! puts #6 + puts nl ] s:case
  '//LIBS [ 'Lib!  puts #6 + puts nl ] s:case
  '//FLAG [ 'Flag! puts #6 + puts nl ] s:case
  drop-pair
] 'build.forth file:for-each-line

~~~


//USES nga bridge image
//LIBS m curses
//FLAG -Wall

