<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:set="http://exslt.org/sets"
                xmlns:mine="thax.home/mine-ext-speed"
                xmlns:ec="thax.home/enclose"
                xmlns:thobi="thax.home/split"
                extension-element-prefixes="exsl func set mine ec thobi">

 <!-- customize by overriding the templates.
      requires a template called "error_trap".
 -->

 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <!-- to ease testing: -->
 <xsl:template match="song/node()"/>
 <xsl:template match="song/content"><xsl:call-template name="songcontent"/></xsl:template>

 <xsl:template name="songcontent">
   <xsl:variable name="config">
     <base/>
     <vers>
       <first><num fmt="#"/><xsl:text>. </xsl:text></first>
       <indent><xsl:text>   </xsl:text></indent>
     </vers>
     <refr>
       <first><xsl:text>Refr: </xsl:text></first>
       <indent><xsl:text>      </xsl:text></indent>
     </refr>
     <bridge>
       <first><xsl:text>Bridge: </xsl:text></first>
       <indent><xsl:text>        </xsl:text></indent>
     </bridge>
     <ending>
       <first><xsl:text>Schluss: </xsl:text></first>
       <indent><xsl:text>         </xsl:text></indent>
     </ending>
     <quotes start="&#x201c;" end="&#x201d;"/>
     <quotes lang="de" start="&#x201e;" end="&#x201c;"/>
     <tick><xsl:text>&#x2019;</xsl:text></tick>
     <rep>
       <start>|: </start>
       <simpleend> :|</simpleend>
       <end> :|&#160;(<num fmt="#"/>x)</end>
       <indent><xsl:text>   </xsl:text></indent>
     </rep>
   </xsl:variable>
   <xsl:variable name="inNodes">
     <xsl:apply-templates select="*" mode="_songcontent">
       <xsl:with-param name="ctxt" select="exsl:node-set($config)|."/>
     </xsl:apply-templates>
   </xsl:variable>
   <xsl:apply-templates select="exsl:node-set($inNodes)/*" mode="_sc_post">
     <xsl:with-param name="ctxt" select="exsl:node-set($config)|."/>
   </xsl:apply-templates>
<!--
   <xsl:copy-of select="$inNodes"/>
