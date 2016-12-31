(: find path :)
declare function local:oneStep($from, $to){
  let $thisnode := /routetable[from=$from]/route[@to=$to]
  return ($thisnode/@by/string(), if($thisnode/@hop > 0) then local:oneStep($thisnode/@by, $to) else ())
};
(: id to name :)
declare function local:id2name($id){
  for $i in $id return
    /nodes/node[id=$i]/name/string()
};
(: name to id :)
declare function local:name2id($name){
  for $i in $name return
    /nodes/node[name=$i]/id
};


let $action := xdmp:get-request-field("a")
let $from := xdmp:get-request-field("f")
let $to := xdmp:get-request-field("t")
let $_:= xdmp:set-response-content-type("text/html")

(:let $from := "Jita"
let $to := "Tanoo"
:)

return
if($action) then 
  let $_ := xdmp:log("$f=" || $from || " $t=" || $to)
  return ($from,local:id2name(
    local:oneStep(
      local:name2id($from)[1], 
      local:name2id($to)[1]
    )
  ))
else (: top page :)
  let $op := fold-left(function($z, $a){$z || $a},(), (
      for $i in /nodes/node/name/string()
        order by $i
        return '<option value="' || $i || '">'|| $i ||'</option>'))

  return
  '<script type="text/javascript">
    function getResult(){
		var req = new XMLHttpRequest();
		req.onreadystatechange = function() {
			var result = document.getElementById("result");
				if (req.readyState == 4) { // 通信の完了時
				if (req.status == 200) { // 通信の成功時
					result.innerHTML = req.responseText;
				}
				}else{
					result.innerHTML = "通信中..."
				}
			}
		var url = "&amp;f="
			  + encodeURIComponent(document.getElementById("f").value)
			  + "&amp;t="
			  + encodeURIComponent(document.getElementById("t").value)
		console.debug(url)
		req.open("GET", "starmapapi.xqy?a=path" + url, true);
		//req.open("GET", "starmapapi.xqy?a=path&amp;f=Jita&amp;t=Sinid", true);
		req.send();
    };
  </script>
  <form name "fm">' ||
    'FROM <select id="f">' || $op || '</select>' ||
    '<p>TO <select id="t">' || $op || '</select></p>' ||
    '<p><a href="javascript:null(0);" onclick="getResult()">getResult()</a></p>
    <div id="result" />
   </form>'

