<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:str="http://exslt.org/strings"
                xmlns:set="http://exslt.org/sets"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:thobi="thax.home/split"
                xmlns:mine="thax.home/mine-ext"
                xmlns:minex="thax.home/parset"
                extension-element-prefixes="str thobi func exsl mine minex set">

 <xsl:output method="xml" encoding="iso-8859-1" indent="no"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:param name="inNodes"/>

 <xsl:include href="split.xsl"/>

 <xsl:template match="/songs">
   <xsl:apply-templates select="*|comment()"/>
 </xsl:template>

 <xsl:template match="/">
   <xsl:choose>
     <xsl:when test="$inNodes">
       <xsl:apply-templates select="$inNodes"/>
     </xsl:when>
     <xsl:otherwise>
       <songs-out>
         <xsl:apply-templates select="*"/>
       </songs-out>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>
  
 <xsl:template match="@*|node()|comment()">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="song">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()"/>
   </xsl:copy>
   <xsl:if test="not(mine:checkAkks())">
     <xsl:message terminate="yes">Fehler[normal,vers,refr,ending,bridge,instrum] in den Akkorden, Lied: <xsl:value-of select="title[1]/text()"/></xsl:message>
   </xsl:if>
 </xsl:template>
 
 <xsl:template match="song/song"><!-- TODO: should be DTD -->
   <xsl:message terminate="yes">Song tag enclosed in song tag.</xsl:message>
 </xsl:template>
 
 <xsl:template match="song/title[not(@lang)]">
   <xsl:if test="count(../content/@lang)!=1">
     <xsl:message terminate="yes">The language for title "<xsl:value-of select="text()"/>" is not uniquely defined (compare with &lt;content&gt;!)</xsl:message>
   </xsl:if>
   <xsl:copy>
     <xsl:attribute name="lang">
       <xsl:value-of select="../content/@lang"/>
     </xsl:attribute>
     <xsl:copy-of select="@*|node()|comment()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="song/text()">
<!--   <xsl:if test="preceding-sibling::node()[1][not(self::title)] or following-sibling::node()[1][self::content|self::title]">-->
   <xsl:if test="not(preceding-sibling::node()[1][self::akks])">
     <xsl:value-of select="."/>
   </xsl:if>
 </xsl:template>

 <xsl:template match="content">
   <xsl:variable name="apos" select='"&apos;"'/>
   <xsl:variable name="sn1">
     <xsl:apply-templates select="thobi:septree(node(),concat('|&#010;*&quot;^\',$apos))" mode="_split_token">
       <xsl:with-param name="wo" select="../title[1]/text()"/>
     </xsl:apply-templates>
   </xsl:variable>
<!--   <exsl:document href="/dev/stdout"><xsl:copy-of select="$sn1"/></exsl:document>-->
   <xsl:copy>
<!--     <xsl:copy-of select="minex:parset(node(),../title[1]/text())|@*"/>-->
<!--     <xsl:copy-of select="minex:parset($sn1,../title[1]/text())|@*"/>-->
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="minex:parset($sn1,../title[1]/text())" mode="_add_akks">
       <xsl:with-param name="level" select="0"/>
       <xsl:with-param name="no" select="0"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

