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
(: run level $n :)
declare function local:doLevel($id, $n){
  (: find all neighbor :)
  let $self := /routetable[from=$id]
  let $neighbor := /routetable[from=$self/route[@hop="1"]/@to]
  (: get route level(n-1) from neighbors :)
  (: except unknown, by me :)
  let $routen_1 := $neighbor/route[not(@by="NOT_SET" or @by=$id)and @hop=($n - 1)]
  (: replace routes of my table :)
  let $oldlist := ()
  for $i in $routen_1 return
    let $old := $self/route[@to=$i/@to and (@by="NOT_SET" or @hop>$n)]
    (: if 2 route to same star, use the first :)
    let $old := if($old/@to = $oldlist) then () else $old
    let $_ := xdmp:set($oldlist, ($old/@to, $oldlist))
    let $new := element route{
      attribute by{$i/../from/string()},
      attribute to{$i/@to},
      attribute hop{$n}
    }
    let $_ := xdmp:node-replace($old, $new)
    return ()
};
declare function local:getNextState(){
  let $fn := "/eve/tmp/state.xml"
  let $_ := xdmp:lock-for-update($fn)
  let $cur := /routetablestate/data()
  let $_ := document-insert($fn, element routetablestate{$cur + 1})
  return $cur + 1
};
(: === main === :)
map(function($a){
  xdmp:spawn-function(function(){
    local:doLevel($a,  local:getNextState())
  })
}, /nodes/node/id/string())
