<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="func exsl str">

 <xsl:output method="html" encoding="iso-8859-1" indent="no"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>
 <xsl:variable name="root" select="/"/>

 <xsl:template match="/">
   <xsl:apply-templates match="*"/>
 </xsl:template>

 <xsl:template match="docu">
   <html>
     <head>
       <title><xsl:value-of select="@title"/></title>
       <style title="normal">
         a:link      { color:#f00000; text-decoration: none; }
         a:visited   { color:#f00000; text-decoration: none; }
         a:hover     { color:#f00000; text-decoration: underline; }
         div.code    { background-color: #e0e0e0; width: 50%; }
         div.badcode { background-color: #ffe0e0; width: 50%; }
       </style>
       <style title="print">
         body        { background-color: #ffffff; }
         a:link      { color:#000000; text-decoration: none; font-weight: bold; }
         a:visited   { color:#000000; text-decoration: none; font-weight: bold; }
         a:hover     { color:#000000; text-decoration: underline; font-weight: bold; }
         div.code    { border-left-width: 2px; border-left-style: solid; border-left-color: #000000; padding-left: 2px; background-color: #e0e0e0; width: 50%; }
         div.badcode { border-left-width: 2px; border-left-style: dotted; border-left-color: #000000; padding-left: 2px; background-color: #ffe0e0; width: 50%; }
       </style>
     </head>
     <body>
       <h1><xsl:value-of select="@title"/></h1>
       <xsl:apply-templates match="section|tag" mode="toc"/>
       <hr/>
       <xsl:apply-templates match="*"/>
     </body>
   </html>
 </xsl:template>

 <xsl:template match="node()" mode="toc"></xsl:template>

 <xsl:template match="section" mode="toc">
   <a href="#{@id}"><xsl:value-of select="text()"/></a><br/>
   <xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="tag" mode="toc">
  <xsl:if test="not(@linkonly)">
   <xsl:text/>&#160;&#160;<a href="#{text()}">Der '<xsl:value-of select="text()"/>'-Tag</a><br/>
   <xsl:value-of select="$nl"/>
  </xsl:if>
 </xsl:template>

 <xsl:template match="a|ul|ol|li|em">
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template match="docu/br">
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template match="docu//text()">
   <xsl:copy-of select="str:subst-tags(.)"/>
 </xsl:template>

 <xsl:template match="section">
   <xsl:if test="not(@id)"><xsl:message terminate="yes">error</xsl:message></xsl:if>
   <a name="{@id}"/><h2><xsl:value-of select="text()"/></h2><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="tag">
   <xsl:choose>
     <xsl:when test="@linkonly">
       <a name="{text()}"/>
     </xsl:when>
     <xsl:otherwise>
       <a name="{text()}"/><h3>Der '<xsl:value-of select="text()"/>'-Tag</h3><xsl:value-of select="$nl"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="ref">
   <xsl:choose>
     <xsl:when test="text()">
       <a href="#{@to}"><xsl:value-of select="text()"/></a>
     </xsl:when>
     <xsl:otherwise>
       <a href="#{@to}"><xsl:value-of select="/docu/section[@id=current()/@to]/text()"/></a>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="attr">
   <xsl:choose>
     <xsl:when test="@opt >0">
       <b>Optionales Attribut: </b><i><xsl:value-of select="@name"/></i>&#160;&#160;<xsl:apply-templates select="node()"/>
     </xsl:when>
     <xsl:otherwise>
       <b>Notwendiges Attribut: </b><i><xsl:value-of select="@name"/></i>&#160;&#160;<xsl:apply-templates select="node()"/>
     </xsl:otherwise>
   </xsl:choose>
   <!--<xsl:value-of select="text()"/>-->
   <br/><br/><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="attref">
   <i><xsl:value-of select="@name"/></i>
 </xsl:template>

 <xsl:template match="code">
   <xsl:choose>
     <xsl:when test="@bad='1'">
       <div class="badcode"><code><xsl:apply-templates select="node()"/></code></div>
     </xsl:when>
     <xsl:otherwise>
       <div class="code"><code><xsl:apply-templates select="node()"/></code></div>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="code//text()">
   <xsl:copy-of select="str:subst-spacer(str:subst-tags(str:subst-br(.,1,1)))"/>
 </xsl:template>

 <!-- Helpers -->
 <func:function name="str:subst-br">
   <xsl:param name="inNodes"/>
   <xsl:param name="ignore">0</xsl:param>
   <xsl:param name="crop">0</xsl:param>
   <xsl:variable name="ret">
     <xsl:apply-templates select="$inNodes" mode="_subst_br">
       <xsl:with-param name="ignore" select="$ignore"/>
       <xsl:with-param name="crop" select="$crop"/>
     </xsl:apply-templates>
   </xsl:variable>
   <func:result select="exsl:node-set($ret)"/>
 </func:function>

 <xsl:template mode="_subst_br" match="*">
   <xsl:param name="ignore">0</xsl:param>
   <xsl:param name="crop">0</xsl:param>
   <xsl:variable name="ign">
     <xsl:choose>
       <xsl:when test="count(preceding-sibling::text())=0"><xsl:value-of select="$ignore"/></xsl:when>
       <xsl:otherwise>0</xsl:otherwise>
     </xsl:choose>
   </xsl:variable>
   <xsl:variable name="crp">
     <xsl:choose>
       <xsl:when test="count(following::text())=0"><xsl:value-of select="$crop"/></xsl:when>
       <xsl:otherwise>0</xsl:otherwise>
     </xsl:choose>
   </xsl:variable>
   <xsl:copy>
     <xsl:apply-templates mode="_subst_br" select="@*|node()">
       <xsl:with-param name="ignore" select="$ign"/>
       <xsl:with-param name="crop" select="$crp"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template mode="_subst_br" match="@*">
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template mode="_subst_br" match="text()" name="_subst_br_txt">
   <xsl:param name="inText" select="."/>
   <xsl:param name="ignore"/>
   <xsl:param name="crop"/>
   <xsl:choose>
     <xsl:when test="contains($inText,'&#010;')">
       <xsl:value-of select="substring-before($inText,'&#010;')"/>
       <xsl:variable name="part2" select="substring-after($inText,'&#010;')"/>
       <xsl:choose>
         <xsl:when test="$ignore>0"><xsl:value-of select="$nl"/>
           <xsl:call-template name="_subst_br_txt">
             <xsl:with-param name="inText" select="$part2"/>
             <xsl:with-param name="ignore" select="$ignore -1"/>
             <xsl:with-param name="crop" select="$crop"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:when test="($crop>0) and not(contains($part2,'&#010;'))"><xsl:value-of select="$nl"/>
           <xsl:value-of select="$part2"/>
         </xsl:when>
         <xsl:otherwise><br/><xsl:value-of select="$nl"/>
           <xsl:call-template name="_subst_br_txt">
             <xsl:with-param name="inText" select="$part2"/>
             <xsl:with-param name="crop" select="$crop"/>
           </xsl:call-template>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="$inText"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <func:function name="str:subst-tags">
   <xsl:param name="inNodes"/>
   <xsl:variable name="ret">
     <xsl:apply-templates select="$inNodes" mode="_subst_tag"/>
   </xsl:variable>
   <func:result select="exsl:node-set($ret)"/>
 </func:function>

 <xsl:template mode="_subst_tag" match="@*|node()">
   <xsl:copy>
     <xsl:apply-templates mode="_subst_tag" select="@*|node()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template mode="_subst_tag" match="text()" name="_subst_tag_txt">
   <xsl:param name="inText" select="."/>
   <xsl:choose>
     <xsl:when test="contains($inText,'&lt;')">
       <xsl:value-of select="substring-before($inText,'&lt;')"/>
       <xsl:variable name="part2" select="substring-after($inText,'&lt;')"/>
       <xsl:choose>
         <xsl:when test="contains($part2,'>')">
           <xsl:call-template name="link-tag">
             <xsl:with-param name="inText" select="substring-before($part2,'>')"/>
           </xsl:call-template>
           <xsl:call-template name="_subst_tag_txt">
             <xsl:with-param name="inText" select="substring-after($part2,'>')"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:call-template name="_subst_tag_txt">
             <xsl:with-param name="inText" select="$part2"/>
           </xsl:call-template>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:when>
     <xsl:when test="contains($inText,'§')">
       <xsl:value-of select="substring-before($inText,'§')"/>
       <xsl:variable name="part2" select="substring-after($inText,'§')"/>
       <xsl:choose>
         <xsl:when test="contains($part2,'>')">
           <xsl:call-template name="link-tag">
             <xsl:with-param name="inText" select="substring-before($part2,'>')"/>
           </xsl:call-template>
           <xsl:call-template name="_subst_tag_txt">
             <xsl:with-param name="inText" select="substring-after($part2,'>')"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:call-template name="_subst_tag_txt">
             <xsl:with-param name="inText" select="$part2"/>
           </xsl:call-template>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="$inText"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template name="link-tag"> <!-- kriegt von '<br name="t">' 'br name="t"', erzeugt link und <> -->
   <xsl:param name="inText"/>
   <xsl:choose>
     <xsl:when test="starts-with($inText,'?')">
       <xsl:text/>&lt;<xsl:value-of select="$inText"/>><xsl:text/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:variable name="to1" select="substring-before($inText,' ')"/>
       <xsl:variable name="tag">
         <xsl:choose>
           <xsl:when test="contains($inText,' ') and (string-length($to1) &lt; string-length($inText))">
             <xsl:value-of select="$to1"/>
           </xsl:when>
           <xsl:otherwise><xsl:value-of select="$inText"/></xsl:otherwise>
         </xsl:choose>
       </xsl:variable>
       <xsl:variable name="tagname">
         <xsl:choose>
           <xsl:when test="starts-with($tag,'/')"><xsl:value-of select="substring($tag,2)"/></xsl:when>
           <xsl:when test="substring($tag,string-length($tag),1)='/'">
             <xsl:value-of select="substring($tag,1,string-length($tag)-1)"/>
           </xsl:when>
           <xsl:otherwise><xsl:value-of select="$tag"/></xsl:otherwise>
         </xsl:choose>
       </xsl:variable>
       <xsl:choose>
         <xsl:when test="$root/docu/tag/text()=$tagname"> <!-- other tree's root!!! -->
           <a href="#{$tagname}">&lt;<xsl:value-of select="$inText"/>></a>
         </xsl:when>
         <xsl:otherwise>
           <xsl:text/>&lt;<xsl:value-of select="$inText"/>><xsl:text/>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <func:function name="str:subst-spacer">
   <xsl:param name="inNodes"/>
   <xsl:variable name="ret">
     <xsl:apply-templates select="$inNodes" mode="_subst_sp"/>
   </xsl:variable>
   <func:result select="exsl:node-set($ret)"/>
 </func:function>

 <xsl:template mode="_subst_sp" match="*">
   <xsl:copy>
     <xsl:apply-templates mode="_subst_sp" select="@*|node()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template mode="_subst_sp" match="@*">
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template mode="_subst_sp" match="text()" name="_subst_sp_txt">
   <xsl:param name="inText" select="."/>
   <xsl:choose>
     <xsl:when test="contains($inText,' ')">
       <xsl:value-of select="substring-before($inText,' ')"/>&#160;<xsl:text/>
       <xsl:call-template name="_subst_sp_txt">
         <xsl:with-param name="inText" select="substring-after($inText,' ')"/>
       </xsl:call-template>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="$inText"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

</xsl:stylesheet>
