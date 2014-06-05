xquery version "1.0-ml";

module namespace anno="urn:overstory:modules:data-mesh:handlers:lib:annotation";

import module namespace re="urn:overstory:rest:modules:rest:errors" at "../../../rest/lib-rest/errors.xqy";

declare namespace i = "http://ns.overstory.co.uk/namespaces/meta/id";
declare namespace e = "http://overstory.co.uk/ns/errors";


declare function validate-annotation (
	$annotation as item()*
) as element(i:annotation)?
{
	if (fn:empty ($annotation))
	then ()
	else
		if ($annotation instance of element(i:annotation))
		then $annotation	(: ToDo: Perform schema validation on $annotation :)
		else re:throw-xml-error ('ANNO-INVALID-ANNOTATION-ELEMENT', 400, "Request body root is not <i:annotation>",
				<e:invalid-annotation>
                        		<e:message>Request body root is not &lt;i:annotation&gt;</e:message>
                        	</e:invalid-annotation>)
};
