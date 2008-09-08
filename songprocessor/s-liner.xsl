<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:mine="thax.home/mine-ext-speed"
                xmlns:ec="thax.home/enclose"
                extension-element-prefixes="exsl func mine ec">

 <!-- customize by overriding the templates.
      requires a template called "error_trap".
 -->

 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:template name="songcontent">
   <xsl:variable name="config">
     <base/>
     <vers>
       <first><xsl:text>#. </xsl:text></first>
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
   </xsl:variable>
   <xsl:variable name="inNodes">
     <xsl:apply-templates select="*" mode="_songcontent">
       <xsl:with-param name="config" select="exsl:node-set($config)"/>
     </xsl:apply-templates>
   </xsl:variable>
   <xsl:apply-templates select="exsl:node-set($inNodes)" mode="_sc_post"/>
 </xsl:template>

 <!-- {{{ songcontent postprocessing: _sc_post -->
 <xsl:template match="line" mode="_sc_post">
   <xsl:value-of select="."/>
   <xsl:if test="@no">
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$nl"/>
       <xsl:with-param name="anz" select="@no"/>
     </xsl:call-template>
     <!-- @break ? -->
   </xsl:if>
 </xsl:template>

 <xsl:template match="text()" mode="_sc_post"/>
 <!-- }}} -->

 <xsl:template name="songcontent_block">
   <xsl:param name="indent" select="/.."/>
   <xsl:param name="first" select="/.."/>
   <xsl:param name="ctxt" select="/.."/>
   <xsl:variable name="lines" select="ec:enclose(*|text(),'$nodes[self::br]','line')"/>
   <xsl:for-each select="exsl:node-set($lines)">
     <xsl:variable name="innerLines_hlp">
       <xsl:apply-templates select="node()" mode="_songcontent_inline">
         <xsl:with-param name="ctxt" select="$ctxt"/>
         <xsl:with-param name="indent" select="$indent"/>
       </xsl:apply-templates>
     </xsl:variable>
     <xsl:variable name="innerLines" select="exsl:node-set($innerLines_hlp)"/>
     <xsl:variable name="isfirstpos" select="position()=1"/>
     <xsl:choose>
       <xsl:when test="not(@no) and not(normalize-space(.))"/>
       <xsl:when test="not($innerLines/*)"> <!-- speed up special case -->
         <line>
           <xsl:copy-of select="@no|@break"/>
           <xsl:choose>
             <xsl:when test="$first and $isfirstpos">
               <xsl:copy-of select="$first"/>
             </xsl:when>
             <xsl:when test="$indent">
               <xsl:copy-of select="$indent"/>
             </xsl:when>
           </xsl:choose>
           <xsl:copy-of select="$innerLines"/>
         </line><xsl:value-of select="$nl"/>
       </xsl:when>
       <xsl:otherwise>
         <xsl:variable name="nbr" select="@no|@break"/>
         <xsl:for-each select="exsl:node-set(ec:enclose($innerLines/*|$innerLines/text(),'$nodes[self::br]','line'))[self::line]">
           <line>
             <xsl:choose>
               <xsl:when test="position()=last()">
                 <xsl:copy-of select="$nbr"/>
               </xsl:when>
               <xsl:otherwise>
                 <xsl:copy-of select="@no"/> <!-- @break's are ignored here! -->
               </xsl:otherwise>
             </xsl:choose>
             <xsl:choose>
               <xsl:when test="$first and $isfirstpos and position()=1">
                 <xsl:copy-of select="$first"/>
               </xsl:when>
               <xsl:when test="$indent and position()=1"><!-- others are done by <br> -->
                 <xsl:copy-of select="$indent"/>
               </xsl:when>
               <xsl:otherwise>
