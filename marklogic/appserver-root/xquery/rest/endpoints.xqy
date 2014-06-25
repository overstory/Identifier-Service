xquery version "1.0-ml";

module namespace endpoints="urn:overstory:rest:modules:endpoints";

import module namespace rce="urn:overstory:rest:modules:common:endpoints" at "lib-rest/common-endpoints.xqy";

declare namespace rest="http://marklogic.com/appservices/rest";

(: ---------------------------------------------------------------------- :)

declare private variable $endpoints as element(rest:options) :=
	<options xmlns="http://marklogic.com/appservices/rest">
		<!-- root -->
		<request uri="^(/?)$" endpoint="/xquery/default.xqy"/>

		<!-- Generate a new resource identifier -->
		<request uri="^/identifier(/?)$" endpoint="/xquery/handlers/identifiers/post.xqy" user-params="allow">
			<http method="POST"/>
			<uri-param name="id-uri-root">/identifier/id/</uri-param>
		</request>

		<!-- ToDo: GET on /identifier with search params to search identifier annotations -->

		<!-- Generate information about a resource identifier -->
		<request uri="^/identifier/id/(.+)$" endpoint="/xquery/handlers/identifiers/get.xqy" user-params="deny">
			<uri-param name="id">$1</uri-param>
			<http method="GET"/>
		</request>

		<!-- Generate information about a resource identifier -->
		<request uri="^/identifier(/)?$" endpoint="/xquery/handlers/identifiers/search.xqy" user-params="allow">
			<http method="GET"/>
		</request>

		<!-- Update information about a resource identifier -->
		<request uri="^/identifier/id/(.+)$" endpoint="/xquery/handlers/identifiers/put.xqy" user-params="deny">
			<uri-param name="id">$1</uri-param>
			<http method="PUT"/>
		</request>

		<!-- Remove information about a resource identifier -->
		<request uri="^/identifier/id/(.+)$" endpoint="/xquery/handlers/identifiers/delete.xqy" user-params="deny">
			<uri-param name="id">$1</uri-param>
			<http method="DELETE"/>
		</request>

		<!-- ================================================================= -->

		{ $rce:DEFAULT-ENDPOINTS }
	</options>;

(: ---------------------------------------------------------------------- :)

declare function endpoints:options (
) as element(rest:options)
{
	$endpoints
};
