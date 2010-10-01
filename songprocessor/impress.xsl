<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:set="http://exslt.org/sets"
                xmlns:thobi="thax.home/split"
                xmlns:tools="thax.home/tools"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:mine="thax.home/mine-ext-speed"
                xmlns:zip="thax.home/zip-ext"
                xmlns:ec="thax.home/enclose"
            xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
            xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
            xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
            xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
            xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
            xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0"
            xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
            xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
            xmlns:math="http://www.w3.org/1998/Math/MathML"
            xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" 
            xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
            xmlns:ooo="http://openoffice.org/2004/office"
            xmlns:ooow="http://openoffice.org/2004/writer"
            xmlns:oooc="http://openoffice.org/2004/calc"
            xmlns:dom="http://www.w3.org/2001/xml-events"
            xmlns:xforms="http://www.w3.org/2002/xforms"
            xmlns:xsd="http://www.w3.org/2001/XMLSchema"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:smil="urn:oasis:names:tc:opendocument:xmlns:smil-compatible:1.0"
            xmlns:anim="urn:oasis:names:tc:opendocument:xmlns:animation:1.0"
            exclude-result-prefixes="office style text table draw fo xlink dc meta number presentation svg chart dr3d math form script ooo ooow oooc dom xforms xsd xsi smil anim"
                extension-element-prefixes="exsl func set thobi mine ec zip tools">
<!-- TODO? Language for spellchecker -->
<!-- TODO? want/need function to add something to an array :-)
  array=array.add bla fasel...
  Idea: Nodesets: ns_clear('id/name'); ns_add('id/name'); ns_get('id/name');
-->
 
 <xsl:import href="s-liner.xsl"/>

 <xsl:output method="text" encoding="iso-8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:param name="out_split" select="'0'"/>
 <xsl:param name="presetname" select="''"/>
 <xsl:variable name="ps_doc" select="document('oopreset.xml')"/>
 <xsl:variable name="preset" select="exsl:node-set(func:if($ps_doc/presets/preset[@name=$presetname],
                                                   $ps_doc/presets/preset[@name=$presetname],$ps_doc/presets/preset[not(@name)]))/preset"/>

 <xsl:include href="rights-full.xsl"/>
 <xsl:include href="lang-db.xsl"/>
 <xsl:strip-space elements="songs-out"/>

 <xsl:template match="/">
   <xsl:choose>
     <xsl:when test="$out_split >0">
       <xsl:apply-templates select="songs-out/*" mode="file_multi"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:call-template name="output_odp">
         <xsl:with-param name="file" select="'allimpress.odp'"/>
         <xsl:with-param name="content_nodes">
           <xsl:apply-templates select="songs-out/*" mode="file_single"/>
         </xsl:with-param>
         <xsl:with-param name="black_back" select="count($preset/black)"/>
         <xsl:with-param name="add_files">
           <xsl:copy-of select="$preset/copy"/>
           <xsl:apply-templates select="songs-out/*" mode="get_add_images"/>
         </xsl:with-param>
       </xsl:call-template>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!--<xsl:with-param name="title"><xsl:apply-templates select="title" mode="inhalt"/></xsl:with-param>-->
 <xsl:template match="song" mode="file_single" name="filecontent">
   <xsl:param name="position" select="position()"/>
<!--  <xsl:call-template name="output_blkp"/>-->
   <xsl:variable name="copy"><xsl:call-template name="copyright"/></xsl:variable>
   <xsl:call-template name="output_pages">
     <xsl:with-param name="copyright">
       <xsl:if test="$copy!=''">
         <xsl:text>© </xsl:text>
