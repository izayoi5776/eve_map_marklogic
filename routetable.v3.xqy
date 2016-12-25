(: add all route when initialize :)
declare function local:newRouteNode($id){
 xdmp:document-insert("/eve/routetable/" || $id || ".xml", 
   element routetable{
        element from{$id},
        for $i in (/nodes/node/id/string()) return
          (: 自分は入れない :)
          if($i=$id) then ()
          else
            element route{
              attribute by {
                (: 隣以外は未知とセットする :)
                if(/edges/edge[from=$id and to=$i]) then $i else "NOT_SET"},
              attribute to {$i},
              (: 未知の場合のhopはこのhop数では未知の意味 :)
              attribute hop{1}
            }
    }
  )
};
(: 初期化 :)
declare function local:initRouteTable(){
  let $rt := for $i in distinct-values(/nodes/node/id)
    return xdmp:spawn-function(function(){local:newRouteNode($i)})
  return $rt
};
(:
(/edges/edge)[1]
:)
(local:initRouteTable())