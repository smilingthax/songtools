<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:mine="thax.home/mine-ext-speed"
                xmlns:ec="thax.home/enclose"
                extension-element-prefixes="func mine ec exsl">

 <xsl:output method="xml" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

<!-- TODO: strip out vers/@no, where possible -->
<!-- TODO: generate <showrefr/> -->

 <xsl:strip-space elements="songs-out content"/>
<!-- does reindent! -->

 <xsl:template match="/">
   <songs><xsl:value-of select="$nl"/>
     <xsl:apply-templates select="songs-out/node()"/>
   </songs>
 </xsl:template>

 <xsl:template match="songs-out/comment()">
   <xsl:copy-of select="."/>
   <xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="node()|comment()">
   <xsl:copy><xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()|comment()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="node()|comment()" mode="_songcontent">
   <xsl:message terminate="yes">Unknown node <xsl:value-of select="text()"/><xsl:text>#</xsl:text><xsl:value-of select="name()"/></xsl:message>
 </xsl:template>

 <xsl:template match="song">
   <xsl:copy><xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()|comment()"/>
     <!-- strip all '\n' -->
   </xsl:copy><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="song/content">
   <xsl:copy><xsl:copy-of select="@*"/><xsl:value-of select="$nl"/>
     <xsl:text>    </xsl:text>
     <xsl:apply-templates select="node()|comment()" mode="_songcontent"/>
     <xsl:text>  </xsl:text>
   </xsl:copy>
 </xsl:template>

 <xsl:template name="pullout_br">
   <xsl:variable name="last_br" select="br[last()]"/>
   <xsl:variable name="has_next">
     <xsl:apply-templates select="$last_br/following-sibling::node()" mode="_check_next"/>
   </xsl:variable>
   <xsl:variable name="indent">
     <xsl:if test="following-sibling::node()">
       <xsl:text>    </xsl:text>
     </xsl:if>
   </xsl:variable>
   <xsl:if test="string-length($has_next)=0">
<!--     <xsl:copy-of select="$last_br"/> -->
     <xsl:apply-templates select="$last_br" mode="_songcontent">
       <xsl:with-param name="has_next" select="'x'"/>
       <xsl:with-param name="indent" select="$indent"/>
     </xsl:apply-templates>
   </xsl:if>
 </xsl:template>

 <xsl:template match="base" mode="_songcontent">
   <xsl:apply-templates select="node()|comment()" mode="_songcontent"/>
   <xsl:call-template name="pullout_br"/>
 </xsl:template>

 <xsl:template match="refr|vers|bridge|ending" mode="_songcontent">
   <xsl:copy><xsl:copy-of select="@*"/><xsl:value-of select="$nl"/>
     <xsl:text>    </xsl:text>
     <xsl:apply-templates select="node()|comment()" mode="_songcontent"/>
   </xsl:copy>
   <xsl:call-template name="pullout_br"/>
 </xsl:template>

 <xsl:template match="quote" mode="_songcontent">
   <xsl:text>"</xsl:text>
   <xsl:apply-templates select="node()|comment()" mode="_songcontent"/>
   <xsl:text>"</xsl:text>
 </xsl:template>

 <xsl:template match="text()" mode="_songcontent">
   <xsl:call-template name="nl_hlp"/>
 </xsl:template>

 <xsl:template match="text()" mode="_check_next">
   <xsl:call-template name="nl_hlp"/>
 </xsl:template>
 <xsl:template match="*" mode="_check_next">
   <xsl:text>x</xsl:text>
 </xsl:template>

 <xsl:template match="br" mode="_songcontent">
   <xsl:param name="has_next">
     <xsl:apply-templates select="following-sibling::node()" mode="_check_next"/>
   </xsl:param>
   <xsl:param name="indent"><xsl:text>    </xsl:text></xsl:param>
   <xsl:if test="string-length($has_next)">
     <xsl:choose>
     <xsl:when test="not(@break)"/>
     <xsl:when test="@break=1"></xsl:when>
     <xsl:when test="@break=-2">
       <xsl:value-of select="$nl"/>
       <xsl:text>    </xsl:text><pagebreak/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:message terminate="yes">Unknown break <xsl:value-of select="@break"/></xsl:message>
     </xsl:otherwise>
     </xsl:choose>
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$nl"/>
       <xsl:with-param name="anz" select="@no"/>
     </xsl:call-template>
     <xsl:value-of select="$indent"/>
   </xsl:if>
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
