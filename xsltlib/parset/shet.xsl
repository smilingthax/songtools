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
 <xsl:param name="allowSpecial" select="''"/>

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
     <xsl:apply-templates select="@*[not(name()='special') or $allowSpecial=.]|node()|comment()"/>
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
   <xsl:if test="mine:main_lang(../content/@lang)!=../content/@lang">
     <xsl:message terminate="yes">Title-without-@lang is not allowed for xlang contents.</xsl:message>
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
       <xsl:with-param name="dbg_title" select="../title[1]/text()"/>
     </xsl:apply-templates>
   </xsl:variable>
<!--
   <exsl:document href="/dev/stdout"><xsl:copy-of select="$sn1"/></exsl:document>
-->
   <xsl:copy>
<!--     <xsl:copy-of select="minex:parset(node(),../title[1]/text())|@*"/>-->
<!--     <xsl:copy-of select="minex:parset($sn1,../title[1]/text())|@*"/>-->
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="minex:parset($sn1,../title[1]/text())" mode="_add_akks">
       <xsl:with-param name="level" select="-1"/>
       <xsl:with-param name="no" select="-1"/>
       <xsl:with-param name="debug" select="concat(../title[1]/text(),' (-> ',@lang,')')"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

<!-- <xsl:template match="content//bf">
 </xsl:template>-->

 <xsl:template match="split[@char='&quot;']" mode="_split_token"> <!-- LATER(_add_akks): transformed to <sq/> and <eq/> -->
   <quot/>
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
   <xsl:param name="dbg_title"/>
   <xsl:param name="as"/>
   <xsl:param name="repeated"/>
   <xsl:copy>
     <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
     <xsl:copy-of select="@*"/>
     <xsl:if test="$repeated">
       <xsl:attribute name="repeated"><xsl:value-of select="$repeated"/></xsl:attribute>
     </xsl:if>
     <xsl:choose>
       <xsl:when test="$as">
         <xsl:attribute name="no"><xsl:value-of select="$as"/></xsl:attribute>
       </xsl:when>
       <xsl:otherwise>
         <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::vers|preceding-sibling::showvers[@as]|.)"/></xsl:attribute>
       </xsl:otherwise>
     </xsl:choose>
     <xsl:apply-templates select="node()" mode="_split_token">
       <xsl:with-param name="dbg_title" select="$dbg_title"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/refr" mode="_split_token">
   <xsl:param name="dbg_title"/>
   <xsl:param name="repeated"/>
   <xsl:copy>
     <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::refr|.)"/></xsl:attribute>
     <xsl:if test="$repeated">
       <xsl:attribute name="repeated"><xsl:value-of select="$repeated"/></xsl:attribute>
     </xsl:if>
     <xsl:apply-templates select="@*|node()" mode="_split_token">
       <xsl:with-param name="dbg_title" select="$dbg_title"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/ending" mode="_split_token">
   <xsl:param name="dbg_title"/>
   <xsl:copy>
     <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::ending|.)"/></xsl:attribute>
     <xsl:apply-templates select="@*|node()" mode="_split_token">
       <xsl:with-param name="dbg_title" select="$dbg_title"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/bridge" mode="_split_token">
   <xsl:param name="dbg_title"/>
   <xsl:param name="repeated"/>
   <xsl:copy>
     <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::bridge|.)"/></xsl:attribute>
     <xsl:if test="$repeated">
       <xsl:attribute name="repeated"><xsl:value-of select="$repeated"/></xsl:attribute>
     </xsl:if>
     <xsl:apply-templates select="@*|node()" mode="_split_token">
       <xsl:with-param name="dbg_title" select="$dbg_title"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/showvers" mode="_split_token">
   <xsl:param name="dbg_title"/>
   <xsl:choose>
     <xsl:when test="@no">
       <xsl:apply-templates select="../vers[@no=current()/@no]" mode="_split_token">
         <xsl:with-param name="as" select="@as"/>
         <xsl:with-param name="repeated" select="true()"/>
       </xsl:apply-templates>
     </xsl:when>
     <xsl:otherwise>
       <xsl:apply-templates select="preceding-sibling::vers[1]" mode="_split_token">
         <xsl:with-param name="repeated" select="true()"/>
       </xsl:apply-templates>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="/showrefr" mode="_split_token">
   <xsl:param name="dbg_title"/>
   <xsl:choose>
     <xsl:when test="@no">
       <xsl:apply-templates select="../refr[@no=current()/@no]" mode="_split_token">
         <xsl:with-param name="repeated" select="true()"/>
       </xsl:apply-templates>
     </xsl:when>
     <xsl:otherwise>
       <xsl:apply-templates select="preceding-sibling::refr[1]" mode="_split_token">
         <xsl:with-param name="repeated" select="true()"/>
       </xsl:apply-templates>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="/showbridge" mode="_split_token">
   <xsl:param name="dbg_title"/>
   <xsl:choose>
     <xsl:when test="@no">
       <xsl:apply-templates select="../bridge[@no=current()/@no]" mode="_split_token">
         <xsl:with-param name="repeated" select="true()"/>
       </xsl:apply-templates>
     </xsl:when>
     <xsl:otherwise>
       <xsl:apply-templates select="preceding-sibling::bridge[1]" mode="_split_token">
         <xsl:with-param name="repeated" select="true()"/>
       </xsl:apply-templates>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="pagebreak" mode="_split_token">
   <bf break="-2"/>
 </xsl:template>

 <xsl:template match="*" mode="_split_token">
   <xsl:param name="dbg_title"/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_split_token">
       <xsl:with-param name="dbg_title" select="$dbg_title"/>
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
   <xsl:param name="debug"/>
   <xsl:copy>
     <xsl:if test="not(text()='-')">
       <xsl:attribute name="note">
         <xsl:variable name="note" select="mine:getAkk($level,$no)"/>
         <xsl:if test="not($note)">
           <xsl:message terminate="yes">Fehler[normal,vers,refr,ending,bridge,instrum] in den Akkorden, Lied: <xsl:value-of select="$debug"/></xsl:message>
         </xsl:if>
         <xsl:value-of select="$note"/>
       </xsl:attribute>
     </xsl:if>
     <xsl:value-of select="."/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/base" mode="_add_akks">
   <xsl:param name="debug"/>
   <xsl:call-template name="check-quotes">
     <xsl:with-param name="debug" select="$debug"/>
   </xsl:call-template>
   <xsl:copy>
     <xsl:attribute name="no"><xsl:value-of select="mine:get_no(preceding-sibling::base|.)"/></xsl:attribute>
     <xsl:apply-templates select="@*|node()" mode="_add_akks">
       <xsl:with-param name="level" select="0"/>
       <xsl:with-param name="no" select="0"/>
       <xsl:with-param name="debug" select="$debug"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/vers" mode="_add_akks">
   <xsl:param name="debug"/>
   <xsl:call-template name="check-quotes">
     <xsl:with-param name="debug" select="$debug"/>
   </xsl:call-template>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_add_akks">
       <xsl:with-param name="level" select="1"/>
       <xsl:with-param name="no" select="@no"/>
       <xsl:with-param name="debug" select="$debug"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/refr" mode="_add_akks">
   <xsl:param name="debug"/>
   <xsl:call-template name="check-quotes">
     <xsl:with-param name="debug" select="$debug"/>
   </xsl:call-template>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_add_akks">
       <xsl:with-param name="level" select="2"/>
       <xsl:with-param name="no" select="@no"/>
       <xsl:with-param name="debug" select="$debug"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/ending" mode="_add_akks">
   <xsl:param name="debug"/>
   <xsl:call-template name="check-quotes">
     <xsl:with-param name="debug" select="$debug"/>
   </xsl:call-template>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_add_akks">
       <xsl:with-param name="level" select="3"/>
       <xsl:with-param name="no" select="@no"/>
       <xsl:with-param name="debug" select="$debug"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/bridge" mode="_add_akks">
   <xsl:param name="debug"/>
   <xsl:call-template name="check-quotes">
     <xsl:with-param name="debug" select="$debug"/>
   </xsl:call-template>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_add_akks">
       <xsl:with-param name="level" select="4"/>
       <xsl:with-param name="no" select="@no"/>
       <xsl:with-param name="debug" select="$debug"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="br" mode="_add_akks"> <!-- COMPAT: strips @break=0 as following sheets often just test '@break' -->
   <xsl:copy>
     <xsl:attribute name="no"><xsl:value-of select="@no"/></xsl:attribute>
     <xsl:if test="@break != 0"><xsl:attribute name="break"><xsl:value-of select="@break"/></xsl:attribute></xsl:if>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="/*[last()]/br[last()]" mode="_add_akks"> <!-- set final @no=1 -->
   <!-- NOTE: /[block]/br is enough: we pulled ending <br>s out of inline tags (but always inside block); also: every block ends with a br -->
   <br no="1" break="-3"/> <!-- this also removes a <pagebreak> here -->
 </xsl:template>

 <xsl:template match="quot[ancestor::xlang]" mode="_add_akks">
   <!-- We're not as strict as we could:  we could get the Start-of-Line context and only consider <xlang>s in the same context -->
   <xsl:variable name="prec" select="preceding::node()[ancestor::xlang]"/>
   <xsl:choose>
     <xsl:when test="count($prec[self::quot]) mod 2"><eq/></xsl:when><!-- closing -->
     <xsl:otherwise><sq/></xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="quot" mode="_add_akks">
   <xsl:choose>
     <xsl:when test="count(preceding-sibling::quot) mod 2"><eq/></xsl:when><!-- closing -->
     <xsl:otherwise><sq/></xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="*" mode="_add_akks">
   <xsl:param name="level"/>
   <xsl:param name="no"/>
   <xsl:param name="debug"/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_add_akks">
       <xsl:with-param name="level" select="$level"/>
       <xsl:with-param name="no" select="$no"/>
       <xsl:with-param name="debug" select="$debug"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*|comment()" mode="_add_akks">
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template name="check-quotes">
   <xsl:param name="debug"/>
   <xsl:variable name="quots" select=".//quot[not(ancestor::xlang)]"/>
   <xsl:for-each select="$quots[not(preceding-sibling::quot)]">
     <xsl:if test="count(.|following-sibling::quot) mod 2">
       <xsl:message terminate="yes">Quoting problem (quotes over paragraph boundary?), Lied: <xsl:value-of select="$debug"/></xsl:message>
     </xsl:if>
   </xsl:for-each>
   <xsl:if test="count(.//quot[ancestor::xlang]) mod 2">
     <xsl:message terminate="yes">Quoting in xlang is weird, Lied: <xsl:value-of select="$debug"/></xsl:message>
   </xsl:if>
 </xsl:template>

 <xsl:template match="akks"> <!-- {{{ grab chords -->
   <xsl:choose>
     <xsl:when test="contains(@transpose,',')"><xsl:value-of select="mine:noteAkks(substring-before(@transpose,','))"/></xsl:when>
     <xsl:when test="@transpose"><xsl:value-of select="mine:noteAkks(@transpose)"/></xsl:when>
     <xsl:otherwise><xsl:value-of select="mine:noteAkks()"/></xsl:otherwise>
   </xsl:choose>
   <xsl:apply-templates select="*|text()"/>
 </xsl:template>

 <xsl:template match="akks/*"><!-- don't copy -->
   <xsl:apply-templates select="*|text()"/>
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
 <!-- }}} -->

 <func:function name="mine:get_no"> <!-- {{{ call with 'preceding-sibling::tag|.' -->
   <xsl:param name="prec"/>
   <xsl:variable name="pno" select="$prec[@no or @as][last()]"/>
   <xsl:variable name="add">
     <xsl:choose>
       <xsl:when test="$pno/self::showvers"><xsl:value-of select="$pno/@as"/></xsl:when>
       <xsl:when test="$pno"><xsl:value-of select="$pno/@no"/></xsl:when>
       <xsl:otherwise>0</xsl:otherwise>
     </xsl:choose>
   </xsl:variable>
   <func:result select="count(set:trailing($prec,$pno))+$add"/>
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
