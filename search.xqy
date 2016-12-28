(: find path :)
declare function local:oneStep($from, $to){
  let $thisnode := /routetable[from=$from]/route[@to=$to]
  return ($thisnode/@by, if($thisnode/@hop > 0) then local:oneStep($thisnode/@by, $to) else ())
};
(: id to name :)
declare function local:id2name($id){
  for $i in $id return
    /nodes/node[id=$i]/name
};
(: name to id :)
declare function local:name2id($name){
  for $i in $name return
    /nodes/node[name=$i]/id
};

let $to := "30000012"
let $from := "30000001"
let $from := "30000001"
let $from := "30000142" (: Jita :)
let $to := "31002504"
let $to := "30000054"
let $to := "30000002"
let $to := "30000020" (: Lilmad :)
let $to := "30000001" (: Tanoo :)
let $froms := "Jita"
let $tos := "Tanoo"
return local:id2name(($from, local:oneStep(local:name2id($froms)[1], local:name2id($tos)[1])))