-->
 </xsl:template>

 <!-- NOTE: handle inline elements which are absolutely positioned in first pass,
            those that are relativ to e.g. first lgroup-line (block,rep) in second pass (_sc_post) -->

 <!-- {{{ songcontent postprocessing: _sc_post -->
 <xsl:template match="/block" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:variable name="this" select="$ctxt/*[name()=current()/@type]"/>
   <xsl:variable name="newbi">
     <block>
       <xsl:copy-of select="@*"/> <!-- debug -->
       <xsl:apply-templates select="$this/first" mode="_do_number">
         <xsl:with-param name="num" select="@no"/>
       </xsl:apply-templates>
       <xsl:copy-of select="$this/indent"/>  <!-- select="func:strip-root($this/indent)"/> -->
     </block>
   </xsl:variable>
<!--
<xsl:copy-of select="$newbi"/>
<xsl:copy-of select="."/>
-->
   <xsl:copy-of select="$this/pre/node()"/>
   <xsl:apply-templates select="*" mode="_sc_post">
     <xsl:with-param name="ctxt" select="$ctxt|exsl:node-set($newbi)"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="/block/lgroup" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:apply-templates select="line" mode="_sc_post">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="repindent" select="sum(preceding-sibling::*/@rep) + @solrep"/> <!-- always has @solrep! -->
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="line" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:param name="solrep" select="@solrep|exsl:node-set(0)[not(current()/@solrep)]"/> <!-- @solrep not always present; TRICK: variable not allowed here... -->
   <xsl:param name="repindent" select="sum(preceding-sibling::*/@rep) + $solrep"/>
   <xsl:variable name="justxlang" select="not(../line[not(@xlang)])"/>

   <xsl:choose>
     <xsl:when test="@firstpos and (not(@xlang) or $justxlang)">
       <xsl:copy-of select="$ctxt/block/first/node()"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:copy-of select="$ctxt/block/indent/node()"/>
     </xsl:otherwise>
   </xsl:choose>
   <xsl:call-template name="rep_it">
     <xsl:with-param name="inNodes" select="$ctxt/rep/indent/node()"/>
     <xsl:with-param name="anz" select="$repindent - $solrep"/>
   </xsl:call-template>

   <xsl:if test="@xlang">
     <xsl:text>  ~</xsl:text>
   </xsl:if>
   <xsl:apply-templates select="node()" mode="_sc_post">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
   <xsl:if test="@xlang">
     <xsl:text>~</xsl:text>
   </xsl:if>
   <xsl:if test="@no">
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$nl"/>
       <xsl:with-param name="anz" select="@no"/>
     </xsl:call-template>
     <!-- @break ? -->
   </xsl:if>
 </xsl:template>
 <!-- }}}  -->

 <!-- {{{ inline elements, second chance -->
 <xsl:template match="line/inline[@start='rep']" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:copy-of select="$ctxt/rep/start/node()"/>
 </xsl:template>

 <xsl:template match="line/inline[@end='rep']" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:variable name="this" select="$ctxt/rep"/>
   <!-- TODO?! func:if(...,default) -->
   <xsl:choose>
     <xsl:when test="@no >2">
       <xsl:apply-templates select="$this/end[current()/@no=@no or not(@no)]/node()" mode="_do_number">
         <xsl:with-param name="num" select="@no"/>
       </xsl:apply-templates>
     </xsl:when>
     <xsl:otherwise><xsl:copy-of select="$this/simpleend/node()"/></xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="line/spacer" mode="_sc_post">
   <xsl:call-template name="rep_it">
     <xsl:with-param name="inNodes"><xsl:text> </xsl:text></xsl:with-param>
     <xsl:with-param name="anz" select="@no *2"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="line/hfill" mode="_sc_post">
   <!-- TODO? this is just damage containment -->
   <xsl:text>               </xsl:text>
 </xsl:template>
 <!-- }}} -->

 <!-- lgroup/line/@* only informational (except @xlang)! -->
 <!-- {{{ TEMPLATE songcontent_block -->
 <xsl:template name="songcontent_block">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:variable name="lines" select="ec:enclose(*|text(),'$nodes[self::br]','line')"/>
   <xsl:for-each select="exsl:node-set($lines)">
     <xsl:variable name="innerLines_hlp">
       <xsl:apply-templates select="node()" mode="_songcontent_inline">
         <xsl:with-param name="ctxt" select="$ctxt"/>
       </xsl:apply-templates>
     </xsl:variable>
     <xsl:variable name="innerLines" select="exsl:node-set($innerLines_hlp)"/>
     <xsl:variable name="isfirstpos" select="position()=1"/>
     <xsl:choose>
       <xsl:when test="not(@no) and not(normalize-space(.))"/>
       <xsl:when test="not($innerLines/*)"> <!-- speed up common case -->
         <line>
           <xsl:copy-of select="@no|@break"/>
           <xsl:if test="$isfirstpos">
             <xsl:attribute name="firstpos">1</xsl:attribute>
           </xsl:if>
           <xsl:copy-of select="$innerLines"/>
         </line><xsl:value-of select="'&#10;'"/>
       </xsl:when>
       <xsl:otherwise>
         <xsl:variable name="nbr" select="@no|@break"/>
         <xsl:for-each select="exsl:node-set(ec:enclose($innerLines/*|$innerLines/text(),'$nodes[self::br]','line'))[self::line]">
           <xsl:variable name="brhlp"> <!-- common attributes -->
             <line rep="{count(inline[@start='rep'])-count(inline[@end='rep'])}">
               <xsl:choose>
                 <xsl:when test="position()=last()">
                   <xsl:copy-of select="$nbr"/> <!-- use outer -->
                 </xsl:when>
                 <xsl:otherwise>
                   <xsl:copy-of select="@no"/> <!-- @break's are ignored here! -->
                 </xsl:otherwise>
               </xsl:choose>
               <xsl:attribute name="solrep">
                 <xsl:value-of select="count(set:leading(node(),node()[not(self::inline[@start='rep'])]))"/>
               </xsl:attribute>
               <xsl:if test="$isfirstpos and position()=1">
                 <xsl:attribute name="firstpos">1</xsl:attribute>
               </xsl:if>
             </line>
           </xsl:variable>
           <xsl:variable name="br" select="exsl:node-set($brhlp)/line"/>
           <!-- output as line or lgroup ? -->
           <xsl:choose>
             <xsl:when test="xlang">
               <lgroup>
                 <xsl:copy-of select="$br/@*"/>
                 <xsl:value-of select="'&#10;'"/><xsl:text>  </xsl:text>
                 <xsl:if test="node()[not(self::xlang)]">
                   <line no="1">
                     <xsl:copy-of select="$br/@solrep|$br/@firstpos"/> <!-- informational -->
                     <xsl:copy-of select="node()[not(self::xlang)]"/>
                   </line>
                 </xsl:if>
                 <xsl:for-each select="xlang">
                   <xsl:value-of select="'&#10;'"/><xsl:text>  </xsl:text>
                   <line xlang="1">
                     <xsl:if test="position()=1">
                       <xsl:copy-of select="$br/@solrep|$br/@firstpos"/> <!-- informational -->
                     </xsl:if>
                     <xsl:choose>
                       <xsl:when test="position()=last()">
                         <xsl:copy-of select="$br/@no|$br/@break"/> <!-- informational -->
                       </xsl:when>
                       <xsl:otherwise>
                         <xsl:attribute name="no">1</xsl:attribute>
                       </xsl:otherwise>
                     </xsl:choose>
                     <xsl:copy-of select="node()"/>
                   </line>
                 </xsl:for-each>
               </lgroup><xsl:value-of select="'&#10;'"/>
             </xsl:when>
             <xsl:otherwise>
               <line>
                 <xsl:copy-of select="$br/@*|node()"/>
               </line><xsl:value-of select="'&#10;'"/>
             </xsl:otherwise>
           </xsl:choose>
         </xsl:for-each>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:for-each>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ Error-catcher -->
 <xsl:template match="*" mode="_songcontent">
   <xsl:call-template name="error_trap"/>
 </xsl:template>
 <xsl:template match="*" mode="_songcontent_inline">
   <xsl:call-template name="error_trap"/>
 </xsl:template>
 <xsl:template match="*" mode="_sc_post">
   <xsl:call-template name="error_trap"/>
 </xsl:template>
 <!-- }}} -->

 <xsl:template match="text()" mode="_songcontent"/>

 <xsl:template match="text()" mode="_songcontent_inline">
   <xsl:call-template name="nl_hlp"/>
 </xsl:template>

 <xsl:template match="text()[not(preceding-sibling::node())]" mode="_songcontent_inline">
   <xsl:call-template name="nl_hlp">
     <xsl:with-param name="inText" select="concat('&#10;',.)"/> <!-- trick to also(!) remove the leading whitespace -->
   </xsl:call-template>
 </xsl:template>

 <!-- default: remove, you can override -->
 <xsl:template match="akk" mode="_songcontent_inline">
   <xsl:choose>
     <xsl:when test="not(text())">
       <xsl:text> </xsl:text>
     </xsl:when>
     <xsl:when test="text()='_'"/>
     <xsl:when test="text()='-'"/>
     <xsl:otherwise>
       <xsl:value-of select="text()"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!-- {{{ block tags -->
 <xsl:template match="base|vers|refr|bridge|ending" mode="_songcontent">
   <xsl:param name="ctxt"/>
   <block type="{name()}" no="{@no}"><xsl:value-of select="'&#10;'"/>
     <xsl:call-template name="songcontent_block">
       <xsl:with-param name="ctxt" select="$ctxt"/>
     </xsl:call-template>
   </block>
 </xsl:template>

<!--
 <xsl:template match="img" mode="_songcontent">
 </xsl:template>
 -->
 <!-- }}} -->