<!--       <xsl:text>Copyright: </xsl:text>-->
         <xsl:value-of select="$copy"/>
       </xsl:if> 
     </xsl:with-param>
     <xsl:with-param name="source">
       <xsl:text>Quelle: </xsl:text>
       <xsl:apply-templates select="from" mode="from_list"/>
     </xsl:with-param>
     <xsl:with-param name="lbfrom">
       <xsl:apply-templates select="from" mode="from_lbfrom"/>
     </xsl:with-param>
     <xsl:with-param name="position" select="$position"/>
   </xsl:call-template>
   <xsl:call-template name="output_blkp">
     <xsl:with-param name="position" select="concat($position,'_b')"/>
   </xsl:call-template>
 </xsl:template>
 <xsl:template match="from" mode="from_list">
   <xsl:value-of select="text()"/>
   <xsl:if test="count(following-sibling::from)">
     <xsl:text>; </xsl:text>
   </xsl:if> 
 </xsl:template>
 <xsl:template match="from" mode="from_lbfrom">
   <xsl:choose>
     <xsl:when test="starts-with(translate(text(),'IWD','iwd'),'iwdd/')">
       <IWDD><xsl:value-of select="substring-after(text(),'/')"/></IWDD>
     </xsl:when>
     <xsl:when test="starts-with(translate(text(),'GML','gml'),'gml/')">
       <GML><xsl:value-of select="substring-after(text(),'/')"/></GML>
     </xsl:when>
   </xsl:choose> 
 </xsl:template>

 <xsl:template match="song" mode="file_multi">
   <xsl:variable name="file">oo-impress/<xsl:value-of select="func:escape_file(title[1]/text())"/>.odp</xsl:variable>
   <xsl:call-template name="output_odp">
     <xsl:with-param name="file" select="$file"/>
     <xsl:with-param name="content_nodes">
       <xsl:call-template name="filecontent">
         <xsl:with-param name="position" select="0"/>
       </xsl:call-template>
     </xsl:with-param>
     <xsl:with-param name="black_back" select="count($preset/black)"/>
     <xsl:with-param name="add_files">
       <xsl:apply-templates select="content/*" mode="get_add_images"/>
     </xsl:with-param>
   </xsl:call-template>
   <xsl:apply-templates select="title" mode="links">
     <xsl:with-param name="linkTo" select="$file"/>
   </xsl:apply-templates>
 </xsl:template>

 <xsl:template match="blkp" mode="file_multi"/>
 <xsl:template match="blkp" mode="file_single" name="output_blkp">
   <xsl:param name="position" select="concat(position(),'_B')"/>
   <draw:page draw:name="{$position}" draw:style-name="dp3" draw:master-page-name="Default">
     <office:forms form:automatic-focus="false" form:apply-design-mode="false"/>
   </draw:page>
 </xsl:template>

 <xsl:template match="img" mode="file_multi"/><!-- TODO? -->
 <!--
 <xsl:template match="img" mode="file_multi">
   <xsl:variable name="file">oo-impress/<xsl:value-of select="func:escape_file(@href)"/>.odp</xsl:variable>
   <xsl:call-template name="output_odp">
     <xsl:with-param name="file" select="$file"/>
     <xsl:with-param name="content_nodes">
