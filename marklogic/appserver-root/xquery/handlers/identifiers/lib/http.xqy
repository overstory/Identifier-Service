xquery version "1.0-ml";

module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:http";

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "constants.xqy";
import module namespace re="urn:overstory:rest:modules:rest:errors" at "../../../rest/lib-rest/errors.xqy";

declare namespace e = "http://ns.overstory.co.uk/namespaces/resources/error";
declare namespace i = "http://ns.overstory.co.uk/namespaces/resources/meta/id";



declare function get-xml-body (
) as element()
{
	get-body ("xml", fn:true())
};

declare function get-xml-body-optional (
) as element()?
{
	get-body ("xml", fn:false())
};

declare function return-identifer-info-xml (
	$id-info as element(i:identifier-info)
) as element(i:identifier-info)
{
	let $_ := xdmp:set-response-code (200, "OK")
	let $_ := xdmp:set-response-content-type ($const:ID-METADATA-MIME-TYPE)
	let $_ := if ($id-info/i:system/i:etag) then xdmp:add-response-header ("ETag", $id-info/i:system/i:etag/fn:string()) else ()
	return $id-info
};

declare function set-created-response-with-location-and-etag (
	$uri as xs:string,
	$etag as xs:string,
	$id-uri-root as xs:string
) as empty-sequence()
{
	let $_ := xdmp:set-response-code (201, "Created")
	let $_ := xdmp:add-response-header ("Location", fn:concat ($id-uri-root, $uri))
	let $_ := xdmp:add-response-header ("X-URI", $uri)
	let $_ := xdmp:add-response-header ("ETag", $etag)
	return ()
};

declare function return-no-content (
	$new-etag as xs:string?
) as empty-sequence()
{
	let $_ := xdmp:set-response-code (204, "No Content")
	let $_ := xdmp:add-response-header ("ETag", $new-etag)
	return ()
};

declare function return-bad-request-error (
	$error as element()*
) as element(e:errors)
{
	let $_ := xdmp:set-response-code (400, "Bad Request")
	let $_ := xdmp:set-response-content-type ($const:ERROR-XML-MIME-TYPE)
	return
	<e:errors>{
		$error
	}</e:errors>
};

declare function return-not-found-error-for-id (
	$uri as xs:string?
) as element(e:errors)
{
	let $_ := xdmp:set-response-code (404, "Not Found")
	let $_ := xdmp:set-response-content-type ($const:ERROR-XML-MIME-TYPE)
	return
	<e:errors>{
		<e:resource-not-found>
			<e:message>Requested resource '{ $uri }' was not found</e:message>
			<e:uri>{ $uri }</e:uri>
		</e:resource-not-found>
	}</e:errors>
};

declare function return-etag-conflict (
	$existing-etag as xs:string,
	$given-etag as xs:string?
) as element(e:errors)
{
	let $_ := xdmp:set-response-code (409, "Conflict")
	let $_ := xdmp:set-response-content-type ($const:ERROR-XML-MIME-TYPE)
	let $msg :=
		if (fn:empty ($given-etag))
		then "ETag value must be provided on mutation request, current ETag: " || $existing-etag
		else "Given ETag (" || $given-etag || ") does not match current ETag (" || $existing-etag || ")"
	return
	<e:errors>{
		<e:etag-mismatch>
			<e:message>{ $msg }</e:message>
			<e:given-etag>{ $given-etag }</e:given-etag>
			<e:current-etag>{ $existing-etag }</e:current-etag>
		</e:etag-mismatch>
	}</e:errors>
};

(: ------------------------------------------------------------ :)

declare private function get-body (
	$type as xs:string,
	$required as xs:boolean
) as node()?
{
    try {
        let $body := xdmp:get-request-body ($type)
        let $node as node()? := ($body/(element(), $body/binary(), $body/text()))[1]
        return
        if (fn:empty ($node) and $required)
        then re:throw-xml-error ('HTTP-EMPTYBODY', 400, "Empty body", empty-body ("Expected XML body is empty"))
        else $node
    } catch ($e) {
        re:throw-xml-error ('HTTP-MALXMLBODY', 400, "Malformed request body", malformed-body ($e))
    }
};

declare private function empty-body (
	$msg as xs:string
) as element(e:empty-body)
{
	<e:empty-body>
		<e:message>{ $msg }</e:message>
	</e:empty-body>
};

declare private function malformed-body (
	$error as element(error:error)
) as element(e:malformed-body)
{
	let $msg :=
		if ($error)
		then $error/error:message/fn:string()
		else "Unknown error occurred"

	return
	<e:malformed-body>
		<e:message>{ $msg }</e:message>
	</e:malformed-body>
};

