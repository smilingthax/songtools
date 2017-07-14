<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:akk="thax.home/akk"
                extension-element-prefixes="akk">

 <xsl:output method="xml" encoding="iso-8859-1"/>

 <!-- types:
   '': fill with ' ' and sync chord; @note optional
   ' ': fill (before) with ' ' (or @fill), sync, *and after chord* fill with ' ' (independent of @fill (?));  @note should be present
   '-': fill with '-' and sync; @note optional

   '^': no fill, no sync; @note expected (and vow is present, ...)
   '=': no sync, fill *after* with '-' (if desired); @note expected (and vow is present, ...)
   '_': no sync, fill *after* with '_'; @note expected (and vow is present, ...)
 -->

 <xsl:template match="/songs-out/song/content">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="akk:akker(node())"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*|node()|comment()">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

</xsl:stylesheet>