<!- -       <xsl:call-template name="output_blkp"/>- ->
       <xsl:call-template name="output_img"/>
     </xsl:with-param>
     <xsl:with-param name="black_back" select="count($preset/black)"/>
   </xsl:call-template>
   <xsl:apply-templates select="title" mode="links">
     <xsl:with-param name="linkTo" select="$file"/>
   </xsl:apply-templates>
 </xsl:template>
 -->
 
 <xsl:template match="img" mode="file_single" name="output_img">
   <xsl:param name="impress_page_x" select="0"/>
   <xsl:param name="impress_page_y" select="0"/>
   <xsl:param name="impress_page_w" select="28"/><!-- everything in cm -->
   <xsl:param name="impress_page_h" select="21"/>
   <xsl:param name="odpName" select="func:get_image_name(.)"/>
   <xsl:param name="position" select="concat(position(),'_I')"/><!-- only relevant for standalone, TODO? -->
   <xsl:variable name="impress_page_ratio" select="$impress_page_w div $impress_page_h"/>
   <xsl:variable name="bgstyle">
     <xsl:choose>
       <xsl:when test="@blackbg">dp3</xsl:when>
       <xsl:when test="@whitebg">dp4</xsl:when>
       <xsl:otherwise>dp1</xsl:otherwise><!-- default -->
     </xsl:choose>
   </xsl:variable>
   <xsl:variable name="img_border" select="func:default(@border,0)"/>
   <xsl:variable name="img_info" select="tools:image-size(@href)"/>
   <xsl:variable name="img_ratio" select="$img_info/@width div $img_info/@height"/>
   <xsl:variable name="impress_w" select="func:if($img_ratio > $impress_page_ratio,
                                                  $impress_page_w - $img_border,
                                                  ($impress_page_h - $img_border)*$img_ratio)"/>
   <xsl:variable name="impress_h" select="func:if($img_ratio > $impress_page_ratio,
                                                  ($impress_page_w - $img_border) div $img_ratio,
                                                  $impress_page_h - $img_border)"/>
   <xsl:variable name="impress_x" select="$impress_page_x + ($impress_page_w - $impress_w) div 2"/> <!-- center -->
   <xsl:variable name="impress_y" select="$impress_page_y + ($impress_page_h - $impress_h) div 2"/>
   <draw:page draw:name="{$position}" draw:style-name="{$bgstyle}" draw:master-page-name="Default">
     <office:forms form:automatic-focus="false" form:apply-design-mode="false"/>
     <draw:frame draw:style-name="gr1" draw:text-style-name="P2" draw:layer="layout" svg:width="{$impress_w}cm" svg:height="{$impress_h}cm" svg:x="{$impress_x}cm" svg:y="{$impress_y}cm"><!-- gr1 / gr2 to choose center/top -->
       <draw:image xlink:href="{$odpName}" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
     </draw:frame>
   </draw:page>
 </xsl:template>

 <xsl:template mode="get_add_images" match="img">
   <xsl:variable name="img_info" select="tools:image-size(@href)"/>
   <copy fromhref="{@href}" tohref="{func:get_image_name(.)}" mime="{$img_info/@type}"/>
 </xsl:template>

 <xsl:template match="img" mode="_img_pager">
   <xsl:call-template name="output_img">
     <xsl:with-param name="impress_page_x" select="-0.5"/><!-- TODO: lilypond hack -->
     <xsl:with-param name="impress_page_y" select="0.1"/><!-- trial-and-error... -->
     <xsl:with-param name="impress_page_h" select="19.23"/><!-- only top-part used -->
     <xsl:with-param name="odpName" select="@odpName"/>
   </xsl:call-template>
 </xsl:template>

 <!-- {{{ TEMPLATE output_odp (file, content_nodes, black_back)  - outputs an .odp (>file) with black(>black_back==1) or white(0) background using >content_nodes. There is also add_files -->
 <xsl:template name="output_odp">
   <xsl:param name="file"/>
   <xsl:param name="content_nodes" select="."/>
   <xsl:param name="black_back"/>
   <xsl:param name="add_files"/>
   <zip:doc-zip href="{$file}" copy-select="$add_files">
     <exsl:document href="zip:store/mimetype" method="text"><!-- has to be first, and uncompressed! -->
       <xsl:text>application/vnd.oasis.opendocument.presentation</xsl:text>
     </exsl:document>
     <exsl:document href="content.xml" encoding="UTF-8" method="xml" indent="yes">
       <xsl:apply-templates select="document('oo-template/content.xml')" mode="_output_odp_content">
         <xsl:with-param name="content_nodes" select="$content_nodes"/>
       </xsl:apply-templates>
     </exsl:document>
     <exsl:document href="styles.xml" encoding="UTF-8" method="xml" indent="yes">
       <xsl:apply-templates select="document('oo-template/styles.xml')" mode="_output_odp_style">
         <xsl:with-param name="black_back" select="$black_back"/>
       </xsl:apply-templates>
     </exsl:document>
     <exsl:document href="META-INF/manifest.xml" encoding="UTF-8" method="xml" indent="yes"
                    doctype-public="-//OpenOffice.org//DTD Manifest 1.0//EN"
                    doctype-system="Manifest.dtd">
       <manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">
         <manifest:file-entry manifest:media-type="application/vnd.oasis.opendocument.presentation" manifest:full-path="/"/>
         <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/>
         <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml"/>
         <xsl:for-each select="exsl:node-set($add_files)/*">
           <manifest:file-entry manifest:media-type="{@mime}" manifest:full-path="{@tohref}"/>
         </xsl:for-each>
       </manifest:manifest>
     </exsl:document>
   </zip:doc-zip>
 </xsl:template>

 <xsl:template match="INSERT" mode="_output_odp_content">
   <xsl:param name="content_nodes"/>
<!--   <xsl:copy-of select="$content_nodes"/> ... namespaces not reduced ... --> 
   <xsl:apply-templates select="exsl:node-set($content_nodes)/node()" mode="_output_odp_content"/>
 </xsl:template>

 <xsl:template match="@*|node()|comment()" mode="_output_odp_content">
   <xsl:param name="content_nodes" select="."/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()|comment()" mode="_output_odp_content">
       <xsl:with-param name="content_nodes" select="$content_nodes"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>
 
 <xsl:template match="style:style[@style:name='Default-background']/style:graphic-properties" mode="_output_odp_style">
   <xsl:param name="black_back"/>
   <xsl:choose>
     <xsl:when test="$black_back >0">
       <xsl:copy>
         <xsl:attribute name="draw:stroke">solid</xsl:attribute>
         <xsl:attribute name="draw:fill-color">#000000</xsl:attribute>
         <xsl:attribute name="draw:fill-image-width">0cm</xsl:attribute>
         <xsl:attribute name="draw:fill-image-height">0cm</xsl:attribute>
       </xsl:copy>
     </xsl:when>
     <xsl:otherwise>
       <xsl:copy>
         <xsl:attribute name="draw:stroke">none</xsl:attribute>
         <xsl:attribute name="draw:fill">none</xsl:attribute>
       </xsl:copy>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="style:default-style/style:text-properties/@fo:language" mode="_output_odp_style">
   <xsl:attribute name="fo:language">de</xsl:attribute>
 </xsl:template>

 <xsl:template match="style:default-style/style:text-properties/@fo:country" mode="_output_odp_style">
   <xsl:attribute name="fo:country">DE</xsl:attribute>
 </xsl:template>
 
 <xsl:template match="@*|node()|comment()" mode="_output_odp_style">
   <xsl:param name="black_back"/>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()|comment()" mode="_output_odp_style">
       <xsl:with-param name="black_back" select="$black_back"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>
 <!-- }}} -->

 <xsl:template name="output_pages">
   <xsl:param name="copyright"/>
   <xsl:param name="source"/>
   <xsl:param name="lbfrom"/>
   <xsl:param name="position" select="position()"/>
   <!--  select="title[1]/text()" -->
   <xsl:variable name="inNodes">
     <xsl:apply-templates select="content"/>
   </xsl:variable>
   <xsl:variable name="inPNodes">
     <xsl:apply-templates select="exsl:node-set($inNodes)/node()" mode="_break_calc"/>
   </xsl:variable>
   <xsl:variable name="inPages">
     <xsl:call-template name="page_fix"> 
       <xsl:with-param name="inNodes" select="exsl:node-set($inPNodes)/node()"/>
     </xsl:call-template> 
   </xsl:variable>
