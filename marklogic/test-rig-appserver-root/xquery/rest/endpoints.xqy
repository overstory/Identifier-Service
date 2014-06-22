xquery version "1.0-ml";

module namespace endpoints="urn:overstory:rest:modules:endpoints";

import module namespace rce="urn:overstory:rest:modules:common:endpoints" at "lib-rest/common-endpoints.xqy";

declare namespace rest="http://marklogic.com/appservices/rest";

(: ---------------------------------------------------------------------- :)

declare private variable $endpoints as element(rest:options) :=
	<options xmlns="http://marklogic.com/appservices/rest">
		<!-- Endpoint mappings for test rig admin function.  DANGER: Stuff here is destrcutive -->

		<!-- Wipe the database (actualy delete everything in the identifier collection -->
		<request uri="^/actions/clear-db$" endpoint="/xquery/handlers/clear-db.xqy" user-params="forbid">
			<http method="DELETE"/>
		</request>

		<!-- Return the size of the identifier collection -->
		<request uri="^/actions/identifier-count$" endpoint="/xquery/handlers/identifier-count.xqy" user-params="forbid">
			<http method="GET"/>
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
