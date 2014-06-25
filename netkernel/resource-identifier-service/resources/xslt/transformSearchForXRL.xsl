<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xrl="http://netkernel.org/xrl"
	xmlns:atom="http://www.w3.org/2005/Atom"
	xmlns:i="http://ns.overstory.co.uk/namespaces/resources/meta/id">

	<xsl:template match="/search-results">
		<atom:feed>
			<atom:id>Search results</atom:id>
			<!-- ToDo: Links, etc here -->
			<xsl:apply-templates/>
		</atom:feed>
	</xsl:template>

	<xsl:template match="uri">
		<atom:entry>
			<atom:id><xsl:value-of select="."/></atom:id>
			<!-- ToDo: Links, etc here -->
			<atom:content type="application/vnd.overstory.meta.id+xml">
				<xrl:include>
					<xrl:identifier>active:idsvc/get-id</xrl:identifier>
					<xrl:argument name="id"><xsl:value-of select="."/></xrl:argument>
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

</xsl:stylesheet>
