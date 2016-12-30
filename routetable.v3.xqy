module namespace eve = "https://eve.marklogic.zhangxiaodong.net";

(: add all route when hop0 :)
declare function newRouteTemplete(){
  for $i in (/nodes/node/id/string()) return
      element route{
        attribute by{  "NOT_SET"},
        attribute to {$i},
        attribute hop{0}
      }
};
(: init :)
declare function initRouteTable(){
  let $_ := xdmp:log("DEBUG:initRouteTable(0)")
  let $fn := "/eve/tmp/state.xml"
  let $_ := xdmp:document-insert($fn, element routetablestate{0})

  let $a := newRouteTemplete()
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
declare function level1(){
  let $_ := xdmp:log("DEBUG:level1(1)")
  let $fn := "/eve/tmp/state.xml"
  let $_ := xdmp:document-insert($fn, element routetablestate{1})

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
        let $_ := xdmp:node-replace($old, $new)
        return ()
      let $_ := xdmp:node-delete($a/route[@to=$i])
      return ()
    })
};
(: run level $n :)
declare function doLevel_old($id, $n){
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
(: run level $n :)
declare function doLevel($id, $n){
  (: find all neighbor :)
  let $n := xs:decimal($n)
  let $self := /routetable[from=$id]
  let $neighbor := /routetable[from=$self/route[@hop="1"]/@to]
  (: get route level(n-1) from neighbors :)
  (: except unknown, by me :)
  let $routen_1 := $neighbor/route[not(@by="NOT_SET" or @by=$id)and @hop=($n - 1)]
  (: replace routes of my table :)
  let $oldlist := ()
  for $i in $routen_1 return
    (: let $old := $self/route[@to=$i/@to and (@by="NOT_SET" or @hop>$n)] :)
    let $old := cts:search(doc("/eve/routetable/" || $id || ".xml")/routetable/route,
      cts:and-query((
        cts:element-attribute-word-query(xs:QName("route"), xs:QName("to"), $i/@to),
        cts:or-query((
          cts:element-attribute-word-query(xs:QName("route"), xs:QName("by"), "NOT_SET"),
          cts:element-attribute-range-query(xs:QName("route"), xs:QName("hop"), ">", $n)
        ))
      ))
    )
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
declare function getNextState(){
  let $fn := "/eve/tmp/state.xml"
  let $_ := xdmp:lock-for-update($fn)
  let $cur := /routetablestate/data()
  let $_ := xdmp:document-insert($fn, element routetablestate{$cur + 1})
  return $cur + 1
};
(: === main === :)
declare function runNextLevel(){
  let $n := getNextState()
  let $_ := xdmp:log("DEBUG:runNextLevel(" || $n || ")")
  return map(function($a){
    xdmp:spawn-function(function(){
      doLevel($a, $n)
    })
  }, /nodes/node/id/string())
};
