<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:str="http://exslt.org/strings"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="str exsl">

 <xsl:output method="text" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>
<!--
 <xsl:output method="xml" encoding="iso-8859-1"/>
 <xsl:variable name="nl"/>
-->

 <xsl:key name="uniq" match="/token/text()" use="."/>

 <xsl:template match="/">
   <xsl:variable name="all">
     <xsl:apply-templates select="/songs/song/akks"/>
     <xsl:apply-templates select="/songs-out/song/content"/>
   </xsl:variable>
   <root> <!-- will be stripped, when output method = text -->
     <xsl:for-each select="exsl:node-set($all)"> <!-- change context -->
       <xsl:apply-templates select="/token/text()[generate-id() = generate-id(key('uniq',.)[1])]" mode="_grabakk">
         <xsl:sort select="."/>
       </xsl:apply-templates>
     </xsl:for-each>
   </root>
 </xsl:template>

 <xsl:template match="akks">
   <xsl:apply-templates select=".//text()"/>
 </xsl:template>

 <xsl:template match="akks//text()">
   <xsl:copy-of select="str:tokenize(normalize-space(.))"/>
 </xsl:template>

 <xsl:template match="token/text()" mode="_grabakk">
   <v><xsl:value-of select="."/></v><xsl:value-of select="$nl"/>
 </xsl:template>

 <!-- sout ... -->
 <xsl:template match="content">
   <xsl:apply-templates select=".//akk"/>
 </xsl:template>

 <xsl:template match="akk">
   <xsl:if test="@note">
     <token>
       <xsl:value-of select="@note"/>
     </token>
   </xsl:if>
 </xsl:template>

</xsl:stylesheet>
