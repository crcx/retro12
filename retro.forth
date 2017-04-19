:EOM  (-n)  #-3 fetch ;
:d:last        (-d) &Dictionary fetch ;
:d:last<xt>    (-a) d:last d:xt fetch ;
:d:last<class> (-a) d:last d:class fetch ;
:d:last<name>  (-s) d:last d:name ;
:reclass    (a-) d:last d:class store ;
:immediate  (-)  &class:macro reclass ;
:data       (-)  &class:data reclass ;
:prefix:@  (s-n) d:lookup d:xt fetch class:data &fetch class:word ; immediate
:prefix:!  (s-n) d:lookup d:xt fetch class:data &store class:word ; immediate
:compile:lit  (a-) #1 , , ;
:compile:jump (a-) #1793 , , ;
:compile:call (a-) #2049 , , ;
:compile:ret  (-)  #10 , ;
:compiling?  (-f)  @Compiler ;
:prefix:`  (s-)
  compiling? [ s:to-number , ] [ drop ] choose ; immediate
:here  (-a) @Heap ;
:d:create (s-)
  (s-) &class:data #0 d:add-header
  here d:last d:xt store ;
:var    (s-)  d:create #0 , ;
:var<n> (ns-) d:create , ;
:const  (ns-) d:create d:last d:xt store ;
:tuck      (xy-yxy)   dup push swap pop ;
:over      (xy-xyx)   push dup pop swap ;
:dup-pair  (xy-xyxy)  over over ;
:nip       (xy-y)     swap drop ;
:drop-pair (nn-)      drop drop ;
:?dup      (n-nn||n-n) dup 0; ;
:dip  (nq-n)  swap push call pop ;
:sip  (nq-n)  push dup pop swap &call dip ;
:bi  (xqq-)  &sip dip call ;
:bi*  (xyqq-) &dip dip call ;
:bi@  (xyq-)  dup bi* ;
:tri  (xqqq-)  [ &sip dip sip ] dip call ;
:tri*  (xyzqqq-)  [ [ swap &dip dip ] dip dip ] dip call ;
:tri@ dup dup tri* ;
:while  (q-)
  [ repeat dup dip swap 0; drop again ] call drop ;
:until  (q-)
  [ repeat dup dip swap #-1 xor 0; drop again ] call drop ;
:times  (q-)
  swap [ repeat 0; #1 - push &call sip pop again ] call drop ;
:TRUE  (-n) #-1 ;
:FALSE (-n)  #0 ;
:lteq?  (nn-f)  dup-pair eq? [ lt? ] dip or ;
:gteq?  (nn-f)  dup-pair eq? [ gt? ] dip or ;
:n:zero?      (n-f)   #0 eq? ;
:n:-zero?     (n-f)   #0 -eq? ;
:n:negative?  (n-f)   #0 lt? ;
:n:positive?  (n-f)   #-1 gt? ;
:n:strictly-positive?  (n-f)  #0 gt? ;
:n:even?      (n-f)  #2 /mod drop n:zero? ;
:n:odd?       (n-f)  #2 /mod drop n:-zero? ;
:case
  [ over eq? ] dip swap
  [ nip call TRUE ] [ drop FALSE ] choose 0; pop drop drop ;
:s:case
  [ over s:eq? ] dip swap
  [ nip call TRUE ] [ drop FALSE ] choose 0; pop drop drop ;
:rot  (abc-bca)   [ swap ] dip swap ;
:tors (-n)  pop pop dup push swap push ;
:/         (nq-d)  /mod swap drop ;
:mod       (nq-r)  /mod drop ;
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
:copy   (aan-) [ &fetch-next dip store-next ] times drop drop ;
:ScopeList `0 `0 ;
:{{            (-)
  d:last dup &ScopeList store-next store ;
:---reveal---  (-)
   d:last &ScopeList n:inc store ;
:}}            (-)
  &ScopeList fetch-next swap fetch eq?
  [ @ScopeList !Dictionary ]
  [ @ScopeList [ &Dictionary repeat fetch dup fetch &ScopeList n:inc fetch -eq? 0; drop again ] call store ] choose ;
{{
  :Buffer `0 ; data
  :Ptr    `0 ; data
  :terminate (-) #0 @Ptr store ;
---reveal---
  :buffer:start  (-a) @Buffer ;
  :buffer:end    (-a) @Ptr ;
  :buffer:add    (c-) buffer:end store &Ptr v:inc terminate ;
  :buffer:get    (-c) &Ptr v:dec buffer:end fetch terminate ;
  :buffer:empty  (-)  buffer:start !Ptr terminate ;
  :buffer:size   (-n) buffer:end buffer:start - ;
  :buffer:set    (a-) !Buffer buffer:empty ;
  :buffer:preserve (q-)
    @Buffer @Ptr [ [ call ] dip !Buffer ] dip !Ptr ;
}}
:TempStrings ;   &class:data reclass  #12 !TempStrings
:TempStringMax ; &class:data reclass #512 !TempStringMax
:STRINGS   EOM @TempStrings @TempStringMax * - ;
{{
  :MAX-LENGTH #512 ;
  :s:Current `0 ; data
  :s:pointer (-p)  @s:Current MAX-LENGTH * STRINGS + ;
  :s:next    (-)
    &s:Current v:inc
    @s:Current @TempStrings eq? [ #0 !s:Current ] if ;
---reveal---
  :s:temp (s-s) dup s:length n:inc s:pointer swap copy s:pointer s:next ;
  :s:empty (-s) s:pointer s:next ;
}}
:s:skip (-) pop [ fetch-next n:-zero? ] while n:dec push ;
:s:keep (s-s) compiling? [ &s:skip class:word ] if here [ s, ] dip class:data ;
:prefix:' compiling? [ s:keep ] [ s:temp ] choose ; immediate
:s:chop (s-s) s:temp dup s:length over + n:dec #0 swap store ;
:s:reverse (s-s)
  [ dup s:temp buffer:set &s:length [ dup s:length + n:dec ] bi swap
    [ dup fetch buffer:add n:dec ] times drop buffer:start s:temp ]
  buffer:preserve ;
