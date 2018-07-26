<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:output method="xml" encoding="iso-8859-1"/>

 <xsl:template match="@*|node()|comment()">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="refr[@repeated]|bridge[@repeated]|vers[@repeated]"/>

 <!-- @break="-3" can get lost -->
 <xsl:template match="content/*[not(@repeated) and not(following-sibling::*[not(@repeated)])][position()=last()]/br[last()]">
   <br no="1" break="-3"/>
 </xsl:template>

</xsl:stylesheet>
