<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:output method="xml" encoding="iso-8859-1"/>

 <xsl:template match="song">
   <xsl:choose>
     <xsl:when test="title/@lang">
       <xsl:for-each select="title">
         <xsl:variable name="lng" select="@lang"/>
         <xsl:for-each select="parent::node()">
           <xsl:copy>
             <xsl:apply-templates select="title[@lang=$lng]"/>
             <xsl:apply-templates select="@*|comment()|node()[not(self::title or self::content)]"/>
             <xsl:apply-templates select="content[@lang=$lng]"/>
           </xsl:copy>
         </xsl:for-each>
       </xsl:for-each>
     </xsl:when>
     <xsl:otherwise>
       <xsl:copy>
         <xsl:apply-templates select="@*|node()|comment()"/>
       </xsl:copy>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="@*|node()|comment()">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

</xsl:stylesheet>
