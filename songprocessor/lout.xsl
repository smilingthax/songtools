<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:set="http://exslt.org/sets"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="exsl set func str">

 <xsl:output method="text" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:strip-space elements="songs-out"/>

 <xsl:template match="/">
   @SysInclude {doc}
   def @invis right x { { false "\{" // "\}" if grestore } @Graphic { x } }
   def @akkbox left x right y {
     { -0.5w @HShift @OneCol { {} &amp;0io { 0.5w @HShift x } &amp;0io {} ^/0.6vx @invis { 0.5w @HShift y } } } &amp;0io {}
   }
   def @akksbox left x right y {
     { -0.5w @HShift @OneCol { {} &amp;0io { 0.5w @HShift x } &amp;0io {} ^/0.6vx @invis { 0.5w @HShift { y &amp;1s {} } } } }
   }
   def @akktbox left x {
     { @OneCol { {} &amp;0io { x } &amp;0io {} ^/0.6vx {} } }
   }
   def @break {}
   @Doc @Text @Begin<xsl:value-of select="$nl"/>
   <xsl:apply-templates select="songs-out/*"/>
   @Null
   @End @Text<xsl:value-of select="$nl"/>
 </xsl:template>
 
 <xsl:template match="song">
<!-- multi song/lang mode -->
   <xsl:apply-templates select="content"/>
<!-- one song/lang mode -->
 </xsl:template>
 
 <xsl:template match="blkp">
   <xsl:text>BLKP @LLP</xsl:text><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/title" mode="inhalt">
   <xsl:param name="lang"/>
   <xsl:value-of select="."/>
   <xsl:if test="following-sibling::title[@lang=$lang or not($lang)]"><xsl:text> @LLP</xsl:text><xsl:value-of select="$nl"/></xsl:if>
 </xsl:template>

 <xsl:template match="song/content">
<!-- multi song/lang mode -->
   <xsl:text>16p @Font {</xsl:text>
   <xsl:apply-templates select="../title[@lang=current()/@lang or not(@lang)]" mode="inhalt">
     <xsl:with-param name="lang" select="@lang"/>
   </xsl:apply-templates>
   <xsl:text> } //{1vx} @FullWidthRule //{2vx} </xsl:text>
   <xsl:value-of select="$nl"/>
   <xsl:call-template name="songcontent"/>
   <xsl:text> @NP </xsl:text>
 </xsl:template>

 <xsl:template name="songcontent">
   <xsl:param name="inNodes" select="*|text()"/>
   <xsl:variable name="tree1" select="set:leading($inNodes,$inNodes[self::br][1])"/>
   <xsl:apply-templates select="$tree1"/>
   <xsl:if test="$inNodes[self::br][1]">
     <xsl:if test="not($inNodes[self::br][1]/@no>1)">
       <xsl:text> //{1.5vx}</xsl:text>
     </xsl:if>
     <xsl:if test="$inNodes[self::br][1]/@break">
      <xsl:text> @break</xsl:text>
     </xsl:if>
     <xsl:if test="$inNodes[self::br][1]/@no>1">
       <xsl:text> //{</xsl:text><xsl:value-of select="$inNodes[self::br][1]/@no"/>
       <xsl:text>vx}</xsl:text>
     </xsl:if>
     <xsl:variable name="tree2" select="set:trailing($inNodes,$inNodes[self::br][1])"/>
     <xsl:call-template name="songcontent">
       <xsl:with-param name="inNodes" select="$tree2"/>
     </xsl:call-template>
   </xsl:if>
 </xsl:template>

 <xsl:template match="akk">
     <xsl:variable name="nt" select="@note"/>
     <xsl:choose>
       <xsl:when test="not(text())">
          <xsl:text>{ "</xsl:text><xsl:value-of select="$nt"/><xsl:text>" @akksbox "</xsl:text>
          <xsl:value-of select="$nt"/><xsl:text>" }</xsl:text>
       </xsl:when>
       <xsl:when test="text()='_'">
         <xsl:text>{ "</xsl:text><xsl:value-of select="$nt"/><xsl:text>" @akktbox }</xsl:text>
       </xsl:when>
       <xsl:otherwise>
         <xsl:text>{ "</xsl:text><xsl:value-of select="$nt"/><xsl:text>" @akkbox { </xsl:text>
         <xsl:value-of select="text()"/><xsl:text> } }</xsl:text>
         <xsl:value-of select="text()"/>
       </xsl:otherwise>
     </xsl:choose>
 </xsl:template>

 <xsl:template match="*"><!-- Error-catcher -->
   <xsl:text/>"\{ <xsl:value-of select="text()"/>#<xsl:value-of select="name()"/> \}"<xsl:value-of select="$nl"/>
 </xsl:template>
 
 <xsl:template match="base">
   <xsl:call-template name="songcontent"/>
 </xsl:template>
 
 <xsl:template match="rep">
   <xsl:text>{ "|": {</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text> :"|" </xsl:text>
   <xsl:if test="@no"><xsl:text>(</xsl:text><xsl:value-of select="@no"/><xsl:text>x)</xsl:text></xsl:if>
   <xsl:text>} } //{0vk} </xsl:text>
 </xsl:template>

 <xsl:template match="vers">
   <xsl:text>{ </xsl:text><xsl:value-of select="@no"/><xsl:text>. {</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>} } //{0vk}</xsl:text>
 </xsl:template>

 <xsl:template match="refr">
   <xsl:text>@I { Refr: {</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>} } //{0vk}</xsl:text>
 </xsl:template>

 <xsl:template match="ending">
   <xsl:text>{ Schluss: { </xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>} } //{0vk}</xsl:text>
 </xsl:template>

 <xsl:template match="bridge">
   <xsl:text>{ Bridge: { </xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>} } //{0vk}</xsl:text>
 </xsl:template>

 <xsl:template match="cnr">
   <xsl:text>{ </xsl:text>
   <xsl:text> cnr {</xsl:text>
   <xsl:call-template name="songcontent"/>
   <xsl:text>} } //{0vk}</xsl:text>
 </xsl:template>

 <xsl:template match="next">
   <xsl:text>next</xsl:text>
 </xsl:template>

 <xsl:template match="spacer">
<!--   <xsl:text>\myst{}</xsl:text> TODO-->
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

 <xsl:template match="hfill">
   <xsl:text>hfill</xsl:text>
 </xsl:template>

 <xsl:template match="text()">
   <xsl:value-of select="."/>
 </xsl:template>

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

</xsl:stylesheet>
