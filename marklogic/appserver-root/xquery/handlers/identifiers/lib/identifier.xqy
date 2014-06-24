xquery version "1.0-ml";

module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier";

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "constants.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "/MarkLogic/appservices/utils/in-mem-update.xqy";

declare namespace e = "http://overstory.co.uk/ns/errors";
declare namespace i = "http://ns.overstory.co.uk/namespaces/resources/meta/id";
declare namespace m = "http://ns.overstory.co.uk/namespaces/resources/meta/content";

declare namespace s ="http://www.w3.org/2005/xpath-functions";

declare variable $MAX-RETRIES := 20;

declare variable $uri-prefix as xs:string := "urn:overstory.co.uk:id:";
declare variable $identifier-directory-prefix := "/identifier/";

declare variable $default-content-type as xs:string := "application/xml";

declare variable $collection-identifier as xs:string := $const:ID-COLLECTION-NAME;

declare variable $urn-invalid-regex := '([^\-.:_\da-zA-Z])';

(: ------------------------------------------------------ :)

(:
	Allocates a unique URI for the template, creates a new i:identifier-info and stores it in the DB
	Returns the new i:identifier-info on success, empty sequence if it couldn't be created.
	ToDo: Need a reliable locking strategy to insure IDs are created and checked atomically
:)
declare function new-identifier (
	$template as xs:string,
	$annotation as element(i:annotation)?
) as element(i:identifier-info)?
{
	let $new-uri := generate-unique-id ($template, 0, $MAX-RETRIES)
	return
	if (fn:exists ($new-uri))
	then store-new-identifier ($new-uri, $annotation)
	else ()
};

(:
	Generates a unique URI, recursing up to $max times if the generated URI is already allocated
	Return a string on success, empty sequence on failure.
:)
declare function generate-unique-id (
	$template as xs:string,
	$level as xs:int,
	$max as xs:int
) as xs:string?
{
	if ($level ge $max)
	then ()
	else
		let $uri := identifier-from-template ($template, $level)
		return
		if (identifier-exists ($uri))
		then generate-unique-id ($template, $level + 1, $max)
		else $uri
};

(: ------------------------------------------------------ :)

declare function validate-annotation (
	$post-body as element(i:annotation)?
) as element(i:annotation)?
{
	$post-body

(:
	if (fn:empty ($post-body))
	then ()
	else $post-body/i:annotation	 :)
(: Will cause exception if body is not an i:annotation element because of function's declared return type :)(:

 :)
};

(: ------------------------------------------------------ :)

declare function clear-annotation (
	$old-id-info as element(i:identifier-info)
) as element(i:identifier-info)
{
	if (fn:exists ($old-id-info/i:annotation))
	then
		let $history-event := <i:delete-annotation when="{ current-dateTime-as-utc() }"/>
		let $doc := mem:node-delete ($old-id-info/i:annotation)/i:identifier-info
		let $doc := mem:node-replace ($doc/i:system/i:etag, <i:etag>"{ generate-etag() }"</i:etag>)/i:identifier-info
		let $doc := append-history ($doc, $history-event)
		return store-identifier-doc ($doc)
	else
		$old-id-info
};

(: ------------------------------------------------------ :)

declare function replace-annotation (
	$old-id-info as element(i:identifier-info),
	$new-annotation as element(i:annotation)
) as element(i:identifier-info)
{
	if (fn:exists ($old-id-info/i:annotation))
	then
	let $_ := xdmp:log ("exists")
		let $doc := mem:node-replace ($old-id-info/i:annotation, $new-annotation)/i:identifier-info
		let $doc := update-etag ($doc)
		let $doc := append-history ($doc, <i:replace-annotation when="{ current-dateTime-as-utc() }"/>)
		return store-identifier-doc ($doc)
	else
	let $_ := xdmp:log ("doesn't exist")
		let $doc := mem:node-insert-child ($old-id-info, $new-annotation)/i:identifier-info
		let $doc := update-etag ($doc)
		let $doc := append-history ($doc, <i:add-annotation when="{ current-dateTime-as-utc() }"/>)
		return store-identifier-doc ($doc)
};

(: ------------------------------------------------------ :)

declare function update-etag (
	$doc as element(i:identifier-info)
) as element(i:identifier-info)
{
	mem:node-replace ($doc/i:system/i:etag, <i:etag>"{ generate-etag() }"</i:etag>)/i:identifier-info
};

declare function append-history (
	$doc as element(i:identifier-info),
	$history-event as element()
) as element(i:identifier-info)
{
	let $updated := <i:updated>{ current-dateTime-as-utc() }</i:updated>
	let $doc :=
		if (fn:exists ($doc/i:system/i:updated))
		then mem:node-replace ($doc/i:system/i:updated, $updated)/i:identifier-info
		else mem:node-insert-after ($doc/i:system/i:created, $updated)/i:identifier-info
	let $doc :=
		if (fn:exists ($doc/i:system/i:history))
		then mem:node-insert-child ($doc/i:system/i:history, $history-event)/i:identifier-info
		else mem:node-insert-child ($doc/i:system, <i:history>{ $history-event }</i:history>)/i:identifier-info
	return $doc
};

