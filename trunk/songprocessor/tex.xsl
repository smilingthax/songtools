<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:set="http://exslt.org/sets"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                xmlns:mine="thax.home/mine-ext-speed"
                extension-element-prefixes="exsl set func str mine">

 <xsl:output method="text" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:include href="rights-full.xsl"/>
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
   <xsl:text>\blkp</xsl:text><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="img">
   <xsl:text>\picH{</xsl:text><xsl:value-of select="@href"/><xsl:text>}\esng{}</xsl:text><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/title" mode="inhalt">
   <xsl:param name="lang"/>
   <xsl:value-of select="."/>
   <xsl:if test="following-sibling::title[@lang=$lang or not(@lang)]"><xsl:text>|</xsl:text></xsl:if>
 </xsl:template>

 <xsl:template match="song/content">
<!-- multi song/lang mode -->
   <xsl:text>\sng{</xsl:text>
   <xsl:apply-templates select="../title[@lang=current()/@lang or not(@lang)]" mode="inhalt">
     <xsl:with-param name="lang" select="@lang"/>
   </xsl:apply-templates>
   <xsl:text>} %{{{</xsl:text>
   <xsl:value-of select="$nl"/>
<!-- ergänzung w. grab -->
   <xsl:if test="../addinfo or ../text or ../melody">
     <xsl:text>\infos{</xsl:text><xsl:apply-templates select="../addinfo/text()"/>
     <xsl:text>}{</xsl:text><xsl:apply-templates select="../text/text()"/>
     <xsl:text>}{</xsl:text><xsl:apply-templates select="../melody/text()"/>
     <xsl:text>}</xsl:text>
   </xsl:if>
<!-- END ergänzung w. grab -->
   <xsl:call-template name="songcontent"/>
   <xsl:text>\esng{</xsl:text>
     <xsl:variable name="rhlp">
       <xsl:call-template name="copyright">
         <xsl:with-param name="inSong" select=".."/>
         <xsl:with-param name="lang" select="@lang"/>
       </xsl:call-template>
     </xsl:variable>
     <xsl:value-of select="str:subst(str:subst($rhlp,'&amp;','\&amp;'),'&quot;','\&quot;')"/>
   <xsl:text>} %}}}</xsl:text><xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
