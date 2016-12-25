(: add all route when hop0 :)
declare function local:newRouteTemplete(){
  for $i in (/nodes/node/id/string()) return
      element route{
        attribute by{  "NOT_SET"},
        attribute to {$i},
        attribute hop{0}
      }
};
(: init :)
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
(: fix hop1 in route table, only lvl1 need search /edges/edge :)
declare function local:level1(){
  for $i in distinct-values(/nodes/node/id) return
     xdmp:spawn-function(function(){
      let $a := doc("/eve/routetable/" || $i || ".xml")/*
      let $_ := for $j in /edges/edge[from=$i]/to/string() return
        let $old := $a/route[@to=$j]
        let $new := element route{
          attribute by{$j},
          attribute to{$j},
          attribute hop{1}
        }
        let $_ := xdmp:log(("old=" , $old , " new=" , $new))
        let $_ := xdmp:node-replace($old, $new)
        return ()
      let $_ := xdmp:node-delete($a/route[@to=$i])
      return ()
    })
};

local:level1()
