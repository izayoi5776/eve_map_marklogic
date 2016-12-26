  xquery version "1.0-ml";

  import module namespace admin = "http://marklogic.com/xdmp/admin" 
      at "/MarkLogic/admin.xqy";
  declare namespace st = "http://marklogic.com/xdmp/status/server";

declare function local:getJobCount(){
  let $config := admin:get-configuration()
  let $id := admin:group-get-taskserver-id($config, admin:group-get-id($config,"Default"))

  let $remain := (xdmp:server-status(xdmp:host(),$id)/st:queue-size +
   count(xdmp:server-status(xdmp:host(),$id)//st:request-status))
  let $_ := xdmp:log("DEBUG:jobs remain:[" || $remain || "]")
  return $remain
};
declare function local:savelog(){
  xdmp:document-insert("/eve/tmp/routetablelog.xml",
    element routetablelog{
      element log{
        attribute tm{current-dateTime()},
        attribute jobs{local:getJobCount()}
      }
    }
  )
};

(:
count(/routetable/route[@by="NOT_SET"])
:)

local:savelog()
