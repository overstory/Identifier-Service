
xquery version "1.0-ml";

module namespace uuid="urn:overstory:modules:utility:uuid";

(:~
 :  Adapted from code written by Alex Bleasdale
 :
 : See also https://gist.github.com/ellispritchard/5466339
 :)

declare function generate-uuid-v4 (
) as xs:string
{
	string-join (
		(random-hex(8), random-hex(4), random-hex(4), random-hex(4), random-hex(12)),
		"-"
	)
};


declare private function random-hex (
  $length as xs:integer
) as xs:string
{
	string-join (
		for $n in 1 to $length
		return fn:upper-case (xdmp:integer-to-hex (xdmp:random(15))),
		""
	)
};

