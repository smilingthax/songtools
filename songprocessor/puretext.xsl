<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:thobi="thax.home/split"
                xmlns:str="http://exslt.org/strings"
                xmlns:mine="thax.home/mine-ext-speed"
                xmlns:ec="thax.home/enclose"
                extension-element-prefixes="func mine ec exsl str thobi">

 <xsl:import href="s-liner.xsl"/>

 <xsl:output method="text" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:strip-space elements="songs-out"/>

 <xsl:template match="/">
   <xsl:apply-templates select="songs-out/*"/>
 </xsl:template>

 <xsl:template match="song">
<!-- multi song/lang mode -->
   <xsl:apply-templates select="content"/>
   <xsl:if test="content[not(@lang)]">
     <xsl:message terminate="yes">lang attribute not specified for content of "<xsl:value-of select="title[1]"/>"</xsl:message>
   </xsl:if>
<!-- one song/lang mode -->
<!--
   <xsl:apply-templates select="title"/>
   <xsl:text>- - - - -</xsl:text><xsl:value-of select="$nl"/>
   <xsl:apply-templates select="content"/>
   <xsl:text>$e</xsl:text><xsl:value-of select="$nl"/>-->
 </xsl:template>

 <xsl:template match="blkp">
   <xsl:text>$t****</xsl:text><xsl:value-of select="$nl"/>
   <xsl:text>$e</xsl:text><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="img">
   <xsl:text>$t*</xsl:text><xsl:value-of select="@href"/><xsl:value-of select="$nl"/>
   <xsl:text>*Img:</xsl:text><xsl:value-of select="@href"/><xsl:value-of select ="$nl"/>
   <xsl:text>$e</xsl:text><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/title">
   <xsl:param name="lang"/>
   <xsl:text>$t</xsl:text>
   <xsl:value-of select="."/>
   <xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/content">
<!-- multi song/lang mode -->
   <xsl:apply-templates select="../title[@lang=mine:main_lang(current()/@lang)]">
     <xsl:with-param name="lang" select="@lang"/>
   </xsl:apply-templates>
<!-- -->
   <xsl:if test="../copyright">
     <xsl:text>$c</xsl:text><xsl:value-of select="../copyright"/><xsl:value-of select="$nl"/>
   </xsl:if>
   <xsl:text>-----</xsl:text><xsl:value-of select="$nl"/>
   <xsl:call-template name="songcontent"/>
   <xsl:text>$e</xsl:text><xsl:value-of select="$nl"/>
<!-- one song/lang mode -->
<!--
   <xsl:if test="@lang">
     <xsl:choose>
       <xsl:when test="@lang='de'">
         <xsl:text>$fDeutsche Version:
</xsl:text>
       </xsl:when>
       <xsl:when test="@lang='en'">
         <xsl:text>$fEnglische Version:
</xsl:text>
       </xsl:when>
       <xsl:otherwise>
         <xsl:text>$f'</xsl:text><xsl:value-of select="@lang"/><xsl:text>'Version:
</xsl:text>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:if>
   <xsl:call-template name="songcontent"/>-->
   <!-- implicit $f in tex! -->
 </xsl:template>

 <xsl:template name="songcontent">
   <xsl:variable name="config">
     <base/>
     <vers>
       <first><num fmt="#"/><xsl:text>. </xsl:text></first>
     </vers>
     <refr>
       <first><xsl:text>Refr: </xsl:text></first>
     </refr>
     <bridge>
       <first><xsl:text>Bridge: </xsl:text></first>
     </bridge>
     <ending>
       <first><xsl:text>Schluss: </xsl:text></first>
     </ending>
     <quotes start="&quot;" end="&quot;"/>
     <tick><xsl:text>'</xsl:text></tick>
     <rep>
       <start>|: </start>
       <simpleend> :|</simpleend>
       <end> :| (<num fmt="#"/>x)</end>
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
   <xsl:variable name="justxlang" select="not(../line[not(@xlang)])"/>

   <xsl:choose>
     <xsl:when test="@firstpos and (not(@xlang) or $justxlang)">
       <xsl:value-of select="$ctxt/block/first"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="str:padding(string-length($ctxt/block/first),' ')"/>
     </xsl:otherwise>
   </xsl:choose>
   <xsl:value-of select="str:padding(string-length($ctxt/rep/start)*($repindent - $solrep),' ')"/>

   <xsl:if test="@xlang">
     <xsl:text>  ~</xsl:text>
   </xsl:if>
   <xsl:apply-templates select="node()" mode="_sc_post">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
   <xsl:if test="@xlang">
     <xsl:text>~</xsl:text>
   </xsl:if>
   <xsl:if test="@no">
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$nl"/>
       <xsl:with-param name="anz" select="@no"/>
     </xsl:call-template>
     <xsl:if test="@break">
        <xsl:text>$f</xsl:text>
     </xsl:if>
   </xsl:if>
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

 <!-- override: print [akk] -->
 <xsl:template match="akk" mode="_songcontent_inline">
   <xsl:if test="@note">
     <xsl:text>[</xsl:text><xsl:value-of select="@note"/><xsl:text>]</xsl:text>
   </xsl:if>
   <xsl:value-of select="text()"/>
 </xsl:template>

 <!-- {{{ block tags -->
 <xsl:template match="img" mode="_songcontent">
   <xsl:param name="ctxt"/>
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

 <xsl:template match="spacer" mode="_songcontent_inline">
   <xsl:value-of select="str:padding(@no *2,' ')"/>
 </xsl:template>

 <xsl:template match="hfill" mode="_songcontent_inline">
   <!-- TODO? this is just damage containment -->
   <xsl:value-of select="str:padding(20,' ')"/>
 </xsl:template>
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

 <!-- {{{ FUNCTION func:strip-root(node)  -  but keep attribs -->
 <func:function name="func:strip-root">
   <xsl:param name="node"/>
   <func:result select="$node[1]/@*|$node[1]/node()"/>
 </func:function>
 <!-- }}} -->

 <func:function name="mine:main_lang"> <!-- {{{ main_lang('en+de')='en'   ('en+de',3)='de' -->
   <xsl:param name="lang"/>
   <xsl:param name="num" select="1"/>
   <xsl:variable name="split" select="thobi:separate($lang,'+')"/>
   <func:result select="$split[$num][self::text()]"/>
 </func:function>
 <!-- }}} -->

</xsl:stylesheet>
