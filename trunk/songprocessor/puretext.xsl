<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:set="http://exslt.org/sets"
                xmlns:exsl="http://exslt.org/common"
                xmlns:mine="thax.home/mine-ext-speed"
                xmlns:ec="thax.home/enclose"
                extension-element-prefixes="func set mine ec exsl">

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
   <xsl:apply-templates match="*"/>
<!--   <xsl:call-template name="songcontent"/>-->
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
   <xsl:param name="indent" select="'0'"/>
   <xsl:param name="first"/>
   <xsl:variable name="lines" select="ec:enclose(*|text(),'$nodes[self::br]','line')"/>
   <xsl:for-each select="exsl:node-set($lines)">
     <xsl:choose>
       <xsl:when test="$first and position()=1"><xsl:value-of select="$first"/></xsl:when>
       <xsl:when test="not(text())"/>
       <xsl:when test="$indent">
         <xsl:call-template name="rep_it">
           <xsl:with-param name="inNodes" select="' '"/>
           <xsl:with-param name="anz" select="$indent"/>
         </xsl:call-template>
       </xsl:when>
     </xsl:choose>
     <xsl:apply-templates select="node()" mode="_songcontent">
       <xsl:with-param name="indent" select="$indent"/>
     </xsl:apply-templates>
     <xsl:if test="@no">
       <xsl:call-template name="rep_it">
         <xsl:with-param name="inNodes" select="$nl"/>
         <xsl:with-param name="anz" select="@no"/>
       </xsl:call-template>
       <xsl:if test="@break">
          <xsl:text>$f</xsl:text>
       </xsl:if>
     </xsl:if>
   </xsl:for-each>
 <!--
   <xsl:param name="inNodes" select="*|text()"/>
   <xsl:param name="indent" select="'0'"/>
   <xsl:param name="first"/>
   <xsl:variable name="tree1" select="set:leading($inNodes,$inNodes[self::br][1])"/>
   <xsl:choose>
     <xsl:when test="$first"><xsl:value-of select="$first"/></xsl:when>
     <xsl:when test="not($inNodes/text())"/>
     <xsl:when test="$indent">
       <xsl:call-template name="rep_it">
         <xsl:with-param name="inNodes" select="' '"/>
         <xsl:with-param name="anz" select="$indent"/>
       </xsl:call-template>
     </xsl:when>
   </xsl:choose>
   <xsl:apply-templates select="$tree1" mode="_songcontent">
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   <xsl:if test="$inNodes[self::br][1]">
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$nl"/>
       <xsl:with-param name="anz" select="$inNodes[self::br][1]/@no"/>
     </xsl:call-template>
     <xsl:if test="$inNodes[self::br][1]/@break">
        <xsl:text>$f</xsl:text>
     </xsl:if>
     <xsl:variable name="tree2" select="set:trailing($inNodes,$inNodes[self::br][1])"/>
     <xsl:call-template name="songcontent">
       <xsl:with-param name="inNodes" select="$tree2"/>
       <xsl:with-param name="indent" select="$indent"/>
     </xsl:call-template>
   </xsl:if>
   -->
 </xsl:template>

 <xsl:template match="*" name="error_trap"><!-- Error-catcher -->
   <xsl:text>{</xsl:text>
   <xsl:value-of select="text()"/>
   <xsl:text>#</xsl:text>
   <xsl:value-of select="name()"/>
   <xsl:text>}</xsl:text>
   <xsl:value-of select="$nl"/>
 </xsl:template>
 <xsl:template match="*" mode="_songcontent">
   <xsl:call-template name="error_trap"/>
 </xsl:template>

 <xsl:template match="text()"/>
 
 <xsl:template match="text()" mode="_songcontent">
   <xsl:call-template name="nl_hlp"/>
 </xsl:template>

 <xsl:template match="akk" mode="_songcontent">
   <xsl:text>[</xsl:text><xsl:value-of select="@note"/><xsl:text>]</xsl:text>
   <xsl:value-of select="text()"/>
   <xsl:choose>
     <xsl:when test="not(text())">
       <xsl:text> </xsl:text>
     </xsl:when>
     <xsl:when test="text()='_'"/>
     <xsl:otherwise/>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="base">
   <xsl:call-template name="songcontent"/>
 </xsl:template>

 <xsl:template match="vers">
   <xsl:variable name="pre"><xsl:value-of select="@no"/><xsl:text>. </xsl:text></xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first" select="$pre"/>
     <xsl:with-param name="indent" select="string-length($pre)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="refr">
   <xsl:variable name="pre"><xsl:text>Refr: </xsl:text></xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first" select="$pre"/>
     <xsl:with-param name="indent" select="string-length($pre)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="bridge">
   <xsl:variable name="pre"><xsl:text>Bridge: </xsl:text></xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first" select="$pre"/>
     <xsl:with-param name="indent" select="string-length($pre)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="ending">
   <xsl:variable name="pre"><xsl:text>Schluss: </xsl:text></xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first" select="$pre"/>
     <xsl:with-param name="indent" select="string-length($pre)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="rep" mode="_songcontent">
   <xsl:param name="indent" select="'0'"/>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first"><xsl:text>|: </xsl:text></xsl:with-param>
     <xsl:with-param name="indent" select="$indent +3"/>
   </xsl:call-template>
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

 <xsl:template match="quote" mode="_songcontent">
   <xsl:param name="indent" select="'0'"/>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first"><xsl:text>"</xsl:text></xsl:with-param>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:call-template>
   <xsl:text>"</xsl:text>
 </xsl:template>

 <xsl:template match="spacer" mode="_songcontent">
   <xsl:call-template name="rep_it">
     <xsl:with-param name="inNodes"><xsl:text>  </xsl:text></xsl:with-param>
     <xsl:with-param name="anz" select="@no"/>
   </xsl:call-template>
 </xsl:template>
 
 <xsl:template match="hfill" mode="_songcontent">
   <xsl:call-template name="rep_it">
     <xsl:with-param name="inNodes"><xsl:text> </xsl:text></xsl:with-param>
     <xsl:with-param name="anz" select="30"/>
   </xsl:call-template>
 </xsl:template>
 
 <xsl:template match="xlate" mode="_songcontent">
   <xsl:param name="indent" select="'0'"/>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first"><xsl:text>(Übersetzung: </xsl:text></xsl:with-param>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:call-template>
   <xsl:text>)</xsl:text>
 </xsl:template>

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
     <xsl:choose>
       <xsl:when test="string-length($first)=0"/>
       <xsl:otherwise>
         <xsl:value-of select="$first"/><xsl:value-of select="substring-after($inText,$first)"/>
       </xsl:otherwise>
     </xsl:choose>
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

</xsl:stylesheet>
