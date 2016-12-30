xquery version "1.0-ml";

import module namespace admin = "http://marklogic.com/xdmp/admin" 
      at "/MarkLogic/admin.xqy";

import module namespace eve = "https://eve.marklogic.zhangxiaodong.net"
      at "/eve/routetable.v3.xqy";

declare namespace st = "http://marklogic.com/xdmp/status/server";

declare function local:getJobCount(){
  let $config := admin:get-configuration()
  let $id := admin:group-get-taskserver-id($config, admin:group-get-id($config,"Default"))

  let $remain := (xdmp:server-status(xdmp:host(),$id)/st:queue-size +
   count(xdmp:server-status(xdmp:host(),$id)//st:request-status))
  let $_ := xdmp:log("DEBUG:jobs remain:[" || $remain || "] at level [" || /routetablestate/string() || "]")
  return $remain
};
declare function local:savelog(){
  xdmp:node-insert-child(doc("/eve/tmp/routetablelog.xml")/*,
    element log{
      attribute tm{current-dateTime()},
      attribute jobs{local:getJobCount()}
    }
  )
};

(:
count(/routetable/route[@by="NOT_SET"])

:)
(: === main === :)
let $_ := local:savelog()
let $cur := /routetablestate/data()
return if($cur or $cur="0") then
  if(local:getJobCount() > 1) then ()
  else if($cur="0") then
    eve:level1()
  else
    eve:runNextLevel()
else
  eve:initRouteTable()

