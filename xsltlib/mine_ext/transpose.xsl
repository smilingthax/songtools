<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:mine="thax.home/mine-ext"
                xmlns:regexp="http://exslt.org/regexp"
                extension-element-prefixes="mine regexp">

  <xsl:output method="xml" encoding="iso-8859-1"/>

  <!-- Usage: xsltproc -stringparam transpose 1 transpose.xsl [sout.xml / songs.xml] -->

  <xsl:param name="transpose" select="0"/>

  <xsl:template match="/songs/song/akks">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="_akks"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()" mode="_akks">
    <xsl:apply-templates select="regexp:split(.,'(\s+)')" mode="_replace"/>
  </xsl:template>

  <xsl:template match="match" mode="_replace">
    <xsl:value-of select="text()"/>
  </xsl:template>

  <xsl:template match="text()" mode="_replace">
    <xsl:value-of select="mine:transpose(.,$transpose)"/>
  </xsl:template>

  <xsl:template match="/songs-out/song/content">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()" mode="_akk"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="akk" mode="_akk">
    <xsl:copy>
      <xsl:if test="@*[not(name()='note')]">
        <xsl:message>Unexpected &lt;akk> attribute</xsl:message>
        <xsl:copy-of select="@*"/> <!-- we'll overwrite @note in the next step -->
      </xsl:if>
      <xsl:if test="@note">
        <xsl:attribute name="note"><xsl:value-of select="mine:transpose(@note,$transpose)"/></xsl:attribute>
      </xsl:if>
      <xsl:copy-of select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*|node()|comment()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()|comment()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*|node()|comment()" mode="_akk">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()|comment()" mode="_akk"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*|node()|comment()" mode="_akks">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()|comment()" mode="_akks"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