<!-- 
<exsl:document href="/dev/stdout"><xsl:copy-of select="$inPNodes"/></exsl:document>
-->
   <xsl:apply-templates select="exsl:node-set($inPages)/node()" mode="_output_page">
     <xsl:with-param name="inCopyright" select="$copyright"/>
     <xsl:with-param name="inSource" select="$source"/>
     <xsl:with-param name="inLBfrom" select="exsl:node-set($lbfrom)/*[1]"/>
     <xsl:with-param name="position" select="$position"/>
   </xsl:apply-templates>
 </xsl:template>

 <!-- {{{ the page template -->
 <xsl:template match="/page" mode="_output_page">
   <xsl:param name="inCopyright"/><!-- Copyright: -->
   <xsl:param name="inSource"/><!-- Aus: -->
   <xsl:param name="inLBfrom"/><!-- Liednummer /Grün,Rot -->
   <xsl:param name="position"/><!-- Liedposition (für einzigartigen seitennamen) -->
   <xsl:variable name="tr1" select="set:leading(../page,.)"/>
   <xsl:variable name="tr2" select=".|set:trailing(../page,.)"/>
   <xsl:variable name="tr3" select="set:trailing($tr1,$tr1[@endpage][1])"/>
   <xsl:variable name="tr4" select="set:leading($tr2,$tr2[@endpage][1])|$tr2[@endpage][1]"/>
   <xsl:variable name="inPgOf" select="func:if(count($tr3)+count($tr4)>1,concat(count($tr3)+1,'/',count($tr3)+count($tr4)))"/>
   <xsl:variable name="images-hlp">
     <xsl:apply-templates select="img" mode="_img_pager"/>
   </xsl:variable>
   <xsl:variable name="images" select="exsl:node-set($images-hlp)"/>
   <xsl:variable name="style" select="func:default($images/draw:page/@draw:style-name,'dp1')"/>
   <xsl:variable name="lb">
     <xsl:choose>
       <xsl:when test="not($preset/set-lb)"/>
       <xsl:when test="$inLBfrom[self::IWDD]">PLBgreen</xsl:when>
       <xsl:when test="$inLBfrom[self::GML]">PLBred</xsl:when>
     </xsl:choose>
   </xsl:variable>
   <draw:page draw:name="{$position}_{(position()-1) div 2+1}" draw:style-name="{$style}" draw:master-page-name="Default">
     <office:forms form:automatic-focus="false" form:apply-design-mode="false"/>
     <xsl:copy-of select="$preset/prestatic/*"/>
     <xsl:copy-of select="$images/draw:page/draw:frame"/>
     <draw:frame draw:text-style-name="P2" draw:layer="layout"><!-- gr1 / gr2 / gr3 to choose center/top/bottom -->
       <xsl:copy-of select="$preset/set-text/@*|$preset/set-text/node()"/>
       <draw:text-box>
         <xsl:copy-of select="node()[not(self::img)]"/>
       </draw:text-box><xsl:value-of select="$nl"/>
     </draw:frame><xsl:value-of select="$nl"/>
     <draw:frame draw:style-name="gr3" draw:layer="layout">
       <xsl:copy-of select="$preset/set-rights/@*|$preset/set-rights/node()"/>
       <draw:text-box>
         <text:p text:style-name="P1"><xsl:copy-of select="$inCopyright"/></text:p><!-- TODO? handle formatting? -->
       </draw:text-box><xsl:value-of select="$nl"/>
     </draw:frame><xsl:value-of select="$nl"/>
     <draw:frame draw:style-name="gr3" draw:layer="layout">
       <xsl:copy-of select="$preset/set-from/@*|$preset/set-from/node()"/>
       <draw:text-box>
         <text:p text:style-name="P1"><xsl:copy-of select="$inSource"/></text:p><!-- TODO? handle formatting? -->
       </draw:text-box><xsl:value-of select="$nl"/>
     </draw:frame><xsl:value-of select="$nl"/>
     <draw:frame draw:style-name="gr3" draw:text-style-name="P5" draw:layer="layout">
       <xsl:copy-of select="$preset/set-pgof/@*|$preset/set-pgof/node()"/>
       <draw:text-box>
         <text:p text:style-name="P5"><xsl:value-of select="$inPgOf"/></text:p>
       </draw:text-box><xsl:value-of select="$nl"/>
     </draw:frame><xsl:value-of select="$nl"/>
     <!-- Rotes/Grünes Lb -->
     <xsl:if test="string-length($lb)">
       <draw:frame draw:style-name="gr2" draw:text-style-name="{$lb}" draw:layer="layout">
         <xsl:copy-of select="$preset/set-lb/@*|$preset/set-lb/node()"/>
         <draw:text-box>
           <text:p text:style-name="{$lb}"><xsl:value-of select="$inLBfrom/text()"/></text:p>
         </draw:text-box>
       </draw:frame><xsl:value-of select="$nl"/>
     </xsl:if>
     <xsl:copy-of select="$preset/poststatic/*"/>
     <presentation:notes draw:style-name="dp2">
       <draw:page-thumbnail draw:style-name="gr2" draw:layer="layout" svg:width="14.848cm" svg:height="11.135cm" svg:x="3.07cm" svg:y="2.257cm" draw:page-number="1" presentation:class="page"/><xsl:value-of select="$nl"/>
       <draw:frame presentation:style-name="pr1" draw:text-style-name="P3" draw:layer="layout" svg:width="16.79cm" svg:height="13.365cm" svg:x="2.098cm" svg:y="14.107cm" presentation:class="notes" presentation:placeholder="true"><xsl:value-of select="$nl"/>
         <draw:text-box/><xsl:value-of select="$nl"/>
       </draw:frame><xsl:value-of select="$nl"/>
     </presentation:notes>
   </draw:page>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ page breaking, part 2 -->
 <xsl:template name="page_fix">
   <xsl:param name="inNodes"/>
   <xsl:param name="lastSplit" select="'0'"/>
   <xsl:variable name="nextEnd" select="set:leading($inNodes[self::page-cand],$inNodes[self::page-cand][@endpage or @break &lt;0])|
                                        $inNodes[self::page-cand][@endpage or @break &lt; 0][1]"/>
   <xsl:variable name="splitpt_set" select="$nextEnd[position()=1 or @no &lt;= 2*$preset/linesPerPage + $lastSplit]"/>
   <xsl:variable name="no_block" select="count($splitpt_set/@block)=0"/><!-- is there no block-start ? -->
   <xsl:variable name="splitpt" select="$splitpt_set[$no_block or @block or @endpage or @break &lt; 0][last()]|$nextEnd[last()]"/>
   <xsl:variable name="tree1" select="set:leading($inNodes,$splitpt)"/>
   <xsl:variable name="tree2" select="set:trailing($inNodes,$splitpt)"/>
   <xsl:choose>
     <xsl:when test="$tree2/@endpage">
       <page>
       <xsl:if test="$splitpt[1]/@endpage"><xsl:attribute name="endpage">1</xsl:attribute></xsl:if>
       <xsl:apply-templates select="$tree1" mode="_page_fix"/>
       </page><xsl:value-of select="$nl"/>
       <xsl:call-template name="page_fix">
         <xsl:with-param name="inNodes" select="$tree2"/>
         <xsl:with-param name="lastSplit" select="$splitpt[1]/@no + $splitpt[1]/@self"/>
       </xsl:call-template>
     </xsl:when>
     <xsl:otherwise>
       <page>
       <xsl:apply-templates select="$tree1" mode="_page_fix"/>
       </page><xsl:value-of select="$nl"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="page-cand" mode="_page_fix">
   <xsl:copy-of select="*"/>
 </xsl:template>

 <xsl:template match="@*|node()" mode="_page_fix">
   <xsl:copy>
     <xsl:copy-of select="@*" mode="_page_fix"/>
     <xsl:apply-templates select="node()" mode="_page_fix"/>
   </xsl:copy>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ page breaking, part 1 -->
 <xsl:template match="/page-cand" mode="_break_calc">
   <xsl:variable name="tr1" select="set:leading(../*,.)/descendant-or-self::text:p"/>
   <xsl:copy>
     <xsl:attribute name="no"><!-- sum of lines up to here -->
       <xsl:value-of select="count($tr1[@text:style-name!='P3'])*2+
                             count($tr1[@text:style-name='P3'])-
                             count($tr1[child::text:span[@text:style-name='Txlang']])"/>
     </xsl:attribute>
     <xsl:attribute name="self"><!-- number of lines contained in <page-cand>..</page-cand> -->
       <xsl:value-of select="func:if(node(),count(text:p[@text:style-name!='P3'])*2+
                                            count(text:p[@text:style-name='P3'])
                                           ,0)"/>
     </xsl:attribute>
     <xsl:if test="not(@endpage) and following-sibling::*[1][self::page-cand]/@block">
       <xsl:attribute name="block">1</xsl:attribute>
     </xsl:if>
     <xsl:if test="following-sibling::*[1][self::page-cand]/@endpage">
       <xsl:attribute name="endpage">1</xsl:attribute>
     </xsl:if>
     <xsl:copy-of select="@*[name()!='no']|node()"/>
   </xsl:copy>
   <xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="/page-cand[@block][not(preceding-sibling::*)]" mode="_break_calc"/>
 <xsl:template match="/page-cand[@block or @endpage][preceding-sibling::*[1][self::page-cand]]" mode="_break_calc"/>

 <xsl:template match="@*|node()" mode="_break_calc">
   <xsl:copy-of select="."/>
 </xsl:template>
 <!-- }}} -->

 <!-- special Txlang handling -->
 <xsl:template match="/text:p[child::text:span[@text:style-name='Txlang']]" mode="_break_calc">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_move_txlang"/>
   </xsl:copy>
 </xsl:template>
 <xsl:template match="text:tab" mode="_move_txlang">
 </xsl:template>
 <xsl:template match="text:span" mode="_move_txlang">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="preceding-sibling::text:tab"/>
     <xsl:copy-of select="node()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="song/title" mode="links">
   <xsl:param name="linkTo"/>
   <xsl:choose>
     <xsl:when test="../content//akk">
       <xsl:text>href="</xsl:text><xsl:value-of select="$linkTo"/><xsl:text>" </xsl:text>
       <xsl:value-of select="."/>&#160;[akks]<xsl:value-of select="$nl"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:text>href="</xsl:text><xsl:value-of select="$linkTo"/><xsl:text>" </xsl:text>
       <xsl:value-of select="."/><xsl:value-of select="$nl"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="song/content">