(: ------------------------------------------------------ :)

declare private function store-new-identifier (
	$uri as xs:string,
	$annotation as element(i:annotation)?
) as element(i:identifier-info)
{
	store-identifier-doc (new-identifier-info ($uri, $annotation))
};

declare private function new-identifier-info (
	$uri as xs:string,
	$annotation as element(i:annotation)?
) as element(i:identifier-info)
{
	<i:identifier-info>
		<i:system>
			<i:uri>{ $uri }</i:uri>
			<i:etag>"{ generate-etag() }"</i:etag>
			<i:created>{ current-dateTime-as-utc() }</i:created>
		</i:system>
		{ $annotation }
	</i:identifier-info>
};

(: ------------------------------------------------------ :)

(: Identifier functionality specific :)

(: default uri when /identifier is called without any parameters :)
declare function generate-default-uri (
) as xs:string
{
	fn:concat ($uri-prefix, "resource:", generate-uuid-v4())
};

(: check if identifier-uri exists :)
declare function identifier-exists (
	$identifier as xs:string
) as xs:boolean
{
	(: ToDo: check existence of the id inside an identifier-info doc (in proper collection), don't use doc URI as proof of existence existence :)
	fn:exists (fn:doc (full-identifier-ml-uri ($identifier) ))
};

(: add directory path to identifier-uri :)
declare function full-identifier-ml-uri (
	$identifier as xs:string
) as xs:string
{
	fn:concat ($identifier-directory-prefix, $identifier, ".xml")
};


(: insert identifier document :)
declare function store-identifier-doc (
	$doc as element(i:identifier-info)
) as element(i:identifier-info)
{
	(
		xdmp:document-insert (full-identifier-ml-uri ($doc/i:system/i:uri),
			$doc, xdmp:default-permissions(), collections-for-new-identifier()),
		$doc
	)
};

(: return collections for identifier :)
declare function collections-for-new-identifier (
) as xs:string*
{
	($collection-identifier)
};

(: get identifier document :)
declare function get-identifier-info (
    $identifier as xs:string
) as element(i:identifier-info)?
{
	(: ToDo: Look up by internal ID, not algorithmically created doc URL :)
	fn:doc (full-identifier-ml-uri ($identifier))/i:identifier-info
};


(: ToDo: Move this template stuff to template.xqy, make inside functions private :)

(: identifier template work :)

declare function identifier-from-template (
    $template as xs:string,
    $level as xs:int
) as xs:string
{
    let $analyze := fn:analyze-string ($template, '\{.*?\}')
    return process-analyze-string-result ($analyze, $level)
};

declare function process-analyze-string-result (
    $result as element (s:analyze-string-result),
    $level as xs:int
) as xs:string
{
	let $result-sequence :=
		for $child in $result/child::*
		return (
			typeswitch ($child)
			case element(s:non-match) return
				if (fn:matches ($child/fn:string(), $urn-invalid-regex))
				then fn:error (xs:QName ("lib:bad-template-char"), "Invalid char sequence detected in template: " || fn:string ($child))
				else fn:string ($child)
			case element(s:match) return
				process-match ($child, $level)
			default return
				fn:error (xs:QName ("lib:analyze-fail"), "Unexpected child from analyse string: " || xdmp:describe ($child))
		)

	return full-identifier-uri (fn:string-join ($result-sequence, ''))

};

declare function full-identifier-uri (
    $uri-suffix as xs:string
)
{
    fn:concat ( $uri-prefix, $uri-suffix )
};


declare function process-match (
    $match as element (s:match),
    $level as xs:int
) as xs:string
{
    process-match-string (discard-match-brackets ($match), $level)
};

declare function discard-match-brackets (
    $match as element(s:match)
) as xs:string
{
    fn:substring-before (fn:substring-after ($match,'{'),'}')
};

declare function process-match-string (
    $match as xs:string,
    $level as xs:int
)
{
    if (fn:starts-with ($match, 'guid'))
    then process-guid-template ($match)
    else if ($match = 'now')
    then process-now-template ($level)  (: FixMe, need to append level and type as a string :)
    else if (fn:starts-with ($match, 'time'))
    then process-time-template ($match, $level)
    else if (fn:starts-with ($match, 'doi'))
    then process-doi-template ($match, $level)
    else if (fn:starts-with ($match, 'id:'))
    then process-id-template ($match)
    else if (fn:starts-with($match, 'file:'))
    then process-file-template ($match)
    else if (fn:starts-with ($match, 'min'))
    then process-min-template ($match, $level)
    else 'UNRECOGNIZED-TEMPLATE-NAME'
};



declare function process-guid-template (
	$match as xs:string
) as xs:string
{
	let $guid := generate-uuid-v4()
	let $length := numeric-arg ($match)
	return if ($length = 0) then $guid else fn:substring ($guid, 1, $length)
};

declare function process-doi-template (
	$match as xs:string,
	$level as xs:int
) as xs:string?
{
	let $doi := string-arg ($match)
	let $scrubbed := if (fn:exists ($doi)) then fn:replace ($doi, $urn-invalid-regex, '_') else ()
	return
	if (fn:exists ($scrubbed))
	then append-level-number-gt-zero ($scrubbed, $level)
	else fn:error (xs:QName ("lib:missing-doi"), "No valid DOI found as argument to {doi: <doi>}")
};

declare function process-id-template (
	$match as xs:string
)
{
	fn:replace(fn:substring-after (fn:replace($match, ' ', ''), 'id:'), '/', '_')
};

declare function process-time-template (
	$match as xs:string,
	$level as xs:int
) as xs:string
{
	let $time := fn:substring-after (fn:replace($match, ' ', ''), 'time:')
	let $suffix := if ($level = 0) then "" else fn:concat ("-", $level)
	return fn:concat ($time, $suffix)
};

declare function process-now-template (
	$level as xs:int
) as xs:string
{
	let $time := fn:string (current-dateTime-as-utc())
	let $suffix := if ($level = 0) then "" else fn:concat ("-", $level)
	return fn:concat ($time, $suffix)
};

declare function process-file-template (
	$match as xs:string
)
{
	if (fn:contains($match, '/'))
	then (functx:substring-after-last($match, '/'))
	else (functx:substring-after-last($match, '\'))
};

declare function process-min-template (
	$match as xs:string,
	$level as xs:int
) as xs:string
{
	let $length := numeric-arg ($match)
	let $empty := ($length = 0) and ($level = 0)
	let $length := fn:max ((1, $length))
	return if ($empty) then "" else fn:string (functx:pad-integer-to-length ($level, $length))
};

(: ------------------------------------------------------ :)

declare function numeric-arg (
	$template as xs:string
) as xs:int
{
	let $default-length := 0
	let $tokens := fn:tokenize ($template, " *: *")
	return if ((fn:count ($tokens) = 1) or fn:not ($tokens[2] castable as xs:int)) then $default-length else xs:int($tokens[2])
};

declare function string-arg (
	$template as xs:string
) as xs:string?
{
	let $arg := fn:substring-after ($template, ":")
	return if (fn:exists ($arg)) then functx:trim ($arg) else ()
};

declare function append-level-number-gt-zero (
	$string as xs:string,
	$level as xs:int
) as xs:string
{
	if ($level = 0) then $string else $string || "-" || $level
};

(: ------------------------------------------------------ :)

(: uuid/etag generators :)

(: Alternative to sem:uuid-string() if sem: is not available for ML license :)
declare function generate-uuid-v4 (
) as xs:string
{
	let $x := fn:concat (xdmp:integer-to-hex(xdmp:random()), xdmp:integer-to-hex(xdmp:random()))
	return
	string-join
	(
		(
		fn:substring ($x, 1, 8), fn:substring ($x, 9, 4),
		fn:substring ($x, 13, 4), fn:substring ($x, 17, 4), fn:substring ($x, 21, 14)
		),
		'-'
	)
};

(: Generate Etag :)
declare function generate-etag (
) as xs:string
{
	let $x := fn:concat (xdmp:integer-to-hex(xdmp:random()), xdmp:integer-to-hex(xdmp:random()))
	return fn:substring ($x, 1, 18)
};

(: ------------------------------------------------------ :)

declare function current-time (
) as xs:string
{
	fn:substring-before(fn:string(fn:current-dateTime()), '+')
};

declare function dateTime-as-utc (
	$time as xs:dateTime
) as xs:dateTime
{
	fn:adjust-dateTime-to-timezone ($time, xs:dayTimeDuration("PT0H"))
};

declare function current-dateTime-as-utc (
) as xs:dateTime
{
	fn:adjust-dateTime-to-timezone (fn:current-dateTime(), xs:dayTimeDuration("PT0H"))
};

(: ------------------------------------------------------ :)
(: ------------------------------------------------------ :)
(: ------------------------------------------------------ :)

(: Cruft, soon to be deleted :)

(: generate identifier's system information :)
declare function identifier-system-info (
	$etag as xs:string
) as element(i:system)
{
	<i:system xmlns:i="http://ns.overstory.co.uk/namespaces/meta/id">
		<i:created>{current-dateTime-as-utc()}</i:created>
		<i:etag>{$etag}</i:etag>
	</i:system>
};

(: identifier xml :)
declare function identifier-info (
	$id-system-info (:as element(i:system)?:),
	$annotations (:as element(i:annotation)?:)
) as element(i:identifier-info)
{
	<i:identifier-info xmlns:i="http://ns.overstory.co.uk/namespaces/meta/id">{
		$id-system-info,
		$annotations
	}</i:identifier-info>
};

(: check incoming identifier annotation xml :)
declare function check-identifier-annotation(
	$annotation as element()
) as xs:boolean
{
	fn:name($annotation) = 'i:annotation'
};

(: get identifier's etag from system info :)
declare function etag-for-identifier (
	$doc as element()
) as xs:string
{
	$doc/i:system/i:etag/string()
};


(: ------------------------------------------------------ :)

