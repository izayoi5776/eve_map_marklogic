(: add all route when initialize :)
declare function local:newRouteNode($id){
 xdmp:document-insert("/eve/routetable/" || $id || ".xml", 
   element routetable{
        element from{$id},
        for $i in (/nodes/node/id/string()) return
          (: �����͓���Ȃ� :)
          if($i=$id) then ()
          else
            element route{
              attribute by {
                (: �׈ȊO�͖��m�ƃZ�b�g���� :)
                if(/edges/edge[from=$id and to=$i]) then $i else "NOT_SET"},
              attribute to {$i},
              (: ���m�̏ꍇ��hop�͂���hop���ł͖��m�̈Ӗ� :)
              attribute hop{1}
            }
    }
  )
};
(: ������ :)
declare function local:initRouteTable(){
  let $rt := for $i in distinct-values(/nodes/node/id)
    return xdmp:spawn-function(function(){local:newRouteNode($i)})
  return $rt
};
(:
(/edges/edge)[1]
:)
(local:initRouteTable())