<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:regexp="http://exslt.org/regexp"
                extension-element-prefixes="regexp">

 <xsl:output method="xml" encoding="utf-8"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

  <xsl:template match="/">
    <root>
      <xsl:value-of select="regexp:test('ab','A','')"/> <xsl:value-of select="$nl"/>

      <xsl:copy-of select="regexp:match('ab ac d','a(.)[^c]*','')"/> <xsl:value-of select="$nl"/>
      <xsl:copy-of select="regexp:match('ab ac d',' .','g')"/> <xsl:value-of select="$nl"/>
      <xsl:copy-of select="regexp:match('ab ac d','(.......)(.)?','')"/> <xsl:value-of select="$nl"/>

      <xsl:copy-of select="regexp:split('ab ac d','([^a]) *')"/> <xsl:value-of select="$nl"/>
    </root>
  </xsl:template>

</xsl:stylesheet>
