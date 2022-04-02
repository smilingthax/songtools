<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:json="thax.home/json"
                xmlns:j="http://www.w3.org/2005/xpath-functions"
                extension-element-prefixes="json">

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:include href="xml-to-json.xsl"/>

  <xsl:template match="/">
    <xsl:variable name="xml">
      <array xmlns="http://www.w3.org/2005/xpath-functions">
        <null/>
        <string>asdf</string>
        <number>1e4</number>
        <boolean>1</boolean>
        <map>
          <number key="a">1e4</number>
          <boolean key="b">1</boolean>
        </map>
      </array>
    </xsl:variable>

    <xsl:call-template name="json:xml-to-json">
      <xsl:with-param name="in" select="$xml"/>
      <xsl:with-param name="indent" select="1"/>
<!--
      <xsl:with-param name="in"><j:array><j:null/><j:boolean>1</j:boolean></j:array></xsl:with-param>
      <xsl:with-param name="indent" select="0"/>
-->
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
