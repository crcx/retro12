'ns:Previous var
#64 array:new 'ns:PUBLIC const
'ns:Latest var
:public  (-)
  &Dictionary fetch
  ns:PUBLIC &ns:Latest fetch array:nth 
  store 
  &ns:Latest v:inc ;
:ns:relink
  @ns:Latest
  [ &ns:Latest v:dec
    @ns:Previous
    ns:PUBLIC @ns:Latest array:nth
    fetch [ store ] sip
    !ns:Previous
  ] times ;
:ns{  (-)
  #0 !ns:Latest
  @Dictionary !ns:Previous ;
:}ns  (-)
  ns:relink
  @ns:Previous !Dictionary ;
