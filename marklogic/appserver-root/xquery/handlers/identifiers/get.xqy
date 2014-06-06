xquery version "1.0-ml";

import module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier" at "lib/identifier.xqy";
import module namespace http="urn:overstory:modules:data-mesh:handlers:lib:http" at "lib/http.xqy";

declare namespace i = "http://ns.overstory.co.uk/namespaces/resources/meta/id";

declare variable $id as xs:string? := xdmp:get-request-field ("id", ());
declare variable $accept-header as xs:string? := xdmp:get-request-header ("Accept", ());	(: ToDo: Verify that Accept is a recognized type :)
declare variable $id-info as element(i:identifier-info)? := lib:get-identifier-info ($id);


if (fn:exists ($id-info))
then http:return-identifer-info-xml ($id-info)
else http:return-not-found-error-for-id ($id)

(: ToDo: Send Last-Modified header :)