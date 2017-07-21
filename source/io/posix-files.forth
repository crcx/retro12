#0 'file:R const
#1 'file:W const
#2 'file:A const
:file:open  (sm-h) `118 ;
:file:close (h-)   `119 ;
:file:read  (h-c)  `120 ;
:file:write (ch-)  `121 ;
:file:tell  (h-n)  `122 ;
:file:seek  (nh-)  `123 ;
:file:size  (h-n)  `124 ;
:file:delete (s-)  `125 ;
:file:flush (f-)   `126 ;
:file:exists?  (s-f)
  file:R file:open dup n:-zero?
  [ file:close TRUE ]
  [ drop FALSE ] choose ;