:s:trim-left (s-s) s:temp [ fetch-next [ #32 eq? ] [ n:zero? ] bi and ] while n:dec ;
:s:trim-right (s-s) s:temp s:reverse s:trim-left s:reverse ;
:s:trim (s-s) s:trim-right s:trim-left ;
:s:prepend (ss-s)
  s:temp [ dup s:length + [ dup s:length n:inc ] dip swap copy ] sip ;
:s:append (ss-s) swap s:prepend ;
:s:for-each (sq-)
  [ repeat
      over fetch 0; drop
      dup-pair
      [ [ [ fetch ] dip call ] dip ] dip
      [ n:inc ] dip
    again
  ] call drop-pair ;
:s:filter (sq-s)
  [ s:empty buffer:set swap
    [ dup-pair swap call
        [ buffer:add ]
        [ drop       ] choose
    ] s:for-each drop buffer:start
  ] buffer:preserve ;
:s:map (sq-s)
  [ s:empty buffer:set swap
    [ over call buffer:add ]
    s:for-each drop buffer:start
  ] buffer:preserve ;
:s:substr (sfl-s)
  [ + s:empty ] dip [ over [ copy ] dip ] sip
  over [ + #0 swap store ] dip ;
:s:hash (s-n) #5381 swap [ swap #33 * + ] s:for-each ;
:ASCII:NUL     (-c)  #0 ;    :ASCII:SOH     (-c)  #1 ;
:ASCII:STX     (-c)  #2 ;    :ASCII:ETX     (-c)  #3 ;
:ASCII:EOT     (-c)  #4 ;    :ASCII:ENQ     (-c)  #5 ;
:ASCII:ACK     (-c)  #6 ;    :ASCII:BEL     (-c)  #7 ;
:ASCII:BS      (-c)  #8 ;    :ASCII:HT      (-c)  #9 ;
:ASCII:LF      (-c)  #10 ;   :ASCII:VT      (-c)  #11 ;
:ASCII:FF      (-c)  #12 ;   :ASCII:CR      (-c)  #13 ;
:ASCII:SO      (-c)  #14 ;   :ASCII:SI      (-c)  #15 ;
:ASCII:DLE     (-c)  #16 ;   :ASCII:DC1     (-c)  #17 ;
:ASCII:DC2     (-c)  #18 ;   :ASCII:DC3     (-c)  #19 ;
:ASCII:DC4     (-c)  #20 ;   :ASCII:NAK     (-c)  #21 ;
:ASCII:SYN     (-c)  #22 ;   :ASCII:ETB     (-c)  #23 ;
:ASCII:CAN     (-c)  #24 ;   :ASCII:EM      (-c)  #25 ;
:ASCII:SUB     (-c)  #26 ;   :ASCII:ESC     (-c)  #27 ;
:ASCII:FS      (-c)  #28 ;   :ASCII:GS      (-c)  #29 ;
:ASCII:RS      (-c)  #30 ;   :ASCII:US      (-c)  #31 ;
:ASCII:SPACE   (-c)  #32 ;   :ASCII:DEL     (-c)  #127 ;
:c:letter?      (c-f) $A $z n:between? ;
:c:lowercase?   (c-f) $a $z n:between? ;
:c:uppercase?   (c-f) $A $Z n:between? ;
:c:digit?       (c-f) $0 $9 n:between? ;
:c:whitespace?  (c-f)
  ASCII:SPACE [ TRUE ] case
  ASCII:HT    [ TRUE ] case
  ASCII:LF    [ TRUE ] case
  ASCII:CR    [ TRUE ] case
  drop FALSE ;
:c:visible?     (c-f) #31 #126 n:between? ;
:c:vowel?       (c-f)
  $a [ TRUE ] case
  $e [ TRUE ] case
  $i [ TRUE ] case
  $o [ TRUE ] case
  $u [ TRUE ] case
  $A [ TRUE ] case
  $E [ TRUE ] case
  $I [ TRUE ] case
  $O [ TRUE ] case
  $U [ TRUE ] case
  drop FALSE ;
:c:consonant?   (c-f)
  dup c:letter? [ c:vowel? not ] [ drop FALSE ] choose ;
:c:-lowercase?  (c-f) c:lowercase? not ;
:c:-uppercase?  (c-f) c:uppercase? not ;
:c:-digit?      (c-f) c:digit? not ;
:c:-whitespace? (c-f) c:whitespace? not ;
:c:-visible?    (c-f) c:visible? not ;
:c:-vowel?      (c-f)  c:vowel? not ;
:c:-consonant?  (c-f)  c:consonant? not ;
:c:to-upper     (c-c) dup c:lowercase? 0; drop ASCII:SPACE - ;
:c:to-lower     (c-c) dup c:uppercase? 0; drop ASCII:SPACE + ;
:c:toggle-case  (c-c) dup c:lowercase? [ c:to-upper ] [ c:to-lower ] choose ;
:c:to-string    (c-s) '. s:temp [ store ] sip ;
:s:to-upper  (s-s)  [ c:to-upper ] s:map ;
:s:to-lower  (s-s)  [ c:to-lower ] s:map ;
{{
  :Value `0 ;
---reveal---
  :n:to-string  (n-s)
    [ here buffer:set dup !Value n:abs
      [ #10 /mod swap $0 + buffer:add dup n:-zero? ] while drop
      @Value n:negative? [ $- buffer:add ] if
      buffer:start s:reverse s:temp ] buffer:preserve ;
}}
TRUE 'RewriteUnderscores var<n>
{{
  :sub (c-c) $_ [ ASCII:SPACE ] case ;
  :rewrite (s-s)
    @RewriteUnderscores [ [ sub ] s:map ] if &prefix:' call ;
---reveal---
  :prefix:' rewrite ; immediate
}}
:s:index-of (sc-n)
  swap [ repeat
           fetch-next 0; swap
           [ over -eq? ] dip
           swap 0; drop
         again
       ] sip
  [ - n:dec nip ] sip
  s:length over eq? [ drop #-1 ] if ;
:s:has-char? (sc-f) s:index-of #-1 -eq? ;
{{
  'Values var #27 allot
  :from s:length dup [ [ &Values + store ] sip n:dec ] times drop ;
  :to dup s:length [ fetch-next $a -  n:inc &Values + fetch swap ] times drop ;
---reveal---
  :reorder (...ss-?) [ from ] dip to ;
}}
:curry (vp-p) here [ swap compile:lit compile:call compile:ret ] dip ;
:does  (q-)   d:last<xt> swap curry d:last d:xt store &class:word reclass ;
:d:for-each (q-)
  &Dictionary [ repeat fetch 0;
 dup-pair [ [ swap call ] dip ] dip again ] call drop ;
{{
  :char (c-)
    $n [ ASCII:LF buffer:add ] case
    $t [ ASCII:HT buffer:add ] case
    buffer:add ;
  :string (a-a)
    repeat fetch-next 0; buffer:add again ;
  :type (aac-)
    $c [ swap buffer:add              ] case
    $s [ swap string drop             ] case
    $n [ swap n:to-string string drop ] case
    drop ;
  :handle (ac-a)
    $\ [ fetch-next char ] case
    $% [ fetch-next type ] case
    buffer:add ;
---reveal---
  :s:with-format (...s-s)
    [ s:empty [ buffer:set
      [ repeat fetch-next 0; handle again ]
      call drop ] sip ] buffer:preserve ;
}}
:putc (c-) `1000 ;
:nl   (-)  ASCII:LF putc ;
:sp   (-)  ASCII:SPACE putc ;
:tab  (-)  ASCII:HT putc ;
:puts (s-) [ putc ] s:for-each ;
:putn (n-) n:to-string puts ;
:words  (-)  [ d:name puts sp ] d:for-each ;
:depth  (-n) #-1 fetch ;
:reset  (...-) depth repeat 0; push drop pop #1 - again ;
