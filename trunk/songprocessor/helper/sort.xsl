<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:output method="xml" encoding="iso-8859-1"/>

 <xsl:template match="/songs">
   <xsl:copy>
     <xsl:apply-templates select="song">
       <xsl:sort select="title" lang="de"/>
<!--       <xsl:sort select="sortkey(title)" lang="de"/>  TODO -->
     </xsl:apply-templates><xsl:text>
</xsl:text>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="song">
   <xsl:text>
</xsl:text>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*|node()|comment()">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

</xsl:stylesheet>