<!-- one song/lang mode -->
<!--
   <xsl:if test="@lang">
     <xsl:choose>
       <xsl:when test="@lang='de'">
         <xsl:text>\fbr{}Deutsche Version:\nl</xsl:text><xsl:value-of select="$nl"/>
         <xsl:text>\nsfbr{}</xsl:text><xsl:value-of select="$nl"/>
       </xsl:when>
       <xsl:when test="@lang='en'">
         <xsl:text>\fbr{}Englische Version:\nl</xsl:text><xsl:value-of select="$nl"/>
         <xsl:text>\nsfbr{}</xsl:text><xsl:value-of select="$nl"/>
       </xsl:when>
       <xsl:otherwise>
         <xsl:text>\fbr{}'</xsl:text><xsl:value-of select="@lang"/><xsl:text>' Version:</xsl:text>
         <xsl:value-of select="$nl"/>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:if>
   <xsl:call-template name="songcontent"/>-->
 </xsl:template>

 <xsl:template name="songcontent">
   <xsl:apply-templates select="*|text()"/>
 </xsl:template>
 
 <xsl:template match="br">
   <xsl:text>\nl</xsl:text>
   <xsl:if test="@no>1">
     <xsl:text>[</xsl:text><xsl:value-of select="@no *0.25"/>
     <xsl:text>\baselineskip]</xsl:text>
   </xsl:if><xsl:value-of select="$nl"/>
 </xsl:template>
 
 <xsl:template match="br[@break='-2']">
   <xsl:text>\ns</xsl:text>
   <xsl:value-of select="$nl"/>
 </xsl:template>
 
 <xsl:template match="br[@break and @break!='-2']">
   <xsl:text>\nlbreak</xsl:text>
   <xsl:if test="@no>1">
     <xsl:text>[</xsl:text><xsl:value-of select="@no *0.25"/>
     <xsl:text>\baselineskip]</xsl:text>
   </xsl:if><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="akk">
   <xsl:choose>
   <xsl:when test="function-available('mine:akk_subst_tex')">
      <xsl:value-of select="mine:akk_subst_tex(@note,text())"/>
   </xsl:when>
   <xsl:otherwise>
     <xsl:choose>
      <xsl:when test="not(text())">
          <xsl:text>\akks{</xsl:text><xsl:value-of select="str:subst(@note,'#','\#')"/><xsl:text>}{ }</xsl:text>
       </xsl:when>
       <xsl:when test="text()='_'">
          <xsl:text>\akkt{</xsl:text><xsl:value-of select="str:subst(@note,'#','\#')"/><xsl:text>}</xsl:text>
       </xsl:when>
       <xsl:otherwise>
         <xsl:text>\akk{</xsl:text><xsl:value-of select="str:subst(@note,'#','\#')"/><xsl:text>}</xsl:text>
         <xsl:value-of select="str:subst(text(),'_','\_')"/>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="*"><!-- Error-catcher -->
   <xsl:text/>{<xsl:value-of select="text()"/>#<xsl:value-of select="name()"/>}<xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="base">
   <xsl:call-template name="songcontent"/>
 </xsl:template>

 <xsl:template match="rep">
   <xsl:text>\rep</xsl:text>
   <xsl:if test="@no"><xsl:text>[</xsl:text><xsl:value-of select="@no"/><xsl:text>]</xsl:text></xsl:if>
   <xsl:text>{</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>}</xsl:text>
 </xsl:template>

 <xsl:template match="vers">
   <xsl:text>\vers</xsl:text>
   <xsl:if test="@no"><xsl:text>[</xsl:text><xsl:value-of select="@no"/><xsl:text>]</xsl:text></xsl:if>
   <xsl:text>{</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>}</xsl:text>
 </xsl:template>

 <xsl:template match="refr">
   <xsl:text>\refr</xsl:text>
   <xsl:text>{</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>}</xsl:text>
 </xsl:template>

 <xsl:template match="ending">
   <xsl:text>\finally</xsl:text>
   <xsl:text>{</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>}</xsl:text>
 </xsl:template>

 <xsl:template match="bridge">
   <xsl:text>\bridge</xsl:text>
   <xsl:text>{</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>}</xsl:text>
 </xsl:template>

 <xsl:template match="cnr">
   <xsl:text>\callresponse</xsl:text>
   <xsl:text>{</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>}</xsl:text>
 </xsl:template>

 <xsl:template match="next">
   <xsl:text>&amp;</xsl:text>
 </xsl:template>

 <xsl:template match="spacer">
   <xsl:text>\myst{}</xsl:text>
   <xsl:call-template name="rep_it">
     <xsl:with-param name="inNodes"><xsl:text> </xsl:text></xsl:with-param>
     <xsl:with-param name="anz" select="@no"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="quote">
   <xsl:text>{,,}</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>{``}</xsl:text>
 </xsl:template>

 <xsl:template match="tick">
   <xsl:text>'</xsl:text><!-- TODO? -->
 </xsl:template>

 <xsl:template match="hfill">
   <xsl:text>\hfill{}</xsl:text>
 </xsl:template>
 
 <xsl:template match="xlate">
   <xsl:choose>
   <xsl:when test="@inner != 0">
     <xsl:text>(</xsl:text><xsl:call-template name="songcontent"/><xsl:text>)</xsl:text>
   </xsl:when>
   <xsl:when test="@for">
     <xsl:text>(</xsl:text><xsl:value-of select="@for"/>
     <xsl:text>(</xsl:text><xsl:value-of select="@lang"/><xsl:text>.):</xsl:text>
     <xsl:call-template name="songcontent"/><xsl:text>)</xsl:text>
   </xsl:when>
   <xsl:otherwise>
     <xsl:text>\xlate{</xsl:text>
     <xsl:call-template name="songcontent"/>
     <xsl:text>}</xsl:text>
   </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="text()">
   <xsl:choose>
   <xsl:when test="function-available('mine:subst_ul-kill_nl')">
      <xsl:value-of select="mine:subst_ul-kill_nl(.)"/>
   </xsl:when>
   <xsl:otherwise>
     <xsl:value-of select="str:subst(str:killnl(.),'_','\_')"/>
   </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!-- Helper functions -->
 <xsl:template name="rep_it">
   <xsl:param name="inNodes"/>
   <xsl:param name="anz"/>
   <xsl:if test="$anz>0">
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$inNodes"/>
       <xsl:with-param name="anz" select="$anz -1"/>
     </xsl:call-template>
     <xsl:copy-of select="$inNodes"/>
   </xsl:if>
 </xsl:template>

 <func:function name="str:subst"><!-- speedup -->
   <xsl:param name="inText"/>
   <xsl:param name="sub1Text"/>
   <xsl:param name="sub2Text"/>
   <func:result>
     <xsl:choose>
       <xsl:when test="contains($inText,$sub1Text)">
         <xsl:value-of select="substring-before($inText,$sub1Text)"/><xsl:value-of select="$sub2Text"/>
         <xsl:value-of select="str:subst(substring-after($inText,$sub1Text),$sub1Text,$sub2Text)"/>
       </xsl:when>
       <xsl:otherwise>
         <xsl:value-of select="$inText"/>
       </xsl:otherwise>
     </xsl:choose>
   </func:result>
 </func:function>

 <func:function name="str:killnl"><!-- speedup -->
   <xsl:param name="inText"/>
   <func:result>
     <xsl:choose>
       <xsl:when test="contains($inText,'&#010;')">
         <xsl:value-of select="substring-before($inText,'&#010;')"/>
         <xsl:variable name="part2" select="substring-after($inText,'&#010;')"/>
         <xsl:value-of select="substring($part2,str:string-anz-of($part2,' ')+1)"/>
       </xsl:when>
       <xsl:otherwise>
         <xsl:value-of select="$inText"/>
       </xsl:otherwise>
     </xsl:choose>
   </func:result>
 </func:function>

 <func:function name="str:string-anz-of"><!-- speedup -->
   <xsl:param name="inText"/>
   <xsl:param name="subText"/>
   <func:result>
     <xsl:choose>
       <xsl:when test="starts-with($inText,$subText)">
         <xsl:value-of select="str:string-anz-of(substring($inText,2),$subText)+1"/>
       </xsl:when>
       <xsl:otherwise>0</xsl:otherwise>
     </xsl:choose>
   </func:result>
 </func:function>

</xsl:stylesheet>
