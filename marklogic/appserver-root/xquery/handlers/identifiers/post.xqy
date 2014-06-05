xquery version "1.0-ml";

import module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier" at "lib/identifier.xqy";
import module namespace http="urn:overstory:modules:data-mesh:handlers:lib:http" at "lib/http.xqy";
import module namespace anno="urn:overstory:modules:data-mesh:handlers:lib:annotation" at "lib/annotation.xqy";

declare namespace i = "http://ns.iop.org/namespaces/resources/meta/id";
declare namespace e = "http://overstory.co.uk/ns/errors";


(:
Incoming doc example:

<i:annotation xmlns:i="http://ns.overstory.co.uk/resources/meta/id">
        <i:id>12345678</i:id>
        <i:content-type>image/jpg</i:content-type>
</i:annotation>
:)
(:

?template=article-{doi:10.1088/23414/21344/24/4}

?template=article-{doi:10.1088/23414/21344/24/4}.blob

?template=resource-{now}.blob

?template=manifestation:filestore-{}-{file: files/njp9_2_025008.pdf}

:)

(: POST Request body :)

declare variable $DEFAULT-TEMPLATE := "resource:{guid}";

declare variable $id-uri-root as xs:string? := xdmp:get-request-field ("id-uri-root", "/MIS-CONFIGURED-URI-ROOT/id/");
declare variable $template as xs:string? := xdmp:get-request-field ("template", $DEFAULT-TEMPLATE);
declare variable $content-type as xs:string? := xdmp:get-request-header ("Content-Type", ());   (: ToDo: Validate content-type header, if present :)
declare variable $annotation as element(i:annotation)? := lib:validate-annotation (http:get-xml-body-optional());
declare variable $identifier-info as element(i:identifier-info)? := lib:new-identifier ($template, $annotation);

declare function local:non-unique-template-error (
	$template as xs:string?
) as element(e:non-unique-template)
{
	<e:non-unique-template>
		<e:message>Cannot generate unique URI from template '{ $template }'</e:message>
		<e:template>{ $template }</e:template>
	</e:non-unique-template>
};

if (fn:exists ($identifier-info))
then http:set-created-response-with-location-and-etag ($identifier-info/i:system/i:uri/fn:string(), $identifier-info/i:system/i:etag/fn:string(), $id-uri-root)
else http:return-bad-request-error (local:non-unique-template-error ($template))


