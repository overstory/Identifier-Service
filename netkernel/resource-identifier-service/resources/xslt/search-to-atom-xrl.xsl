<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xrl="http://netkernel.org/xrl"
	xmlns:atom="http://www.w3.org/2005/Atom"
	xmlns:i="http://ns.overstory.co.uk/namespaces/resources/meta/id">

	<xsl:param name="url"/>

	<xsl:variable name="url-root" select="replace ($url, 'http://([-a-zA-Z0-9]+)(:[0-9]+)', '')"/>

	<xsl:template match="/search-results">
		<xsl:variable name="page" as="xs:integer" select="xs:integer(search-criteria/page)"/>

		<atom:feed>
			<atom:id>Search results</atom:id>

			<xsl:apply-templates select="." mode="link">
				<xsl:with-param name="rel" select="'self'"/>
				<xsl:with-param name="new-page" select="$page"/>
			</xsl:apply-templates>

			<xsl:apply-templates select="." mode="link">
				<xsl:with-param name="rel" select="'next'"/>
				<xsl:with-param name="new-page" select="$page + 1"/>
			</xsl:apply-templates>

			<xsl:apply-templates select="." mode="link">
				<xsl:with-param name="rel" select="'prev'"/>
				<xsl:with-param name="new-page" select="$page - 1"/>
			</xsl:apply-templates>

			<xsl:apply-templates/>
		</atom:feed>
	</xsl:template>

	<xsl:template match="uri">
		<atom:entry>

			<atom:id><xsl:value-of select="."/></atom:id>
			<atom:link rel="self" href="{concat ($url-root, '/id/', string(.))}" type="application/vnd.overstory.meta.id+xml"/>

			<atom:content type="application/vnd.overstory.meta.id+xml">
				<xrl:include>
					<xrl:identifier>active:idsvcNormalized/get-id</xrl:identifier>
					<xrl:argument name="id"><xsl:value-of select="."/></xrl:argument>
                    <xrl:argument name="content-type"><literal type="string">application/xml</literal></xrl:argument>
					<xrl:async>false</xrl:async>
				</xrl:include>
			</atom:content>
		</atom:entry>
	</xsl:template>

	<xsl:template match="selected-count">
		<i:total-hits><xsl:value-of select="."/></i:total-hits>
	</xsl:template>

	<xsl:template match="first-result">
		<i:first-item><xsl:value-of select="."/></i:first-item>
	</xsl:template>

	<xsl:template match="returned-count">
		<i:returned-count><xsl:value-of select="."/></i:returned-count>
	</xsl:template>

	<xsl:template match="search-criteria">
		<xsl:copy-of select="."/>
	</xsl:template>


	<xsl:template match="search-results" mode="link">
		<xsl:param name="rel" as="xs:string"/>
		<xsl:param name="new-page" as="xs:integer"/>

		<xsl:variable name="ipp" as="xs:integer?" select="xs:integer(search-criteria/ipp)"/>
		<xsl:variable name="hits" as="xs:integer" select="xs:integer(selected-count)"/>
		<xsl:variable name="pages" as="xs:integer" select="xs:integer(ceiling($hits div $ipp))"/>
		<xsl:variable name="new-url" as="xs:string">
			<xsl:apply-templates select="." mode="base-url">
				<xsl:with-param name="page" select="$new-page"/>
			</xsl:apply-templates>
		</xsl:variable>

		<xsl:if test="($new-page &gt; 0) and ($new-page &lt;= $pages)">
			<atom:link rel="{$rel}" href="{$new-url}" type="application/atom+xml"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="search-results" mode="base-url">
		<xsl:param name="page" as="xs:integer"/>

		<xsl:variable name="page-param" as="xs:string" select="concat ('page=', $page)"/>
		<xsl:variable name="ipp-param" as="xs:string" select="concat ('ipp=', search-criteria/ipp)"/>
		<xsl:variable name="terms-param" as="xs:string?">
			<xsl:if test="search-criteria/terms ne ''"><xsl:value-of select="concat ('terms=', search-criteria/terms)"/></xsl:if>
		</xsl:variable>
		<xsl:variable name="query-string" select="string-join (($page-param, $ipp-param, $terms-param), '&amp;')"/>

		<xsl:value-of select="concat ($url-root, '?', $query-string)"/>
	</xsl:template>


</xsl:stylesheet>
