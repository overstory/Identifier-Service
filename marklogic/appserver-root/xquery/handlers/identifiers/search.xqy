xquery version "1.0-ml";

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "lib/constants.xqy";
import module namespace search="urn:overstory:modules:data-mesh:handlers:lib:search" at "lib/search.xqy";
import module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier" at "lib/identifier.xqy";
import module namespace http="urn:overstory:modules:data-mesh:handlers:lib:http" at "lib/http.xqy";

declare namespace i = "http://ns.overstory.co.uk/namespaces/resources/meta/id";

declare option xdmp:output "indent=yes";

declare variable $terms as xs:string? := xdmp:get-request-field ("terms", ());

declare variable $ipp as xs:string? := xdmp:get-request-field ("ipp", "10");
declare variable $page as xs:string? := xdmp:get-request-field ("page", "1");

declare variable $search-criteria :=
	<search-criteria>
		<terms>{ $terms }</terms>
		<ipp>{ $ipp }</ipp>
		<page>{ $page }</page>
	</search-criteria>;

(: --------------------------------------------------- :)

let $query as cts:query := search:build-search-query ($search-criteria)
let $results as element(search-results) := search:perform-search ($query, $search-criteria)
let $_ := xdmp:set-response-content-type ($const:ID-METADATA-BRIEF-MIME-TYPE)

return $results
