<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="exsl str">

 <xsl:output method="xml" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:include href="../rights-full.xsl"/>
 <xsl:include href="../lang-db.xsl"/>

 <xsl:template match="song">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <copyright>
       <xsl:call-template name="copyright"/>
     </copyright>
     <xsl:apply-templates select="node()|comment()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*|node()|comment()">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

</xsl:stylesheet>
