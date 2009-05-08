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
   <xsl:apply-templates select="../title[@lang=current()/@lang or not(@lang)]">
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
       <first><xsl:text>. </xsl:text></first>
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
   </xsl:variable>
   <xsl:variable name="inNodes">
     <xsl:apply-templates select="*" mode="_songcontent">
       <xsl:with-param name="config" select="exsl:node-set($config)"/>
     </xsl:apply-templates>
   </xsl:variable>
   <xsl:apply-templates select="exsl:node-set($inNodes)" mode="_sc_post"/>
 </xsl:template>

 <!-- {{{ songcontent postprocessing: _sc_post -->
 <xsl:template match="line" mode="_sc_post">
   <xsl:value-of select="."/>
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
   <xsl:if test="not(text()='-')">
     <xsl:text>[</xsl:text><xsl:value-of select="@note"/><xsl:text>]</xsl:text>
   </xsl:if>
   <xsl:value-of select="text()"/>
   <xsl:choose>
     <xsl:when test="not(text())">
       <xsl:text> </xsl:text>
     </xsl:when>
     <xsl:when test="text()='_'"/>
     <xsl:otherwise/>
   </xsl:choose>
 </xsl:template>

 <!-- {{{ block tags -->
 <xsl:template match="base|refr|bridge|ending" mode="_songcontent">
   <xsl:param name="config" select="/.."/>
   <xsl:variable name="this" select="$config/*[name()=name(current())]"/>
   <xsl:call-template name="songcontent_block">
     <xsl:with-param name="ctxt" select="$config|.."/>
     <xsl:with-param name="first" select="func:strip-root($this/first)"/>
     <xsl:with-param name="indent" select="str:padding(string-length($this/first),' ')"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="vers" mode="_songcontent">
   <xsl:param name="config" select="/.."/>
   <xsl:variable name="this" select="$config/*[name()=name(current())]"/>
   <xsl:variable name="first"><xsl:value-of select="@no"/><xsl:text>. </xsl:text></xsl:variable>
   <xsl:call-template name="songcontent_block">
     <xsl:with-param name="ctxt" select="$config|.."/>
     <xsl:with-param name="first" select="$first"/>
     <xsl:with-param name="indent" select="str:padding(string-length($first),' ')"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="img" mode="_songcontent">
   <line no="1"><xsl:text>*Img:</xsl:text><xsl:value-of select="@href"/></line><xsl:value-of select ="$nl"/>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ inline tags -->
 <xsl:template match="rep" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:text>|: </xsl:text>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent"><xsl:copy-of select="$indent"/><xsl:text>   </xsl:text></xsl:with-param><!-- ?TODO str:padding -->
   </xsl:apply-templates>
   <xsl:choose>
     <xsl:when test="@no >2"><xsl:text> :| (</xsl:text><xsl:value-of select="@no"/><xsl:text>x)</xsl:text></xsl:when>
     <xsl:otherwise><xsl:text> :|</xsl:text></xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!-- TODO... -->
 <xsl:template match="cnr" mode="_songcontent">
   <xsl:call-template name="songcontent"/>
 </xsl:template>
 <xsl:template match="next" mode="_songcontent">
   <xsl:text> &amp; </xsl:text>
 </xsl:template>

 <xsl:template match="quote" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:variable name="quotes" select="$ctxt/quotes[@lang=$ctxt/@lang or not(@lang)]"/>
   <xsl:value-of select="$quotes/@start"/>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   <xsl:value-of select="$quotes/@end"/>
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

<!--
 <!- - {{{ FUNCTION func:drop-nl (inText)  - kill leading whitespace - ->
 <func:function name="func:drop_nl"><!- - speedup (included into nl_hlp) - ->
   <xsl:param name="inText"/>
   <xsl:variable name="first" select="substring(normalize-space($inText),1,1)"/>
   <func:result>
     <xsl:if test="string-length($first)!=0">
       <xsl:value-of select="$first"/><xsl:value-of select="substring-after($inText,$first)"/>
     </xsl:if>
   </func:result>
 </func:function>
 <!- - }}} - ->

 <!- - {{{ TEMPLATE nl_hlp (inText)  - kill all \n's including following whitespaces - ->
 <xsl:template name="nl_hlp"><!- - speedup - ->
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
 <!- - }}} - ->
-->

 <!-- {{{ FUNCTION func:strip-root(node)  -  but keep attribs -->
 <func:function name="func:strip-root">
   <xsl:param name="node"/>
   <func:result select="$node[1]/@*|$node[1]/node()"/>
 </func:function>
 <!-- }}} -->

</xsl:stylesheet>