<!-- <xsl:template match="content//bf">
 </xsl:template>-->

 <xsl:template match="split[@char='&quot;']" mode="_split_token">
   <quot>
     <xsl:attribute name="no"><xsl:value-of select="count(preceding-sibling::split[@char='&quot;'])"/></xsl:attribute>
   </quot>
 </xsl:template>
 
 <xsl:template match="split[@char='|']" mode="_split_token"> <!-- LATER: get following char -->
   <akk/>
 </xsl:template>

 <xsl:template match="split[@char='*']" mode="_split_token">
   <spacer/> <!-- LATER: @no -->
 </xsl:template>

 <xsl:template match="split[@char='&#010;']" mode="_split_token">
   <br/><xsl:value-of select="@char"/>
 </xsl:template>

 <!-- TRICK ; for now: '\' will be ignored TODO: why? --> 
 <xsl:template match="split[@char='\']" mode="_split_token"/>

 <xsl:template match="split[@char='^']" mode="_split_token">
   <xlang/>
 </xsl:template>

 <xsl:template match='split[@char="&apos;"]' mode="_split_token">
   <tick/>
 </xsl:template>

 <xsl:template match="split" mode="_split_token">
   <xsl:value-of select="."/>
 </xsl:template>

 <xsl:template match="/vers" mode="_split_token">
   <xsl:param name="wo"/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::vers|.)"/></xsl:attribute>
     <xsl:apply-templates select="node()" mode="_split_token">
       <xsl:with-param name="wo" select="$wo"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/refr" mode="_split_token">
   <xsl:param name="wo"/>
   <xsl:copy>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::refr|.)"/></xsl:attribute>
     <xsl:apply-templates select="@*|node()" mode="_split_token">
       <xsl:with-param name="wo" select="$wo"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/ending" mode="_split_token">
   <xsl:param name="wo"/>
   <xsl:copy>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::ending|.)"/></xsl:attribute>
     <xsl:apply-templates select="@*|node()" mode="_split_token">
       <xsl:with-param name="wo" select="$wo"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/bridge" mode="_split_token">
   <xsl:param name="wo"/>
   <xsl:copy>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::bridge|.)"/></xsl:attribute>
     <xsl:apply-templates select="@*|node()" mode="_split_token">
       <xsl:with-param name="wo" select="$wo"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/showrefr" mode="_split_token">
   <xsl:param name="wo"/>
   <xsl:choose>
     <xsl:when test="@no">
       <xsl:apply-templates select="../refr[@no=current()/@no]" mode="_split_token"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:apply-templates select="preceding-sibling::refr[1]" mode="_split_token"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>
 
 <xsl:template match="/showbridge" mode="_split_token">
   <xsl:param name="wo"/>
   <xsl:choose>
     <xsl:when test="@no">
       <xsl:apply-templates select="../bridge[@no=current()/@no]" mode="_split_token"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:apply-templates select="preceding-sibling::bridge[1]" mode="_split_token"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="pagebreak" mode="_split_token">
   <bf break="-2"/>
 </xsl:template>

 <xsl:template match="*" mode="_split_token">
   <xsl:param name="wo"/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_split_token">
       <xsl:with-param name="wo" select="$wo"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*|comment()" mode="_split_token">
   <!-- copy @* for now. maybe we can just discard it. but we can't let the default rule convert it to text ... --> 
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template match="akk" mode="_add_akks">
   <xsl:param name="level"/>
   <xsl:param name="no"/>
   <xsl:copy>
     <xsl:if test="not(text()='-')">
       <xsl:attribute name="note"><xsl:value-of select="mine:getAkk($level,$no)"/></xsl:attribute>
     </xsl:if>
     <xsl:copy-of select="@*|node()"/>
   </xsl:copy>
 </xsl:template>
 
 <xsl:template match="/vers" mode="_add_akks">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_add_akks">
       <xsl:with-param name="level" select="1"/>
       <xsl:with-param name="no" select="@no"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>
 
 <xsl:template match="/refr" mode="_add_akks">
   <xsl:copy>
        <xsl:copy-of select="@*[name()!='no']"/>
<!--     <xsl:apply-templates select="@*|node()" mode="_add_akks"> -->
                         <xsl:apply-templates select="node()" mode="_add_akks">  <!-- COMPAT -->
       <xsl:with-param name="level" select="2"/>
       <xsl:with-param name="no" select="@no"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>
 
 <xsl:template match="/ending" mode="_add_akks">
   <xsl:copy>
        <xsl:copy-of select="@*[name()!='no']"/>
<!--     <xsl:apply-templates select="@*|node()" mode="_add_akks"> -->
                         <xsl:apply-templates select="node()" mode="_add_akks">  <!-- COMPAT -->
       <xsl:with-param name="level" select="3"/>
       <xsl:with-param name="no" select="@no"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/bridge" mode="_add_akks">
   <xsl:copy>
        <xsl:copy-of select="@*[name()!='no']"/>
