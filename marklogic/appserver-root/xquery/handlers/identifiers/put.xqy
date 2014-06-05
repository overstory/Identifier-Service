xquery version "1.0-ml";

import module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier" at "lib/identifier.xqy";
import module namespace http="urn:overstory:modules:data-mesh:handlers:lib:http" at "lib/http.xqy";
import module namespace anno="urn:overstory:modules:data-mesh:handlers:lib:annotation" at "lib/annotation.xqy";

declare namespace i = "http://ns.overstory.co.uk/namespaces/resources/meta/id";
declare namespace e = "http://overstory.co.uk/ns/errors";
