(: add all route when initialize :)
declare function local:newRouteTemplete(){
  for $i in (/nodes/node/id/string()) return
      element route{
        attribute by{  "NOT_SET"},
        attribute to {$i},
        attribute hop{0}
      }
};
(: èâä˙âª :)
declare function local:initRouteTable(){
  let $a := local:newRouteTemplete()
  let $rt := for $i in distinct-values(/nodes/node/id)
    return xdmp:spawn-function(function(){
      xdmp:document-insert("/eve/routetable/" || $i || ".xml", 
        element routetable{
          element from{$i},
          $a
      })
    })
  return ()
};
(:
(/edges/edge)[1]
:)
(local:initRouteTable())
