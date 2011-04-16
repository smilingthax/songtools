<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:set="http://exslt.org/sets"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                xmlns:mine="thax.home/mine-ext"
                extension-element-prefixes="exsl set func str mine">

 <xsl:output method="text" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>
 <xsl:variable name="tab"><xsl:text>	</xsl:text></xsl:variable>

 <xsl:strip-space elements="songs-out"/>

 <xsl:template match="/">
   <xsl:apply-templates select="songs-out/*"/>
 </xsl:template>

 <xsl:template match="song">
<!-- multi song/lang mode -->
   <xsl:apply-templates select="content"/>
<!-- one song/lang mode -->
<!--
   <xsl:text>\sng{</xsl:text><xsl:apply-templates select="title" mode="inhalt"/><xsl:text>}</xsl:text>
   <xsl:value-of select="$nl"/>
   <xsl:apply-templates select="content"/>
   <xsl:text>\esng{}</xsl:text>-->
 </xsl:template>

 <xsl:template match="blkp">
 <!--
   <xsl:text>****</xsl:text><xsl:value-of select="$nl"/>
   -->
 </xsl:template>

 <xsl:template match="song/title" mode="inhalt">
   <xsl:param name="lang"/>
   <xsl:value-of select="mine:get_no(ancestor::song/preceding-sibling::song|ancestor::song)"/>
   <xsl:value-of select="$tab"/>
   <xsl:value-of select="."/>
   <xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/content">
   <xsl:apply-templates select="../title[@lang=mine:main_lang(current()/@lang)]" mode="inhalt">
     <xsl:with-param name="lang" select="@lang"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="*"><!-- Error-catcher -->
   <xsl:text/>{<xsl:value-of select="text()"/>#<xsl:value-of select="name()"/>}<xsl:value-of select="$nl"/>
 </xsl:template>

 <func:function name="mine:get_no"> <!-- call with 'preceding-sibling::tag|.' -->
   <xsl:param name="prec"/>
   <xsl:variable name="pno" select="$prec[@no][1]"/>
   <xsl:variable name="add">
     <xsl:choose>
       <xsl:when test="$pno"><xsl:value-of select="$pno/@no"/></xsl:when>
       <xsl:otherwise>0</xsl:otherwise>
     </xsl:choose>
   </xsl:variable>
   <func:result select="count(set:trailing($prec,$pno))+$add"/>
 </func:function>

</xsl:stylesheet>
