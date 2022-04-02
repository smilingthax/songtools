<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                xmlns:json="thax.home/json"
                xmlns:j="http://www.w3.org/2005/xpath-functions"
                extension-element-prefixes="exsl json">

  <xsl:variable name="indent-step" select="'  '"/>

  <xsl:template name="json:xml-to-json">
    <xsl:param name="in" select="."/>
    <xsl:param name="indent" select="0"/>
    <xsl:variable name="indent_hlp">
      <xsl:if test="$indent &gt; 0"><xsl:text>&#10;</xsl:text></xsl:if>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($in)" mode="_do_xml-to-json">
      <xsl:with-param name="indent" select="$indent_hlp"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="j:map" mode="_do_xml-to-json">
    <xsl:param name="indent"/>
    <xsl:choose>
      <xsl:when test="$indent != ''">
        <xsl:variable name="subindent" select="concat($indent, $indent-step)"/>
        <xsl:text>{</xsl:text>
        <xsl:for-each select="*">
          <xsl:if test="position() &gt; 1">
            <xsl:text>,</xsl:text>
          </xsl:if>
          <xsl:value-of select="$subindent"/>
          <xsl:value-of select="concat('&quot;', json:escape(@key), '&quot;')"/>
          <xsl:text>: </xsl:text>
          <xsl:apply-templates select="." mode="_do_xml-to-json">
            <xsl:with-param name="indent" select="$subindent"/>
          </xsl:apply-templates>
        </xsl:for-each>
        <xsl:value-of select="$indent"/>
        <xsl:text>}</xsl:text>
      </xsl:when>

      <xsl:otherwise>
        <xsl:text>{</xsl:text>
        <xsl:for-each select="*">
          <xsl:if test="position() &gt; 1">
            <xsl:text>,</xsl:text>
          </xsl:if>
          <xsl:value-of select="concat('&quot;', json:escape(@key), '&quot;')"/>
          <xsl:text>:</xsl:text>
          <xsl:apply-templates select="." mode="_do_xml-to-json"/>
        </xsl:for-each>
        <xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="j:array" mode="_do_xml-to-json">
    <xsl:param name="indent"/>
    <xsl:choose>
      <xsl:when test="$indent != ''">
        <xsl:variable name="subindent" select="concat($indent, $indent-step)"/>
        <xsl:text>[</xsl:text>
        <xsl:for-each select="*">
          <xsl:if test="position() &gt; 1">
            <xsl:text>,</xsl:text>
          </xsl:if>
          <xsl:value-of select="$subindent"/>
          <xsl:apply-templates select="." mode="_do_xml-to-json">
            <xsl:with-param name="indent" select="$subindent"/>
          </xsl:apply-templates>
        </xsl:for-each>
        <xsl:value-of select="$indent"/>
        <xsl:text>]</xsl:text>
      </xsl:when>

      <xsl:otherwise>
        <xsl:text>[</xsl:text>
        <xsl:for-each select="*">
          <xsl:if test="position() &gt; 1">
            <xsl:text>,</xsl:text>
          </xsl:if>
          <xsl:apply-templates select="." mode="_do_xml-to-json"/>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="j:string" mode="_do_xml-to-json">
    <xsl:value-of select="concat('&quot;', json:escape(.), '&quot;')"/>
  </xsl:template>

  <xsl:template match="j:number" mode="_do_xml-to-json">
    <xsl:value-of select="string(number(.))"/>
  </xsl:template>

  <xsl:template match="j:boolean" mode="_do_xml-to-json">
    <xsl:value-of select="string(boolean(.))"/>
  </xsl:template>

  <xsl:template match="j:null" mode="_do_xml-to-json">
    <xsl:text>null</xsl:text>
  </xsl:template>

  <xsl:template match="*" mode="_do_xml-to-json">
    <xsl:message terminate="yes">Unexpected element &lt;<xsl:value-of select="name()"/>&gt; for json:xml-to-json</xsl:message>
  </xsl:template>

</xsl:stylesheet>