<!-- TODO? fast matching in _sc_post when <rep inline="start"> instead of <inline start="rep"> ?
     TODO?  fix normalize in _sc_post  alternatively by using test="preceding_sibling::[is_element]" and then not killing leading ws ... trailing
        (e.g. use sentinel non-ws for normalize and remove afterwards) -->
 <!-- {{{ inline tags -->
 <!-- general templates -->
 <xsl:template match="rep|xlate" mode="_songcontent_inline">   <!-- xlate  just added here for clarity (overridden below) -->
   <xsl:param name="ctxt"/>
   <!-- TODO?! func:if(...,default) -->
   <inline start="{name()}">
     <xsl:copy-of select="@*"/>
   </inline>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
   <inline end="{name()}">
     <xsl:copy-of select="@*"/>
   </inline>
 </xsl:template>

 <xsl:template match="tick|spacer|hfill" mode="_songcontent_inline"> <!-- "empty tags" -->   <!-- tick(|sq|eq)  only for clarity -->
   <xsl:param name="ctxt"/>
   <xsl:copy-of select="."/>
 </xsl:template>

 <xsl:template match="br" mode="_songcontent_inline">
   <br no="{@no}"/><!-- @break ignored, see songcontent_block -->
 </xsl:template>

 <xsl:template match="xlang" mode="_songcontent_inline">
   <xsl:param name="ctxt"/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
       <xsl:with-param name="ctxt" select="$ctxt"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <!-- specific templates -->
 <xsl:template match="sq|eq" mode="_songcontent_inline">
   <xsl:param name="ctxt"/>
   <xsl:variable name="lang" select="mine:main_lang($ctxt/@lang,number(func:if(ancestor::xlang,3,1)))"/>   <!-- lang via context/param? -->
   <xsl:variable name="gotlang" select="$ctxt/quotes[@lang=$lang]"/>
   <xsl:variable name="quotes" select="exsl:node-set(func:if(count($gotlang),$gotlang,$ctxt/quotes[not(@lang)]))/quotes"/>
   <xsl:choose>
     <xsl:when test="not($quotes)">
       <xsl:text>&quot;</xsl:text>
     </xsl:when>
     <xsl:when test="self::sq">
       <xsl:value-of select="$quotes/@start"/>
     </xsl:when>
     <xsl:when test="self::eq">
       <xsl:value-of select="$quotes/@end"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:message terminate="yes">Unexpected case</xsl:message>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="tick" mode="_songcontent_inline">
   <xsl:param name="ctxt"/>
   <xsl:variable name="apos" select='"&apos;"'/>
   <xsl:value-of select="func:if($ctxt/tick,$ctxt/tick,$apos)"/>
 </xsl:template>

 <xsl:template match="xlate" mode="_songcontent_inline">
   <xsl:param name="ctxt"/>
   <xsl:text>(Übersetzung: </xsl:text>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
   <xsl:text>)</xsl:text>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ _do_number -->
 <xsl:template match="num" mode="_do_number">
   <xsl:param name="num"/>
   <xsl:value-of select="format-number($num,@fmt)"/>
 </xsl:template>

 <xsl:template match="numattr" mode="_do_number">
   <xsl:param name="num"/>
   <xsl:attribute name="{@name}">
     <xsl:value-of select="format-number($num,@fmt)"/>
   </xsl:attribute>
 </xsl:template>

 <xsl:template match="@*|node()|comment()" mode="_do_number">
   <xsl:param name="num"/>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()" mode="_do_number">
       <xsl:with-param name="num" select="$num"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>
 <!-- }}} -->

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
     <xsl:if test="string-length($first)!=0">
       <xsl:value-of select="$first"/><xsl:value-of select="substring-after($inText,$first)"/>
     </xsl:if>
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

 <!-- {{{ FUNCTION func:if (do_first,first [,second])  -  return (copy-of) $first or $second -->
 <func:function name="func:if">
   <xsl:param name="do_first"/>
   <xsl:param name="first"/>
   <xsl:param name="second"/>
   <func:result>
     <xsl:choose>
       <xsl:when test="$do_first">
         <xsl:copy-of select="$first"/>
       </xsl:when>
       <xsl:otherwise>
         <xsl:copy-of select="$second"/>
       </xsl:otherwise>
     </xsl:choose>
   </func:result>
 </func:function>
 <!-- }}} -->

 <!-- {{{ FUNCTION func:strip-root(node)  -  but keep attribs -->
 <func:function name="func:strip-root">
   <xsl:param name="node"/>
   <func:result select="$node[1]/@*|$node[1]/node()"/>
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
