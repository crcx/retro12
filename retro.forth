:EOM       #-3 fetch ;
:prefix:( drop ;
  &class:macro
  &Dictionary fetch d:class store
:d:last        (-d) &Dictionary fetch ;
:d:last<xt>    (-a) d:last d:xt fetch ;
:d:last<class> (-a) d:last d:class fetch ;
:d:last<name>  (-s) d:last d:name ;
:reclass    (a-) d:last d:class store ;
:immediate  (-)  &class:macro reclass ;
:data       (-)  &class:data reclass ;
:here  (-a) &Heap fetch ;
:compile:lit  (a-) #1 , , ;
:compile:jump (a-) compile:lit #7 , ;
:compile:call (a-) compile:lit #8 , ;
:compile:ret  (-)  #10 , ;
:depth (-n) #-1 fetch ;
:reset (...-) depth repeat 0; push drop pop #1 - again ;
:tuck      (xy-yxy)   dup push swap pop ;
:over      (xy-xyx)   push dup pop swap ;
:dup-pair  (xy-xyxy)  over over ;
:nip       (xy-y)     swap drop ;
:drop-pair (nn-)      drop drop ;
:?dup      (n-nn||n-n) dup 0; ;
:prefix:` (s-) &Compiler fetch [ s:to-number , ] [ drop ] choose ; immediate
:d:create (s-)
  (s-) &class:data #0 d:add-header
  here d:last d:xt store ;
:var    (s-)  d:create #0 , ;
:var<n> (ns-) d:create , ;
:const  (ns-) d:create d:last d:xt store ;
:TRUE  (-n) #-1 ;
:FALSE (-n)  #0 ;
:n:zero?      (n-f)   #0 eq? ;
:n:-zero?     (n-f)   #0 -eq? ;
:n:negative?  (n-f)   #0 lt? ;
:n:positive?  (n-f)   #-1 gt? ;
:n:strictly-positive?  (n-f)  #0 gt? ;
:n:even?      (n-f)  #2 /mod drop n:zero? ;
:n:odd?       (n-f)  #2 /mod drop n:-zero? ;
:dip  (nq-n)  swap push call pop ;
:sip  (nq-n)  push dup pop swap &call dip ;
:bi  (xqq-)  &sip dip call ;
:bi*  (xyqq-) &dip dip call ;
:bi@  (xyq-)  dup bi* ;
:tri  (xqqq-)  [ &sip dip sip ] dip call ;
:tri*  (xyzqqq-)  [ [ swap &dip dip ] dip dip ] dip call ;
:tri@ dup dup tri* ;
:while  (q-)  [ repeat dup dip swap 0; drop again ] call drop ;
:until  (q-)  [ repeat dup dip swap #-1 xor 0; drop again ] call drop ;
:times  (q-)  swap [ repeat 0; #1 - push &call sip pop again ] call drop ;
:case
  [ over eq? ] dip swap
  [ nip call TRUE ] [ drop FALSE ] choose 0; pop drop drop ;
:compiling?  (-f)  &Compiler fetch ;
:rot       (abc-bca)   [ swap ] dip swap ;
:tors (-n)  pop pop dup push swap push ;
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
:v:inc-by  (na-)   [ fetch + ] sip store ;
:v:dec-by  (na-)   [ fetch swap - ] sip store ;
:v:inc     (n-n)   #1 swap v:inc-by ;
:v:dec     (n-n)   #1 swap v:dec-by ;
:v:limit   (alu-)  push push dup fetch pop pop n:limit swap store ;
:v:on      (a-)    TRUE swap store ;
:v:off     (a-)    FALSE swap store ;
:allot     (n-)    &Heap v:inc-by ;
:v:update-using (aq-) swap [ fetch swap call ] sip store ;
:ScopeList `0 `0 ;
:{{ d:last dup &ScopeList store-next store ;
:---reveal--- d:last &ScopeList n:inc store ;
:}} &ScopeList fetch-next swap fetch eq? [ &ScopeList fetch &Dictionary store ] [ &ScopeList fetch [ &Dictionary repeat fetch dup fetch &ScopeList n:inc fetch -eq? 0; drop again ] call store ] choose ;
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
:later pop pop swap push push ;
:copy   (aan-) [ &fetch-next dip store-next ] times drop drop ;
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
:s:skip (-) pop [ fetch-next n:-zero? ] while n:dec push ;
:s:keep (s-s) compiling? [ &s:skip class:word ] if here [ s, ] dip class:data ;
:prefix:' compiling? [ s:keep ] [ s:temp ] choose ; immediate
:s:chop (s-s) s:temp dup s:length over + n:dec #0 swap store ;
:s:reverse (s-s)
  dup s:temp buffer:set &s:length [ dup s:length + n:dec ] bi swap
  [ dup fetch buffer:add n:dec ] times drop buffer:start s:temp ;
:s:trim-left (s-s) s:temp [ fetch-next [ #32 eq? ] [ n:zero? ] bi and ] while n:dec ;
:s:trim-right (s-s) s:temp s:reverse s:trim-left s:reverse ;
:s:trim (s-s) s:trim-right s:trim-left ;
:s:prepend (ss-s)
  s:temp [ dup s:length + [ dup s:length n:inc ] dip swap copy ] sip ;
:s:append (ss-s) swap s:prepend ;
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
:s:substr (sfl-s)
  [ + s:empty ] dip [ over [ copy ] dip ] sip
  over [ + #0 swap store ] dip ;
{{
  :<s:hash> repeat push #33 * pop fetch-next 0; swap push + pop again ;
---reveal---
  :s:hash  (s-n)  #5381 swap <s:hash> drop ;
}}
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
:s:to-upper (s-s)
  [ c:to-upper ] s:map ;
:s:to-lower (s-s)
  [ c:to-lower ] s:map ;
{{
  :Value `0 ;
---reveal---
  :n:to-string  (n-s)
    here buffer:set dup &Value store n:abs
    [ #10 /mod swap $0 + buffer:add dup n:-zero? ] while drop
    &Value fetch n:negative? [ $- buffer:add ] if
    buffer:start s:reverse s:temp ;
}}
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
:curry (vp-p) here [ swap compile:lit compile:call compile:ret ] dip ;
:does (q-)
  d:last<xt> swap curry d:last d:xt store &class:word reclass ;
:cons (nn-p) here [ swap , , ] dip ;
:s:for-each (sq-)
  [ repeat
      over fetch 0; drop
      dup-pair
      [ [ [ fetch ] dip call ] dip ] dip
      [ n:inc ] dip
    again
  ] call drop-pair ;
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
{{
  'Values var #27 allot
  :from s:length dup [ [ &Values + store ] sip n:dec ] times drop ;
  :to dup s:length [ fetch-next $a -  n:inc &Values + fetch swap ] times drop ;
---reveal---
  :reorder (...ss-?) [ from ] dip to ;
}}
:putc (c-) `1000 ;
:nl   (-)  ASCII:LF putc ;
:puts (s-) [ putc ] s:for-each ;
:putn (n-) n:to-string puts ASCII:SPACE putc ;
