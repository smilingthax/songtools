<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                xmlns:str="http://exslt.org/strings"
                xmlns:set="http://exslt.org/sets"
                extension-element-prefixes="exsl str set">

 <xsl:import href="lang-db.xsl"/>

 <xsl:variable name="rightsdb" select="document('verlage.xml')"/>
 <xsl:key name="verlag" match="verlag" use="@name"/>
 <xsl:key name="subverlag" match="subverlag" use="@verlag"/>
 <!-- TODO? output only those subverlage where @for contains 'D' (Problem e.g. 'Europe') [to do in output plugin?] -->

 <!-- rights-template {{{ -->
 <!-- converts all <rights|rights-full @no @for>-tags from >inNodes into appropriate <rights @no><*-full @for></rights>-trees.
      >verbose controls debug output -->
 <xsl:template name="rights">
   <xsl:param name="inNodes" select="."/>
   <xsl:param name="verbose" select="0"/>
   <xsl:apply-templates select="$inNodes" mode="_do_rights">
     <xsl:with-param name="verbose" select="$verbose"/>
   </xsl:apply-templates>
 </xsl:template>

 <!-- the '<rights><text year="1992,1993">adsf</text><melody>bla</melody></rights>' case -->
 <xsl:template match="rights[*]" mode="_do_rights">
   <xsl:param name="verbose"/>
   <xsl:copy>
     <xsl:if test="@no"><xsl:attribute name="no"><xsl:value-of select="@no"/></xsl:attribute></xsl:if>
     <xsl:apply-templates match="*" mode="_do_one_rights">
       <xsl:with-param name="title" select="../title[1]/text()"/>
       <xsl:with-param name="for" select="@for"/>
       <xsl:with-param name="verbose" select="$verbose"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <!-- the '<rights>123 text</rights>' case -->
 <xsl:template match="rights" mode="_do_rights">
   <xsl:param name="verbose"/>
   <xsl:variable name="title" select="../title[1]/text()"/>
   <!-- split off year -->
   <xsl:variable name="num-ident-hlp">
     <xsl:apply-templates select="str:tokenize(.,' ')" mode="_rights_num_ident"/>
   </xsl:variable>
   <xsl:variable name="num-ident" select="exsl:node-set($num-ident-hlp)"/>
   <xsl:if test="$num-ident/token[@number and preceding-sibling::token]">
     <xsl:message terminate="yes">In song "<xsl:value-of select="$title"/>": numbers must not be space seperated and occur first</xsl:message>
   </xsl:if>
   <xsl:variable name="all-but-number">
     <xsl:choose>
       <xsl:when test="$num-ident/token[@number]">
         <xsl:value-of select="substring-after(.,' ')"/>
       </xsl:when>
       <xsl:otherwise>
         <xsl:value-of select="."/>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:variable>
   <xsl:variable name="parsedNodes">
     <common>
       <xsl:if test="$num-ident/token[@number]"><!-- just number -->
         <xsl:attribute name="year"><xsl:value-of select="substring-before(.,' ')"/></xsl:attribute>
       </xsl:if>
       <xsl:value-of select="$all-but-number"/>
     </common>
   </xsl:variable>
   <xsl:copy>
     <xsl:if test="@no"><xsl:attribute name="no"><xsl:value-of select="@no"/></xsl:attribute></xsl:if>
     <xsl:apply-templates select="exsl:node-set($parsedNodes)" mode="_do_one_rights">
       <xsl:with-param name="title" select="$title"/>
       <xsl:with-param name="for" select="@for"/>
       <xsl:with-param name="verbose" select="$verbose"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="rights-full" mode="_do_rights">
   <xsl:variable name="title" select="../title[1]/text()"/>
   <xsl:message>rights-full is obsolete ("<xsl:value-of select="$title"/>")</xsl:message>
   <rights><common-full><xsl:value-of select="."/></common-full></rights>
 </xsl:template>

 <xsl:template match="text-full|melody-full|arrangement-full|common-full" mode="_do_one_rights">
   <xsl:param name="title"/>
   <xsl:param name="for"/>
   <xsl:param name="verbose"/>
   <xsl:copy>
     <xsl:choose>
       <xsl:when test="@for"><xsl:attribute name="for"><xsl:value-of select="@for"/></xsl:attribute></xsl:when>
       <xsl:when test="$for"><xsl:attribute name="for"><xsl:value-of select="$for"/></xsl:attribute></xsl:when>
     </xsl:choose>
     <xsl:if test="*">
       <xsl:message terminate="yes"><xsl:value-of select="name(.)"/> must not contain sub-tags ("<xsl:value-of select="$title"/>")</xsl:message>
     </xsl:if>
     <xsl:value-of select="."/>
   </xsl:copy>
 </xsl:template>

 <!-- here we call the verlag-substitution -->
 <xsl:template match="text|melody|arrangement|common" mode="_do_one_rights">
   <xsl:param name="title"/>
   <xsl:param name="for"/>
   <xsl:param name="verbose"/>
   <xsl:variable name="full-name" select="concat(name(.),'-full')"/>
   <xsl:variable name="outNodes-hlp">
     <xsl:apply-templates select="str:split(.,' / ')" mode="_rights">
       <xsl:with-param name="title" select="$title"/>
     </xsl:apply-templates>
   </xsl:variable>
   <xsl:variable name="outNodes" select="exsl:node-set($outNodes-hlp)"/>
<!--<exsl:document href="/dev/stderr" omit-xml-declaration="yes"><xsl:value-of select="$title"/>{<xsl:copy-of select="$outNodes"/>}</exsl:document>-->
   <!-- check for <has-verlag>, output user message for <no-verlag> -->
   <xsl:if test="$outNodes/no-verlag and $verbose">
     <xsl:message>Song "<xsl:value-of select="$title"/>" (<xsl:value-of select="name(.)"/>):</xsl:message>
     <xsl:for-each select="$outNodes/no-verlag">
       <xsl:message>  Verlag "<xsl:value-of select="@name"/>" unknown</xsl:message>
     </xsl:for-each>
   </xsl:if>
   <xsl:if test="not($outNodes/has-verlag) and string-length(.)">
     <xsl:message terminate="yes">Song "<xsl:value-of select="$title"/>" has only unknown verlage in rights(<xsl:value-of select="name(.)"/>)-tag</xsl:message>
   </xsl:if>
   <!-- split subverlage and verlage (if not already handling a subverlag entry) -->
   <xsl:if test="(@for or $for) and $outNodes/has-verlag/subverlag">
     <xsl:message terminate="yes">Song "<xsl:value-of select="$title"/>" has subverlag entry which also has a subverlag</xsl:message>
   </xsl:if>
   <xsl:element name="{$full-name}"><!-- base entry -->
     <xsl:choose>
       <xsl:when test="@for"><xsl:attribute name="for"><xsl:value-of select="@for"/></xsl:attribute></xsl:when>
       <xsl:when test="$for"><xsl:attribute name="for"><xsl:value-of select="$for"/></xsl:attribute></xsl:when>
     </xsl:choose>
     <xsl:if test="@year">
       <xsl:value-of select="@year"/><xsl:text> </xsl:text>
     </xsl:if>
     <xsl:apply-templates select="$outNodes" mode="_combine_verlage"/>
   </xsl:element>
   <xsl:for-each select="$outNodes/has-verlag/subverlag"><!-- subverlag entrys -->
     <xsl:element name="{$full-name}">
       <xsl:attribute name="for"><xsl:value-of select="@for"/></xsl:attribute>
       <xsl:value-of select="text()"/>
     </xsl:element>
   </xsl:for-each>
 </xsl:template>

 <xsl:template match="has-verlag|no-verlag" mode="_combine_verlage">
   <xsl:if test="preceding-sibling::*">
     <xsl:text> / </xsl:text>
   </xsl:if>
   <xsl:value-of select="text()"/>
 </xsl:template>

 <!-- used to substitute rights: "<token>xy Publishing</token><token>Hänssler</token>": substitute verlage, add subverlage -->
 <xsl:template match="token" mode="_rights">
   <xsl:param name="title"/>
   <xsl:variable name="inString" select="."/>
   <!-- do database lookup -->
   <xsl:for-each select="$rightsdb"><!-- only change context -->
     <xsl:variable name="verlag" select="key('verlag',$inString)"/>
     <xsl:choose>
       <xsl:when test="count($verlag)>1">
         <xsl:message terminate="yes">Verlag "<xsl:value-of select="$inString"/>" has more than one entry</xsl:message>
       </xsl:when>
       <xsl:when test="$verlag">
         <has-verlag name="{$inString}"><xsl:value-of select="$verlag/text()"/>
           <xsl:if test="not($verlag/text())"><xsl:value-of select="$inString"/></xsl:if>
           <xsl:variable name="subverlag" select="key('subverlag',$inString)"/>
           <xsl:for-each select="$subverlag">
             <xsl:variable name="current-subverlag" select="."/>
             <xsl:for-each select="$rightsdb">
               <xsl:variable name="subverlag-full" select="key('verlag',$current-subverlag/text())"/>
               <xsl:if test="not($subverlag-full)">
                 <xsl:message terminate="yes">Subverlag entry "<xsl:value-of select="$inString"/>" points to unknown verlag "<xsl:value-of select="$current-subverlag/text()"/>"</xsl:message>
               </xsl:if>
               <xsl:if test="not($current-subverlag/@for)">
                 <xsl:message terminate="yes">Subverlag entry "<xsl:value-of select="$inString"/>" without @for</xsl:message>
               </xsl:if>
               <subverlag for="{$current-subverlag/@for}"><xsl:value-of select="$subverlag-full/text()"/></subverlag>
             </xsl:for-each>
           </xsl:for-each>
         </has-verlag>
       </xsl:when>
       <xsl:otherwise>
         <no-verlag name="{$inString}"><xsl:value-of select="$inString"/></no-verlag>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:for-each>
 </xsl:template>

 <xsl:template match="token" mode="_rights_num_ident">
   <xsl:copy>
     <xsl:if test="count(str:tokenize(.,'0123456789,'))=0"><!-- no other character present -->
       <xsl:attribute name="number">1</xsl:attribute>
     </xsl:if>
   </xsl:copy>
 </xsl:template>
 <!-- }}} -->

 <!-- copyright-template {{{ -->
 <!-- returns a string that contains the complete copyright and text/music-authorship information for
      the song >inSong and Language $lang (all, if not given) -->
 <xsl:template name="copyright">
   <xsl:param name="inSong" select="."/>
   <xsl:param name="lang"/>
   <xsl:param name="withArrangement"/>
   <xsl:for-each select="$inSong"><!-- ensure context -->
     <xsl:variable name="check_lang"><!-- just to look up if language exists -->
       <xsl:if test="not(content/@lang)">
         <xsl:message terminate="yes">Song "<xsl:value-of select="title[1]"/>" has content without language</xsl:message>
       </xsl:if>
       <xsl:for-each select="content/@lang">
<!--         <xsl:for-each select="str:split(.,',')">-->
         <xsl:for-each select="str:tokenize(.,'+,')">
           <xsl:call-template name="full-lang">
             <xsl:with-param name="lang" select="."/>
           </xsl:call-template>
         </xsl:for-each>
       </xsl:for-each>
     </xsl:variable>
     <xsl:variable name="right-hlp">
       <xsl:call-template name="rights">
         <xsl:with-param name="inNodes" select="rights|rights-full"/>
         <xsl:with-param name="verbose" select="0"/>
       </xsl:call-template>
     </xsl:variable>
     <xsl:variable name="right" select="exsl:node-set($right-hlp)"/>
     <!-- TODO? check format of $right: <rights @no><*-full @for>text</*-full>*</rights> -->
     <xsl:variable name="right-subset"><!-- sort by @no; use last, if multiple tags -->
       <xsl:call-template name="collapse_rights">
         <xsl:with-param name="inRights" select="$right/rights[not(@no)][last()]"/>
         <xsl:with-param name="withArrangement" select="$withArrangement"/>
       </xsl:call-template>
       <xsl:for-each select="$right/rights/@no">
         <xsl:call-template name="collapse_rights">
           <xsl:with-param name="inRights" select="$right/rights[@no=current()][last()]"/>
           <xsl:with-param name="withArrangement" select="$withArrangement"/>
         </xsl:call-template>
       </xsl:for-each>
     </xsl:variable>
     <xsl:variable name="txtmusic-hlp">
       <xsl:choose>
         <xsl:when test="$lang">
           <xsl:call-template name="generate_text_music">
             <xsl:with-param name="inSong" select="."/>
             <xsl:with-param name="lang" select="$lang"/>
             <xsl:with-param name="withArrangement" select="$withArrangement"/>
           </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
           <xsl:call-template name="generate_text_music">
             <xsl:with-param name="inSong" select="."/>
             <xsl:with-param name="withArrangement" select="$withArrangement"/>
           </xsl:call-template>
           <!--
           <xsl:variable name="theSong" select="."/>
           <xsl:for-each select="content/@lang">
             <xsl:call-template name="generate_text_music">
               <xsl:with-param name="inSong" select="$theSong"/>
               <xsl:with-param name="lang" select="."/>
               <xsl:with-param name="withArrangement" select="$withArrangement"/>
             </xsl:call-template>
           </xsl:for-each>
           -->
         </xsl:otherwise>
       </xsl:choose>
     </xsl:variable>
     <xsl:variable name="txtmusic" select="exsl:node-set($txtmusic-hlp)/text-music[token/text()]"/>
     <xsl:if test="author"><!-- compatibility option -->
       <xsl:choose>
         <xsl:when test="$lang and author[@lang=$lang]">
           <xsl:value-of select="author[not(@lang)]/text()"/>
           <xsl:text>, </xsl:text><xsl:value-of select="$lang"/><xsl:text>:</xsl:text>
           <xsl:value-of select="author[@lang=$lang]/text()"/>
         </xsl:when>
         <xsl:otherwise>
           <xsl:value-of select="author/text()"/>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:if>
     <xsl:for-each select="exsl:node-set($right-subset)/rights">
       <xsl:value-of select="."/>
       <xsl:if test="following-sibling::*">
         <xsl:text>; </xsl:text>
       </xsl:if>
     </xsl:for-each>
     <xsl:choose>
       <xsl:when test="$lang and $txtmusic[@lang=$lang]">
         <xsl:text> (</xsl:text>
         <xsl:apply-templates select="$txtmusic[@lang=$lang]" mode="_token_concat"/>
         <xsl:text>)</xsl:text>
       </xsl:when>
       <xsl:when test="not($lang)">
         <xsl:for-each select="$txtmusic">
           <xsl:text> (</xsl:text>
           <xsl:apply-templates select="." mode="_token_concat"/>
           <xsl:text>)</xsl:text>
         </xsl:for-each>
       </xsl:when>
     </xsl:choose>
   </xsl:for-each>
 </xsl:template>

 <!-- generates for >inSong (from the text-by and melody-by -Tags) the "Text: xy, Melodie: yz, Deutsch: vw" string
      when >lang is set, and it is not equal to the Original language a "Originaltitel: asd" is also generated.
 -->
 <xsl:template name="generate_text_music">
   <xsl:param name="inSong"/>
   <xsl:param name="lang"/>
   <xsl:param name="withArrangement"/>
   <text-music>
     <xsl:if test="$lang"><xsl:attribute name="lang"><xsl:value-of select="$lang"/></xsl:attribute></xsl:if>
     <xsl:for-each select="$inSong"><!-- ensure context -->
       <xsl:variable name="text_is_melody" select="text-by/text() = melody-by/text()"/>
       <xsl:variable name="melody_is_arrangement" select="melody-by/text() = arrangement-by/text() and $withArrangement"/>
       <xsl:variable name="is_all_three" select="$text_is_melody and $melody_is_arrangement"/>
       <xsl:if test="text-by[not(@lang)]/text()">
         <token>
           <xsl:choose>
             <xsl:when test="$is_all_three">
               <xsl:text>Text, Melodie und Satz: </xsl:text>
             </xsl:when>
             <xsl:when test="$text_is_melody">
               <xsl:text>Text und Melodie: </xsl:text>
             </xsl:when>
             <xsl:otherwise>
               <xsl:text>Text: </xsl:text>
             </xsl:otherwise>
           </xsl:choose>
           <xsl:value-of select="text-by[not(@lang)]/text()"/>
         </token>
         <xsl:variable name="orig-lang-hlp">
           <xsl:for-each select="title/@lang">
             <xsl:if test="not($inSong/text-by[@lang=current()])">
               <lang><xsl:value-of select="."/></lang>
             </xsl:if>
           </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="orig-lang" select="exsl:node-set($orig-lang-hlp)/lang"/>
         <xsl:if test="$orig-lang[text()!=$orig-lang[1]/text()]">
           <xsl:message terminate="yes">Song "<xsl:value-of select="title[1]"/>" does not uniquely define orignal language of song</xsl:message>
         </xsl:if>
         <xsl:if test="( (not($lang) and text-by[@lang]) or ($lang and text-by[@lang=$lang]) ) and $orig-lang">
<!--           <xsl:text>, Originaltitel(</xsl:text><xsl:value-of select="$orig-lang[1]/text()"/><xsl:text>): '</xsl:text>-->
           <tokensep>, </tokensep>
           <token>Originaltitel: '<xsl:value-of select="title[@lang=$orig-lang[1]/text()]"/>'</token>
         </xsl:if>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="melody-by/text() and not($is_all_three) and not($text_is_melody)">
         <token>
           <xsl:choose>
             <xsl:when test="$melody_is_arrangement">
               <xsl:text>Melodie und Satz: </xsl:text>
             </xsl:when>
             <xsl:otherwise>
               <xsl:text>Melodie: </xsl:text>
             </xsl:otherwise>
           </xsl:choose>
           <xsl:value-of select="melody-by/text()"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="arrangement-by/text() and $withArrangement and not($melody_is_arrangement)">
         <token>
           <xsl:text>Satz: </xsl:text>
           <xsl:value-of select="arrangement-by/text()"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:choose>
         <xsl:when test="$lang and text-by[@lang=$lang]/text()">
           <token>
             <xsl:call-template name="full-lang">
               <xsl:with-param name="lang" select="$lang"/>
             </xsl:call-template>
             <xsl:text>: </xsl:text>
             <xsl:value-of select="text-by[@lang=$lang]"/>
           </token>
         </xsl:when>
         <xsl:when test="not($lang) and text-by[@lang]/text()">
           <xsl:for-each select="text-by/@lang">
             <token>
               <xsl:call-template name="full-lang">
                 <xsl:with-param name="lang" select="."/>
               </xsl:call-template>
               <xsl:text>: </xsl:text>
               <xsl:value-of select="$inSong/text-by[@lang=current()]"/>
             </token>
             <tokensep>, </tokensep>
           </xsl:for-each>
         </xsl:when>
       </xsl:choose>
     </xsl:for-each>
   </text-music>
 </xsl:template>

 <xsl:template name="collapse_rights">
   <xsl:param name="inRights"/>
   <xsl:param name="withArrangement"/>
   <xsl:variable name="tokens">
     <xsl:for-each select="$inRights"><!-- ensure context -->
       <xsl:if test="common-full[not(@for)]">
         <token>
           <xsl:value-of select="common-full[not(@for)][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="text-full[not(@for)]">
         <token>
           <xsl:text>(Text:) </xsl:text>
           <xsl:value-of select="text-full[not(@for)][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="melody-full[not(@for)]">
         <token>
           <xsl:text>(Melodie:) </xsl:text>
           <xsl:value-of select="melody-full[not(@for)][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="arrangement-full[not(@for)] and $withArrangement">
         <token>
           <xsl:text>(Satz:) </xsl:text>
           <xsl:value-of select="arrangement-full[not(@for)][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>

       <xsl:if test="common-full[@for]">
         <token>
           <xsl:text>Für </xsl:text><xsl:value-of select="common-full[@for][last()]/@for"/><xsl:text>: </xsl:text>
           <xsl:value-of select="common-full[@for][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="text-full[@for]">
         <token>
           <xsl:text>Für </xsl:text><xsl:value-of select="text-full[@for][last()]/@for"/><xsl:text> (Text): </xsl:text>
           <xsl:value-of select="text-full[@for][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="melody-full[@for]">
         <token>
           <xsl:text>Für </xsl:text><xsl:value-of select="melody-full[@for][last()]/@for"/><xsl:text> (Melodie): </xsl:text>
           <xsl:value-of select="melody-full[@for][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
       <xsl:if test="arrangement-full[@for] and $withArrangement">
         <token>
           <xsl:text>Für </xsl:text><xsl:value-of select="arrangement-full[@for][last()]/@for"/><xsl:text> (Satz): </xsl:text>
           <xsl:value-of select="arrangement-full[@for][last()]"/>
         </token>
         <tokensep>, </tokensep>
       </xsl:if>
     </xsl:for-each>
   </xsl:variable>
   <rights><xsl:apply-templates select="exsl:node-set($tokens)" mode="_token_concat"/></rights>
 </xsl:template>

 <xsl:template match="tokensep" mode="_token_concat"/>
 <xsl:template match="token" mode="_token_concat">
   <xsl:if test="preceding-sibling::token">
     <xsl:value-of select="set:trailing(preceding-sibling::*,preceding-sibling::token[1])/self::tokensep[last()]"/>
   </xsl:if>
   <xsl:value-of select="."/>
 </xsl:template>
 <!-- }}} -->

</xsl:stylesheet>
