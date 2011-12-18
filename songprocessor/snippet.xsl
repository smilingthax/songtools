<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                xmlns:mine="thax.home/mine-ext-speed"
                xmlns:ec="thax.home/enclose"
                extension-element-prefixes="func mine ec exsl str">

 <xsl:import href="s-liner.xsl"/>

 <xsl:output method="text" encoding="iso-8859-1"/> <!-- TODO: utf-8 -->
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:strip-space elements="songs-out"/>

 <xsl:template match="/">
   <xsl:apply-templates select="songs-out/*"/>
 </xsl:template>

 <xsl:template match="song">
<!-- one song/lang mode -->
   <xsl:apply-templates select="title"/>
   <xsl:text>-----</xsl:text><xsl:value-of select="$nl"/>
   <xsl:apply-templates select="content"/>
   <xsl:text>$e</xsl:text><xsl:value-of select="@repos"/><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="blkp"/>

 <xsl:template match="img">
<!-- TODO? later?
   <xsl:text>$t*</xsl:text><xsl:value-of select="@href"/><xsl:value-of select="$nl"/>
   <xsl:text>*Img:</xsl:text><xsl:value-of select="@href"/><xsl:value-of select ="$nl"/>
   <xsl:text>$e</xsl:text><xsl:value-of select="@repos"/><xsl:value-of select="$nl"/>
-->
 </xsl:template>

 <xsl:template match="song/title">
   <xsl:param name="lang"/>
   <xsl:text>$t</xsl:text>
   <xsl:value-of select="."/>
   <xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/content">
<!-- one song/lang mode -->
   <xsl:call-template name="songcontent"/>
 </xsl:template>

 <xsl:template name="songcontent">
   <xsl:variable name="config">
     <base/>
     <vers>
<!--       <first><xsl:text>$b</xsl:text></first>  TODO: !? later -->
     </vers>
     <refr/>
     <bridge/>
     <ending/>
     <quotes start="&quot;" end="&quot;"/>
     <tick><xsl:text>'</xsl:text></tick>
     <rep>
       <start/>
       <simpleend/>
       <end/>
     </rep>
   </xsl:variable>
   <xsl:variable name="inNodes">
     <xsl:apply-templates select="*" mode="_songcontent">
       <xsl:with-param name="ctxt" select="exsl:node-set($config)|."/>
     </xsl:apply-templates>
   </xsl:variable>
   <xsl:apply-templates select="exsl:node-set($inNodes)/*" mode="_sc_post">
     <xsl:with-param name="ctxt" select="exsl:node-set($config)|."/>
   </xsl:apply-templates>
 </xsl:template>

 <!-- {{{ songcontent postprocessing: _sc_post -->
 <xsl:template match="line" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:param name="solrep" select="@solrep|exsl:node-set(0)[not(current()/@solrep)]"/> <!-- @solrep not always present; TRICK: variable not allowed here... -->
   <xsl:param name="repindent" select="sum(preceding-sibling::*/@rep) + $solrep"/>
   <xsl:if test="@xlang">
     <xsl:text>~</xsl:text>
   </xsl:if>
   <xsl:apply-templates select="node()" mode="_sc_post">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
   <xsl:if test="@xlang">
     <xsl:text>~</xsl:text>
   </xsl:if>
   <xsl:value-of select="$nl"/>
<!--
     no empty lines; TODO?
   <xsl:if test="@no">
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$nl"/>
       <xsl:with-param name="anz" select="@no"/>
     </xsl:call-template>
   </xsl:if>
-->
 </xsl:template>

 <xsl:template match="line/text()" mode="_sc_post">
   <xsl:value-of select="translate(normalize-space(.),'&#160;',' ')"/>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ Error-catcher -->
 <xsl:template match="*" name="error_trap">
   <xsl:text>{</xsl:text>
   <xsl:value-of select="text()"/>
   <xsl:text>#</xsl:text>
   <xsl:value-of select="name()"/>
   <xsl:text>}</xsl:text>
   <xsl:value-of select="$nl"/>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ block tags -->
 <xsl:template match="img" mode="_songcontent">
   <line no="1"><xsl:text>*Img:</xsl:text><xsl:value-of select="@href"/></line><xsl:value-of select ="$nl"/>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ inline tags -->
 <!-- TODO... -->
 <xsl:template match="cnr" mode="_songcontent_inlinex">
   <xsl:param name="ctxt"/>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
 </xsl:template>
 <xsl:template match="next" mode="_songcontent_inline">
   <xsl:text> &amp; </xsl:text>
 </xsl:template>

 <!-- just speedup -->
 <xsl:template match="rep" mode="_songcontent_inline">
   <xsl:param name="ctxt"/>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="spacer" mode="_songcontent_inline"/>
 
 <xsl:template match="hfill" mode="_songcontent_inline"/>
 <!-- }}} -->

 <!-- Helper functions -->
 <!-- {{{ TEMPLATE rep_it (inNodes, anz)  - repeates >inNodes >anz times -->
 <xsl:template name="rep_it"><!-- speedup -->
   <xsl:param name="inNodes"/>
   <xsl:param name="anz"/>
   <xsl:choose>
     <xsl:when test="function-available('mine:rep_it')">
       <xsl:copy-of select="mine:rep_it($inNodes,$anz)"/>
     </xsl:when>
     <xsl:when test="$anz>0">
       <xsl:call-template name="rep_it">
         <xsl:with-param name="inNodes" select="$inNodes"/>
         <xsl:with-param name="anz" select="$anz -1"/>
       </xsl:call-template>
       <xsl:copy-of select="$inNodes"/>
     </xsl:when>
   </xsl:choose>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ FUNCTION func:drop-nl (inText)  - kill leading whitespace -->
 <func:function name="func:drop_nl"><!-- speedup (included into nl_hlp) -->
   <xsl:param name="inText"/>
   <xsl:variable name="first" select="substring(normalize-space($inText),1,1)"/>
   <func:result>
     <xsl:if test="string-length($first)!=0">
       <xsl:value-of select="$first"/><xsl:value-of select="substring-after($inText,$first)"/>
     </xsl:if>
   </func:result>
 </func:function>
 <!-- }}} -->

 <!-- {{{ TEMPLATE nl_hlp (inText)  - kill all \n's including following whitespaces -->
 <xsl:template name="nl_hlp"><!-- speedup -->
   <xsl:param name="inText" select="."/>
   <xsl:choose>
     <xsl:when test="function-available('mine:nl_hlp')">
       <xsl:value-of select="mine:nl_hlp($inText)"/>
     </xsl:when>
     <xsl:when test="contains($inText,'&#010;')">
       <xsl:value-of select="substring-before($inText,'&#010;')"/>
       <xsl:call-template name="nl_hlp">
         <xsl:with-param name="inText" select="func:drop_nl(substring-after($inText,'&#010;'))"/>
       </xsl:call-template>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="$inText"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ FUNCTION func:strip-root(node)  -  but keep attribs -->
 <func:function name="func:strip-root">
   <xsl:param name="node"/>
   <func:result select="$node[1]/@*|$node[1]/node()"/>
 </func:function>
 <!-- }}} -->

</xsl:stylesheet>