<!--     <xsl:apply-templates select="@*|node()" mode="_add_akks"> -->
                         <xsl:apply-templates select="node()" mode="_add_akks">  <!-- COMPAT -->
       <xsl:with-param name="level" select="4"/>
       <xsl:with-param name="no" select="@no"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

        <xsl:template match="br" mode="_add_akks"> <!-- COMPAT -->
          <xsl:copy>
            <xsl:attribute name="no"><xsl:value-of select="@no"/></xsl:attribute>
            <xsl:if test="@break != 0"><xsl:attribute name="break"><xsl:value-of select="@break"/></xsl:attribute></xsl:if>
          </xsl:copy>
        </xsl:template>

 <xsl:template match="*" mode="_add_akks">
   <xsl:param name="level"/>
   <xsl:param name="no"/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_add_akks">
       <xsl:with-param name="level" select="$level"/>
       <xsl:with-param name="no" select="$no"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*|comment()" mode="_add_akks">
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template match="akks">
   <xsl:choose>
     <xsl:when test="@transpose"><xsl:value-of select="mine:noteAkks(@transpose)"/></xsl:when>
     <xsl:otherwise><xsl:value-of select="mine:noteAkks()"/></xsl:otherwise>
   </xsl:choose>
   <xsl:apply-templates select="node()"/>
 </xsl:template>

 <xsl:template match="akks/*"><!-- don't copy -->
   <xsl:apply-templates select="node()"/>
 </xsl:template>

 <xsl:template match="akks//text()|akks/base//text()">
   <xsl:call-template name="grab-akks">
     <xsl:with-param name="inText" select="."/>
     <xsl:with-param name="level" select="0"/>
     <xsl:with-param name="no" select="0"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="akks/vers//text()">
   <xsl:call-template name="grab-akks">
     <xsl:with-param name="inText" select="."/>
     <xsl:with-param name="level" select="1"/>
     <xsl:with-param name="no" select="mine:get_no(ancestor::vers/preceding-sibling::vers|ancestor::vers)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="akks/refr//text()">
   <xsl:call-template name="grab-akks">
     <xsl:with-param name="inText" select="."/>
     <xsl:with-param name="level" select="2"/>
     <xsl:with-param name="no" select="mine:get_no(ancestor::refr/preceding-sibling::refr|ancestor::refr)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="akks/ending//text()">
   <xsl:call-template name="grab-akks">
     <xsl:with-param name="inText" select="."/>
     <xsl:with-param name="level" select="3"/>
     <xsl:with-param name="no" select="mine:get_no(ancestor::ending/preceding-sibling::ending|ancestor::ending)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="akks/bridge//text()">
   <xsl:call-template name="grab-akks">
     <xsl:with-param name="inText" select="."/>
     <xsl:with-param name="level" select="4"/>
     <xsl:with-param name="no" select="mine:get_no(ancestor::bridge/preceding-sibling::bridge|ancestor::bridge)"/>
   </xsl:call-template>
 </xsl:template>
 
 <xsl:template match="akks/instrum//text()">
   <xsl:call-template name="grab-akks">
     <xsl:with-param name="inText" select="."/>
     <xsl:with-param name="level" select="5"/>
     <xsl:with-param name="no" select="mine:get_no(ancestor::instrum/preceding-sibling::instrum|ancestor::instrum)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template name="grab-akks">
   <xsl:param name="inText"/>
   <xsl:param name="level"/>
   <xsl:param name="no"/>
   <xsl:apply-templates mode="_grabakk" select="str:tokenize(normalize-space($inText))">
     <xsl:with-param name="level" select="$level"/>
     <xsl:with-param name="no" select="$no"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="token/text()" mode="_grabakk">
   <xsl:param name="level"/>
   <xsl:param name="no"/>
   <xsl:value-of select="mine:grabAkk($level,$no,.)"/>
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
