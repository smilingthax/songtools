<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:set="http://exslt.org/sets"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl set">

 <xsl:output method="html" encoding="iso-8859-1" indent="no"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:strip-space elements="songs-out"/>

 <xsl:template match="/">
  <html>
   <head>
    <title>songs</title>
   </head>
   <body>
    <xsl:apply-templates select="songs-out/*"/>
   </body>
  </html>
 </xsl:template>

 <xsl:template match="song">
   <xsl:variable name="file">html/<xsl:value-of select="translate(title[1]/text(),' äöüÄÖÜß,?','_aouAOUs')"/>.htm</xsl:variable>
   <exsl:document href="{$file}" encoding="iso-8859-1" method="html" indent="no">
     <html>
      <head>
        <title><xsl:value-of select="title[1]/text()"/></title>
        <xsl:call-template name="gen_script1"/>
      </head>
      <body>
        <xsl:apply-templates select="title" mode="inhalt"/>
        <xsl:apply-templates select="content"/>
        <xsl:call-template name="gen_script2"/>
      </body>
     </html>
   </exsl:document>
   <xsl:apply-templates select="title" mode="links">
     <xsl:with-param name="linkTo" select="$file"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="blkp">
   <h2>Blank Page</h2><xsl:value-of select="$nl"/>
   <br/><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/title" mode="inhalt">
   <h3><xsl:value-of select="."/><xsl:if test="@lang">&#160;[<xsl:value-of select="@lang"/>]</xsl:if>
   </h3><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/title" mode="links">
   <xsl:param name="linkTo"/>
   <xsl:choose>
     <xsl:when test="../content//akk">
       <a href="{$linkTo}"><xsl:value-of select="."/></a>&#160;[akks]<br/><xsl:value-of select="$nl"/>
     </xsl:when>
     <xsl:otherwise>
       <a href="{$linkTo}"><xsl:value-of select="."/></a><br/><xsl:value-of select="$nl"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>
 
 <xsl:template match="song/content">
   <xsl:if test="@lang">
     <xsl:choose>
       <xsl:when test="@lang='de'">
         <h4>Deutsche Version:</h4>
       </xsl:when>
       <xsl:when test="@lang='en'">
         <h4>Englische Version:</h4>
       </xsl:when>
       <xsl:otherwise>
         <h4>'<xsl:value-of select="@lang"/>'Version:</h4>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:if>
   <div class="out"><xsl:call-template name="songcontent"/></div>
 </xsl:template>

 <xsl:template name="songcontent">
   <xsl:param name="inNodes" select="*|text()"/>
   <xsl:param name="out_style"/>
   <xsl:param name="indent"/>
   <xsl:param name="first"/>
   <xsl:param name="noakk"/>
   <xsl:variable name="tree1" select="set:leading($inNodes,$inNodes[self::br][1])"/>
   <xsl:variable name="akk_inline" select="set:leading($tree1[self::rep]/*,$tree1[self::rep]/br[1])[self::akk]"/>
   <xsl:if test="($tree1[self::akk][1] or $akk_inline) and not($noakk)">
     <div class="akk1">
     <xsl:apply-templates select="$tree1" mode="do-akks">
       <xsl:with-param name="out_style" select="$out_style"/>
     </xsl:apply-templates><br class="akkbreak"/></div>
   </xsl:if>
   <xsl:choose>
     <xsl:when test="$first"><xsl:copy-of select="$first"/></xsl:when>
     <xsl:when test="count($inNodes[self::br])=0 and not($tree1/text())"/>
     <xsl:when test="$indent"><span class="inv"><xsl:copy-of select="$indent"/></span></xsl:when>
   </xsl:choose>
   <xsl:apply-templates select="$tree1" mode="do-text">
     <xsl:with-param name="out_style" select="$out_style"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   <xsl:if test="$inNodes[self::br][1]">
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes"><span class="break"><br/></span></xsl:with-param>
       <xsl:with-param name="anz" select="$inNodes[self::br][1]/@no"/>
     </xsl:call-template>
     <xsl:variable name="tree2" select="set:trailing($inNodes,$inNodes[self::br][1])"/>
     <xsl:call-template name="songcontent">
       <xsl:with-param name="inNodes" select="$tree2"/>
       <xsl:with-param name="out_style" select="$out_style"/>
       <xsl:with-param name="indent" select="$indent"/>
     </xsl:call-template>
   </xsl:if>
 </xsl:template>

 <xsl:template match="node()" mode="do-akks"/>
 
 <xsl:template match="rep" mode="do-akks"><!-- match alle inline-tags! -->
   <xsl:param name="out_style"/>
   <xsl:apply-templates mode="do-akks" select="set:leading(*|text(),br[1])">
     <xsl:with-param name="out_style" select="$out_style"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="akk" mode="do-akks">
   <xsl:variable name="theId">akk<xsl:value-of select="generate-id(.)"/></xsl:variable>
   <div class="akk2" id="{$theId}"><xsl:value-of select="@note"/></div>
 </xsl:template>

 <xsl:template match="akk" mode="do-text">
   <xsl:param name="out_style"/>
   <xsl:variable name="theId">akk<xsl:value-of select="generate-id(.)"/></xsl:variable><!-- gleich der in do-akks! -->
   <xsl:choose>
     <xsl:when test="not(text())">
       <span class="{$out_style}akk1h" id="{$theId}_">&#160;<xsl:value-of select="@note"/></span>
     </xsl:when>
     <xsl:otherwise>
       <span class="{$out_style}akk1" id="{$theId}_"><xsl:value-of select="text()"/></span>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="node()" mode="do-text">
   <xsl:param name="out_style"/>
   <xsl:param name="indent"/>
   <xsl:apply-templates select=".">
     <xsl:with-param name="out_style" select="$out_style"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="*"><!-- Error-catcher -->
   <xsl:text/>{<xsl:value-of select="text()"/>#<xsl:value-of select="name()"/>}<xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="rep">
   <xsl:param name="out_style"/>
   <xsl:param name="indent"/>
   <xsl:variable name="part1">|:</xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="out_style" select="$out_style"/>
     <xsl:with-param name="first"><xsl:value-of select="$part1"/>
       <xsl:if test="not(starts-with(text()[1],' '))">&#160;</xsl:if>
     </xsl:with-param>
     <xsl:with-param name="indent"><xsl:copy-of select="$indent"/><xsl:value-of select="$part1"/></xsl:with-param>
     <xsl:with-param name="noakk" select="'1'"/>
   </xsl:call-template>
   <xsl:text/>&#160;:|<xsl:if test="@no">&#160;(<xsl:value-of select="@no"/>x)</xsl:if>
 </xsl:template>

 <xsl:template match="vers">
   <xsl:variable name="part1"><xsl:value-of select="@no"/>.</xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="indent" select="$part1"/>
     <xsl:with-param name="first" select="$part1"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="refr">
   <xsl:variable name="part1">Refr:</xsl:variable>
   <span class="it">
   <xsl:call-template name="songcontent">
     <xsl:with-param name="out_style">i</xsl:with-param>
     <xsl:with-param name="indent" select="$part1"/>
     <xsl:with-param name="first" select="$part1"/>
   </xsl:call-template></span>
 </xsl:template>

 <xsl:template match="ending">
   <xsl:variable name="part1">Schluss:</xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="indent" select="$part1"/>
     <xsl:with-param name="first" select="$part1"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="bridge">
   <xsl:variable name="part1">Bridge:</xsl:variable>
   <xsl:call-template name="songcontent">
     <xsl:with-param name="indent" select="$part1"/>
     <xsl:with-param name="first" select="$part1"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="cnr">
   <xsl:param name="out_style"/>
   <xsl:variable name="theId">cnr<xsl:value-of select="generate-id(.)"/></xsl:variable>
   <span id="{$theId}_"/>
   <table border="0" cellpadding="0" cellspacing="0" style="position:relative; float:left;" id="{$theId}">
   <xsl:call-template name="cnr-hlp"/>
   </table>
 </xsl:template>
 <xsl:template name="cnr-hlp">
   <xsl:param name="inNodes" select="node()"/>
   <xsl:variable name="tree1" select="set:leading($inNodes,$inNodes[self::next][1])"/>
   <xsl:variable name="tree2a" select="set:trailing($inNodes,$inNodes[self::next][1])"/>
   <xsl:variable name="tree2b" select="set:leading($inNodes,$inNodes[self::br][1])"/>
   <xsl:variable name="tree2" select="set:intersection($tree2a,$tree2b)"/>
   <tr><td valign="bottom">
     <xsl:call-template name="songcontent">
       <xsl:with-param name="inNodes" select="$tree1"/>
     </xsl:call-template>
   </td><td width="1px" bgcolor="#000000"></td><td valign="bottom">
     <xsl:call-template name="songcontent">
       <xsl:with-param name="inNodes" select="$tree2"/>
     </xsl:call-template>
   </td></tr><xsl:value-of select="$nl"/>
   <xsl:if test="$inNodes[self::br][1]">
     <xsl:variable name="tree3" select="set:trailing($inNodes,$inNodes[self::br][1])"/>
     <xsl:call-template name="cnr-hlp"><xsl:with-param name="inNodes" select="$tree3"/></xsl:call-template>
   </xsl:if>
 </xsl:template>

 <xsl:template match="spacer">
   <xsl:text>&#160;&#160;</xsl:text>
 </xsl:template>

 <xsl:template match="quote">
   <xsl:call-template name="songcontent">
     <xsl:with-param name="first" select="'&#8222;'"/>
   </xsl:call-template>
   <xsl:text>&#8220;</xsl:text>
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

 <xsl:template name="gen_script1">
<style>
div.akk1  { font-size:75%; }
div.akk2  { position:relative; float:left; top:+0.3em; line-height:0.75em; }
div.out   { } 
span.it   { font-style:italic; }
span.akk1   { }
span.iakk1  { }
span.akk1h  { visibility:hidden; }
span.iakk1h { visibility:hidden; }
span.inv    { visibility:hidden; }
span.break    { font-size:45%; }
br.akkbreak { font-size:0.65em; }
</style>
 </xsl:template>

 <xsl:template name="gen_script2">
<script type="text/javascript">
function do_it() {
  var outs=document.getElementsByTagName("div");
  for (iA=0; iA&lt;outs.length; iA++) {
    if (outs[iA].className=="akk2") {
      var akku=document.getElementById(outs[iA].id+"_");
      if (akku.className[0]=="i") {
        outs[iA].style.left=(akku.offsetLeft-outs[iA].offsetLeft+(akku.offsetWidth-outs[iA].offsetWidth)/2)+3+"px";
      } else {
        outs[iA].style.left=(akku.offsetLeft-outs[iA].offsetLeft+(akku.offsetWidth-outs[iA].offsetWidth)/2)+"px";
      }
    }
  }
}
//setTimeout("do_it()",200);
do_it();
</script>
 </xsl:template>

</xsl:stylesheet>
