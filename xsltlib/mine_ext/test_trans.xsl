<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:makk="thax.home/mine-akk"
                extension-element-prefixes="makk">

  <xsl:output method="text" encoding="utf-8"/>
  <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

  <!-- Usage:  xsltproc -stringparam transpose 3 test_trans.xsl c1.xml

  (c1.xml from collect_chords.xsl [set to xml output])
  -->

  <xsl:param name="transpose" select="0"/>

  <xsl:template match="/">
    <xsl:apply-templates select="/root/v/text()"/>
  </xsl:template>

  <xsl:template match="text()">
<!--
    <xsl:value-of select="makk:noteAkks($transpose)"/>
    <xsl:value-of select="makk:grabAkk(0,0,.)"/>
    <xsl:value-of select="."/> . <xsl:value-of select="makk:getAkk(0,0)"/><xsl:value-of select="$nl"/>
-->
    <xsl:value-of select="."/> . <xsl:value-of select="makk:transpose(.,$transpose)"/><xsl:value-of select="$nl"/>
  </xsl:template>

</xsl:stylesheet>
