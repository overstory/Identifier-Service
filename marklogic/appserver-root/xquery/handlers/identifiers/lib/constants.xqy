xquery version "1.0-ml";

module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants";

declare variable $ID-COLLECTION-NAME as xs:string := "urn:overstory:collection:resource:identifier";

declare variable $ID-METADATA-MIME-TYPE := "application/vnd.overstory.meta.id+xml";
declare variable $ID-METADATA-BRIEF-MIME-TYPE := "application/vnd.overstory.meta.id.brief+xml";		(: Only used between NetKernel and MarkLogic :)
declare variable $ERROR-XML-MIME-TYPE := "application/vnd.overstory.error+xml";
(: declare variable $ATOM-XML-MIME-TYPE := "application/atom+xml"; :)

declare variable $IDENTIFIER-INFO-NAMESPACE := "http://ns.overstory.co.uk/namespaces/resources/meta/id";
