xquery version "1.0-ml";

module namespace search="urn:overstory:modules:data-mesh:handlers:lib:search";

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "constants.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

import module namespace p="com.blakeley.xqysp" at "xqysp.xqy";

declare namespace i = "http://ns.overstory.co.uk/namespaces/resources/meta/id";


declare function build-search-query (
	$criteria as element(search-criteria)
) as cts:query
{
	terms-query ($criteria/terms/functx:trim(.))
};

declare private variable $search-options := ( "score-simple" );

declare function perform-search (
	$query as cts:query,
	$criteria as element(search-criteria)
) as element(search-results)
{
	let $ipp as xs:integer := xs:integer ($criteria/ipp)
	let $page as xs:integer := xs:integer ($criteria/page)
	let $first-item as xs:integer := xs:integer ($criteria/first-item)
	let $first as xs:integer := if ($first-item ne 0) then $first-item else ((($page - 1) * (xs:integer ($criteria/ipp))) + 1)
	let $last := ($first + $ipp) - 1
	let $hit-count := xdmp:estimate (cts:search (fn:collection ($const:ID-COLLECTION-NAME), $query, $search-options))
	let $results := cts:search (fn:collection ($const:ID-COLLECTION-NAME), $query, $search-options)[$first to $last]

	return
	<search-results>
		<selected-count>{ $hit-count }</selected-count>
		<returned-count>{ fn:count ($results) }</returned-count>
		<first-result>{ $first }</first-result>
		{ $criteria }
		{
			for $result at $idx in $results
			return <uri>{ $result/i:identifier-info/i:system/i:uri/text() }</uri>
		}
	</search-results>
};

(: ------------------------------------------------------------ :)

declare private function terms-query (
	$terms as xs:string
) as cts:query?
{
	let $parsed-query as cts:query? := parse ($terms)

	return
	if (fn:empty ($parsed-query))
	then cts:and-query (())   (: matches everything :)
	else cts:or-query (($parsed-query, term-value-queries ($terms)))
};

declare private function term-value-queries (
	$terms as xs:string
) as cts:query*
{
	cts:element-value-query (xs:QName ("i:uri"), $terms, "exact", 15)
};


declare private variable $word-query-options := ("case-insensitive", "diacritic-insensitive", "punctuation-insensitive");

declare private function expr (
	$op as xs:string,
	$list as cts:query*
) as cts:query?
{
	let $op := fn:upper-case ($op)

	return
	(: To implement a new operator, simply add it to this code :)
	if (fn:empty($list)) then ()
	(: simple boolean :)
	else if (fn:empty($op) or $op eq 'AND')
	then cts:and-query($list)
	else if ($op = ('NOT', '-'))
	then cts:not-query($list)
	else if ($op = ('OR','|'))
	then cts:or-query($list)
	(: near and variations :)
	else if ($op eq 'NEAR')
	then cts:near-query($list)
	else if (fn:starts-with($op, 'NEAR/'))
	then cts:near-query ($list, xs:double(fn:substring-after($op, 'NEAR/')))
	else if ($op eq 'ONEAR')
	then cts:near-query($list, (), 'ordered')
	else if (fn:starts-with($op, 'ONEAR/'))
	then cts:near-query ($list, xs:double(fn:substring-after($op, 'ONEAR/')), 'ordered')
	else fn:error((), 'UNEXPECTED')
};

declare private function field (
	$qnames as xs:QName+,
	$op as xs:string?,
	$list as element()*
) as cts:query?
{
  (: This function leaves many problems unresolved.
   : What if $list contains sub-expressions from nested groups?
   : What if $list contains non-string values for range queries?
   : What if a range-query needs a special collation?
   : Handle these corner-cases if you need them.
   :)
	if (fn:empty($list))
	then cts:element-query($qnames, cts:and-query(()))
	else if ($op = ('>', '>=', '<', '<='))
	then cts:element-range-query ($qnames, $op, $list)
	else if ($op eq '=')
	then cts:element-value-query($qnames, $list)
	else cts:element-word-query($qnames, $list)
};

declare function eval (
	$n as element()
) as cts:query?
{
	(: walk the AST, transforming AST XML into cts:query items :)
	typeswitch($n)
	case element(p:expression) return expr($n/@op, eval($n/*))
	(: NB - no eval, since we may need to handle literals in qe:field too :)
	(: This code works as long as your field names match the QNames.
	: If they do not, replace xs:QName with a lookup function.
	:)
	case element(p:field) return field (xs:QName($n/@name/fn:string()), $n/@op, $n/*)
	case element(p:group) return if (fn:count($n/*, 2) lt 2) then eval($n/*) else cts:and-query(eval($n/*))
	(: NB - interesting literals should be handled by the cases above :)
	case element(p:literal) return cts:word-query ($n, $word-query-options)
	case element(p:root) return ( if (fn:count($n/*, 2) lt 2) then eval($n/*) else cts:and-query(eval($n/*)))
	default return fn:error((), 'UNEXPECTED')
};

(: public entry point :)
declare function parse (
	$qs as xs:string?
) as cts:query?
{
	eval (p:parse ($qs))
};


