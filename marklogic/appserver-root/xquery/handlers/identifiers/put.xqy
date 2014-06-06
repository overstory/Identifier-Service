xquery version "1.0-ml";

import module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier" at "lib/identifier.xqy";
import module namespace http="urn:overstory:modules:data-mesh:handlers:lib:http" at "lib/http.xqy";
import module namespace anno="urn:overstory:modules:data-mesh:handlers:lib:annotation" at "lib/annotation.xqy";

declare namespace i = "http://ns.overstory.co.uk/namespaces/resources/meta/id";
declare namespace e = "http://overstory.co.uk/ns/errors";

declare variable $id as xs:string? := xdmp:get-request-field ("id", ());
declare variable $etag as xs:string? := xdmp:get-request-header ("ETag", ());
declare variable $annotation as element(i:annotation) := lib:validate-annotation (http:get-xml-body());
declare variable $id-info as element(i:identifier-info)? := lib:get-identifier-info ($id);

(: ToDo: Check for permission to delete :)

if (fn:empty ($id-info))
then http:return-not-found-error-for-id ($id)
else
	if (fn:not ($id-info/i:system/i:etag = $etag))
	then http:return-etag-conflict ($id-info/i:system/i:etag/fn:string(), $etag)
	else (
		let $new-id-info := lib:replace-annotation ($id-info, $annotation)
		return http:return-no-content ($new-id-info/i:system/i:etag)
	)
