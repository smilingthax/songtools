<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL/MIT, see COPYING
     This file may, by your choice, be licensed under LGPL or by the MIT license -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:thobi="thax.home/split"
                extension-element-prefixes="thobi func exsl" exclude-result-prefixes="thobi">

 <func:function name="thobi:septree">
   <xsl:param name="inNodes"/>
   <xsl:param name="seps"/>
   <xsl:variable name="ret">
     <xsl:apply-templates select="$inNodes" mode="_sep_tree">
       <xsl:with-param name="seps" select="$seps"/>
     </xsl:apply-templates>
   </xsl:variable>
   <func:result select="exsl:node-set($ret)"/>
 </func:function>

 <xsl:template mode="_sep_tree" match="*">
   <xsl:param name="seps"/>
   <xsl:copy>
     <xsl:apply-templates mode="_sep_tree" select="@*|node()">
       <xsl:with-param name="seps" select="$seps"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template mode="_sep_tree" match="@*|comment()">
   <xsl:copy/>
 </xsl:template>

 <xsl:template mode="_sep_tree" match="text()" name="_sep_tree">
   <xsl:param name="seps"/>
   <xsl:copy-of select="thobi:separate(.,$seps)"/>
 </xsl:template>

</xsl:stylesheet>