<!-- multi song/lang mode -->
<!--
   <text:p text:style-name="Px">
   <xsl:apply-templates select="../title[@lang=current()/@lang or not(@lang)]">
     <xsl:with-param name="lang" select="@lang"/>
   </xsl:apply-templates></text:p>
   <text:p text:style-name="Px"><xsl:text>- - - - -</xsl:text></text:p><xsl:value-of select="$nl"/>-->
   <xsl:call-template name="songcontent"/>
 </xsl:template>

 <!-- {{{ Error-catcher -->
 <xsl:template match="*" name="error_trap">
   <xsl:text>{</xsl:text>
   <xsl:value-of select="text()"/>
   <xsl:text>#</xsl:text>
   <xsl:value-of select="name()"/>
   <xsl:text>}</xsl:text>
   <xsl:value-of select="$nl"/>
 </xsl:template>
 <xsl:template match="*" mode="file_single">
   <xsl:call-template name="error_trap"/>
 </xsl:template>
 <xsl:template match="*" mode="file_multi">
   <xsl:call-template name="error_trap"/>
 </xsl:template>
 <!-- }}} -->

 <xsl:template name="songcontent">
   <xsl:variable name="config">
     <base>
       <first format="P2"/>
       <indent format="P2"/>
     </base>
     <vers>
       <pre><page-cand block="1"/></pre>
       <first format='Pvers'><num fmt="#"/><xsl:text>.</xsl:text><text:tab/></first>
       <indent format='Pvers'><text:tab/></indent>
     </vers>
     <refr>
       <pre><page-cand block="1"/></pre>
       <first format='Prefr'><xsl:text>Refr:</xsl:text><text:tab/></first>
       <indent format='Prefr'><text:tab/></indent>
     </refr>
     <bridge>
       <pre><page-cand block="1"/></pre>
       <first format='Pbridge'><xsl:text>Bridge:</xsl:text><text:tab/></first>
       <indent format='Pbridge'><text:tab/></indent>
     </bridge>
     <ending>
       <pre><page-cand block="1"/></pre>
       <first format='Pending'><xsl:text>Schluss:</xsl:text><text:tab/></first>
       <indent format='Pending'><text:tab/></indent>
     </ending>
     <quotes lang="en" start="&#x201c;" end="&#x201d;"/>
     <quotes lang="de" start="&#x201e;" end="&#x201c;"/>
     <tick><xsl:text>&#x2019;</xsl:text></tick>
   </xsl:variable>
   <xsl:variable name="inNodes">
     <xsl:apply-templates select="*" mode="_songcontent">
       <xsl:with-param name="config" select="exsl:node-set($config)"/>
     </xsl:apply-templates>
     <page-cand endpage="1"/>
   </xsl:variable>
   <xsl:apply-templates select="exsl:node-set($inNodes)" mode="_sc_post"/>
 </xsl:template>

 <!-- {{{ songcontent postprocessing: _sc_post -->
 <xsl:template match="/line" mode="_sc_post">
   <text:p text:style-name="{@format}">
     <xsl:apply-templates select="node()" mode="_sc_post"/><!-- kill all attribs -->
   </text:p><xsl:value-of select="$nl"/>
   <xsl:choose>
     <xsl:when test="@no>1 and @break">
       <page-cand break="{@break}">
         <xsl:call-template name="rep_it">
           <xsl:with-param name="inNodes"><text:p text:style-name="P3"/></xsl:with-param>
           <xsl:with-param name="anz" select="@no -1"/>
         </xsl:call-template>
       </page-cand><xsl:value-of select="$nl"/>
     </xsl:when>
     <xsl:when test="@no>1">
       <xsl:call-template name="rep_it">
         <xsl:with-param name="inNodes"><text:p text:style-name="P3"/></xsl:with-param>
         <xsl:with-param name="anz" select="@no -1"/>
       </xsl:call-template>
       <xsl:value-of select="$nl"/>
     </xsl:when>
     <xsl:when test="@break">
       <page-cand break="{@break}"/><xsl:value-of select="$nl"/>
     </xsl:when>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="/page-cand" mode="_sc_post"><!-- @block, @endpage, forced pagebreak -->
   <xsl:copy-of select="."/><xsl:value-of select="$nl"/>
 </xsl:template>

 <xsl:template match="/text()" mode="_sc_post"/>

 <xsl:template match="@*|node()" mode="_sc_post">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_sc_post"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="text()" mode="_sc_post">
   <xsl:value-of select="translate(normalize-space(.),'&#160;',' ')"/>
 </xsl:template>
 <!-- }}} -->

 <!--
