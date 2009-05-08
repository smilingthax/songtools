<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:output method="xml" encoding="iso-8859-1"/>

 <xsl:template match="@*|node()|comment()">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="akk">
   <xsl:if test="not(text()='_' or text()='-')"> 
     <xsl:value-of select="text()"/>
   </xsl:if>
   <xsl:if test="not(text())">
     <xsl:text> </xsl:text>
   </xsl:if>
 </xsl:template>

</xsl:stylesheet>