<!-- TODO                 <xsl:copy-of select="func:strip-root(preceding-sibling::*[1][self::next])"/> -->
                 <xsl:copy-of select="func:strip-root(next)"/>
               </xsl:otherwise>
             </xsl:choose>
             <xsl:copy-of select="node()"/>
           </line><xsl:value-of select="$nl"/>
         </xsl:for-each>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:for-each>
 </xsl:template>

 <!-- {{{ Error-catcher -->
 <xsl:template match="*" mode="_songcontent">
   <xsl:call-template name="error_trap"/>
 </xsl:template>
 <xsl:template match="*" mode="_songcontent_inline">
   <xsl:call-template name="error_trap"/>
 </xsl:template>
 <!-- }}} -->

 <xsl:template match="text()" mode="_songcontent"/>
 
 <xsl:template match="text()" mode="_songcontent_inline">
   <xsl:call-template name="nl_hlp"/>
 </xsl:template>

 <!-- default: remove, you can override -->
 <xsl:template match="akk" mode="_songcontent_inline">
   <xsl:choose>
     <xsl:when test="not(text())">
       <xsl:text> </xsl:text>
     </xsl:when>
     <xsl:when test="text()='_'"/>
     <xsl:otherwise>
       <xsl:value-of select="text()"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!-- {{{ block tags -->
 <xsl:template match="base|refr|bridge|ending" mode="_songcontent">
   <xsl:param name="config" select="/.."/>
   <xsl:variable name="this" select="$config/*[name()=name(current())]"/>
   <xsl:copy-of select="$this/pre/@*|$this/pre/node()"/>
   <xsl:call-template name="songcontent_block">
     <xsl:with-param name="ctxt" select="$config|.."/>
     <xsl:with-param name="first" select="func:strip-root($this/first)"/>
     <xsl:with-param name="indent" select="func:strip-root($this/indent)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="vers" mode="_songcontent">
   <xsl:param name="config" select="/.."/>
   <xsl:variable name="this" select="$config/*[name()=name(current())]"/>
   <xsl:variable name="first"><first><xsl:value-of select="@no"/><xsl:text>. </xsl:text></first></xsl:variable>
   <xsl:copy-of select="$this/pre/@*|$this/pre/node()"/>
   <xsl:call-template name="songcontent_block">
     <xsl:with-param name="ctxt" select="$config|.."/>
     <xsl:with-param name="first" select="func:strip-root(exsl:node-set($first)/first)"/>
     <xsl:with-param name="indent" select="func:strip-root($this/indent)"/>
   </xsl:call-template>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ inline tags -->
<!--
 <xsl:template match="img" mode="_songcontent">
   ...
   <xsl:copy>
     <xsl:attribute name="odpName"><xsl:value-of select="func:get_image_name(.)"/></xsl:attribute>
     <xsl:copy-of select="@*"/>
   </xsl:copy>
   <page-cand break="-1"/>
 </xsl:template>
 -->

 <xsl:template match="rep" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:text>|: </xsl:text>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent"><xsl:copy-of select="$indent"/><xsl:text>   </xsl:text></xsl:with-param>
   </xsl:apply-templates>
   <xsl:choose>
     <xsl:when test="@no >2"><xsl:text> :| (</xsl:text><xsl:value-of select="@no"/><xsl:text>x)</xsl:text></xsl:when>
     <xsl:otherwise><xsl:text> :|</xsl:text></xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="quote" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:variable name="quotes" select="$ctxt/quotes[@lang=$ctxt/@lang or not(@lang)]"/>
   <xsl:value-of select="func:if($quotes,string($quotes/@start),string('&quot;'))"/>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   <xsl:value-of select="func:if($quotes,string($quotes/@end),string('&quot;'))"/>
 </xsl:template>

 <xsl:template match="tick" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:variable name="apos" select='"&apos;"'/>
   <xsl:value-of select="func:if($ctxt/tick,$ctxt/tick,$apos)"/>
 </xsl:template>

 <xsl:template match="spacer" mode="_songcontent_inline">
   <xsl:call-template name="rep_it">
     <xsl:with-param name="inNodes"><xsl:text> </xsl:text></xsl:with-param>
     <xsl:with-param name="anz" select="@no *2"/>
   </xsl:call-template>
 </xsl:template>
 
 <xsl:template match="hfill" mode="_songcontent_inline">
   <!-- TODO? this is just damage containment -->
   <xsl:text>               </xsl:text>
 </xsl:template>
 
 <xsl:template match="xlate" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:text>(Übersetzung: </xsl:text>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   <xsl:text>)</xsl:text>
 </xsl:template>

 <xsl:template match="br" mode="_songcontent_inline">
   <xsl:param name="indent" select="/.."/>
<!--  TODO <br no="{@no}"><next><xsl:copy-of select="$indent"/></next></br>--><!-- @break ignored, see songcontent_block -->
   <br no="{@no}"/><next><xsl:copy-of select="$indent"/></next><!-- @break ignored, see songcontent_block -->
 </xsl:template>

 <xsl:template match="xlang" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:text>  ~</xsl:text>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   <xsl:text>~</xsl:text>
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

</xsl:stylesheet>