<exsl:document href="/dev/stdout"><o><xsl:copy-of select="$inNodes"/></o></exsl:document>
 -->
 <!-- {{{ block tags -->
 <xsl:template match="vers" mode="_songcontent">
   <xsl:param name="config" select="/.."/>
   <xsl:variable name="this" select="$config/*[name()=name(current())]"/>
   <xsl:variable name="first"><first format='Pvers'><xsl:value-of select="@no"/><xsl:text>.</xsl:text><text:tab/></first></xsl:variable>
   <xsl:copy-of select="$this/pre/@*|$this/pre/node()"/>
   <xsl:call-template name="songcontent_block">
     <xsl:with-param name="ctxt" select="$config|.."/>
     <xsl:with-param name="first" select="func:strip-root(exsl:node-set($first)/first)"/>
     <xsl:with-param name="indent" select="func:strip-root($this/indent)"/>
   </xsl:call-template>
 </xsl:template>

 <xsl:template match="img" mode="_songcontent">
   <xsl:copy>
     <xsl:attribute name="odpName"><xsl:value-of select="func:get_image_name(.)"/></xsl:attribute>
     <xsl:copy-of select="@*"/>
   </xsl:copy>
   <page-cand break="-1"/>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ inline tags -->
 <xsl:template match="rep" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:variable name="tab"><text:tab/></xsl:variable>
   <xsl:text>|:</xsl:text><text:tab/>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent" select="$indent|exsl:node-set($tab)"/>
   </xsl:apply-templates>
   <xsl:choose>
     <xsl:when test="@no >2"><xsl:text> :|&#160;(</xsl:text><xsl:value-of select="@no"/><xsl:text>x)</xsl:text></xsl:when>
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

 <xsl:template match="spacer" mode="_songcontent_inline">
   <text:s text:c="{@no *3}"/>
 </xsl:template>
 
 <xsl:template match="hfill" mode="_songcontent_inline">
   <!-- TODO? this is just damage containment -->
   <text:s text:c="20"/>
 </xsl:template>
 
 <xsl:template match="xlate" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <xsl:text>(Übersetzung:&#160;</xsl:text>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   <xsl:text>)</xsl:text>
 </xsl:template>

 <xsl:template match="xlang" mode="_songcontent_inline">
   <xsl:param name="ctxt" select="/.."/>
   <xsl:param name="indent" select="/.."/>
   <text:span text:style-name="Txlang">
   <text:s text:c="4"/>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
     <xsl:with-param name="indent" select="$indent"/>
   </xsl:apply-templates>
   </text:span>
 </xsl:template>

 <!-- ignore certain known tags -->
 <xsl:template match="bible" mode="_songcontent_inline"/> 
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

 <!-- {{{ FUNCTION func:default (value, default)  -  return $value, if it is not empty (node-set), otherwise $default -->
 <func:function name="func:default">
   <xsl:param name="value"/>
   <xsl:param name="default"/>
   <func:result select="(exsl:node-set($value)|exsl:node-set($default))[1]"/>
 </func:function>
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

 <!-- {{{ FUNCTION func:make_attr(name,value) -->
 <func:function name="func:make_attr">
   <xsl:param name="name"/>
   <xsl:param name="value"/>
   <xsl:variable name="tmp"><hlp><xsl:attribute name="{$name}"><xsl:value-of select="$value"/></xsl:attribute></hlp></xsl:variable>
   <func:result select="exsl:node-set($tmp)/hlp/@*"/>
 </func:function>
 <!-- }}} -->
 
 <!-- {{{ FUNCTION func:get_attr(nodeset,name) -->
 <func:function name="func:get_attr">
   <xsl:param name="nodes"/>
   <xsl:param name="name"/>
   <func:result select="$nodes[not(self::*) and name()=$name]"/>
 </func:function>
 <!-- }}} -->

 <!-- {{{ FUNCTION func:strip-root(node)  -  but keep attribs -->
 <func:function name="func:strip-root">
   <xsl:param name="node"/>
   <func:result select="$node[1]/@*|$node[1]/node()"/>
 </func:function>
 <!-- }}} -->
 
 <!-- {{{ FUNCTION set:replace(nodeset,delnode,insnode)  - remove $delnode and insert instead $insnode -->
 <func:function name="set:replace">
   <xsl:param name="nodeset"/>
   <xsl:param name="delnode"/>
   <xsl:param name="insnode"/>
   <func:result select="set:leading($nodeset,$delnode)|$insnode|set:trailing($nodeset,$delnode)"/>
 </func:function>
 <!-- }}} -->

 <!-- {{{ FUNCTION func:escape_file (inText)  - convert äöü... -->
 <func:function name="func:escape_file">
   <xsl:param name="inText"/>
   <xsl:variable name="xfrom"> äöüÄÖÜßé,?'/</xsl:variable>
   <func:result>
     <xsl:apply-templates mode="_esc_file" select="thobi:separate($inText,$xfrom)"/>
   </func:result>
 </func:function>
 <xsl:template mode="_esc_file" match="split[@char='ä']">ae</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='ö']">oe</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='ü']">ue</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='Ä']">Ae</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='Ö']">Oe</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='Ü']">Ue</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='ß']">ss</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='é']">e</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char=' ']">_</xsl:template>
 <xsl:template mode="_esc_file" match="split"/>
 <!-- }}} -->
 
 <!-- {{{ FUNCTION func:get_image_name (img-Tag)  - return "the" image name for the image tag -->
 <func:function name="func:get_image_name">
   <xsl:param name="inTag"/>
   <!-- generate id from inTag and add the original extensition. -->
   <xsl:variable name="extension" select="thobi:separate($inTag/@href,'.')[preceding-sibling::split and self::text()][position()=last()]"/>
   <func:result>Pictures/pic<xsl:value-of select="generate-id($inTag)"/><xsl:if test="$extension">.</xsl:if><xsl:value-of select="$extension"/></func:result>
 </func:function>
 <!-- }}} -->

</xsl:stylesheet>
