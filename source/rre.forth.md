````
(RRE_Extensions_to_Core_Language)
:getc (-c) `1001 ;
#0 'file:R const
#1 'file:W const
#2 'file:A const
#3 'file:M const
:file:open  (sm-h) `118 ;
:file:close (h-)   `119 ;
:file:read  (h-c)  `120 ;
:file:write (ch-f) `121 ;
:file:tell  (ch-f) `122 ;
:file:seek  (?)    `123 ;
:file:size  (h-n)  `124 ;
:file:delete (s-)  `125 ;
:file:flush (f-)   `126 ;
:file:exists?  (s-f)
  file:R file:open dup n:-zero?
  [ file:close TRUE ]
  [ drop FALSE ] choose ;
````

````
:sys:argc (-n) `-6100 ;
:sys:argv (n-s) s:empty swap `-6101 ;
````
