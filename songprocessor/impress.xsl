<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:set="http://exslt.org/sets"
                xmlns:thobi="thax.home/split"
                xmlns:tools="thax.home/tools"
                xmlns:func="http://exslt.org/functions"
                xmlns:exsl="http://exslt.org/common"
                xmlns:dyn="http://exslt.org/dynamic"
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
                extension-element-prefixes="exsl func dyn set thobi mine ec zip tools">
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
 <xsl:variable name="preset_hlp" select="func:default($ps_doc/presets/preset[@name=$presetname],
                                                      $ps_doc/presets/preset[not(@name)])"/>
 <xsl:variable name="preset" select="func:if($preset_hlp/@fwd,
                                             $ps_doc/presets/preset[@name=$preset_hlp/@fwd],
                                             $preset_hlp)"/>  <!-- @fwd not found: empty preset. -->

 <xsl:include href="rights-full.xsl"/>
 <xsl:include href="lang-db.xsl"/>
 <xsl:strip-space elements="songs-out"/>

 <xsl:key name="img_by_href" match="img" use="@href"/> <!-- faster lookup -->

 <xsl:template match="/">
   <xsl:choose>
     <xsl:when test="$out_split > 0">
       <xsl:apply-templates select="songs-out/*" mode="file_multi"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:variable name="imgs" select="songs-out//img[count(.|key('img_by_href',@href)[1])=1]"/>
       <xsl:call-template name="output_odp">
         <xsl:with-param name="file" select="'allimpress.odp'"/>
         <xsl:with-param name="content_nodes">
           <xsl:apply-templates select="songs-out/*" mode="file_single"/>
         </xsl:with-param>
         <xsl:with-param name="black_back" select="count($preset/black)"/>
         <xsl:with-param name="add_files">
           <xsl:copy-of select="$preset/copy"/>
           <xsl:apply-templates select="$imgs" mode="get_add_images"/>
         </xsl:with-param>
         <xsl:with-param name="add_styles">
           <xsl:apply-templates select="songs-out/song/special[@type='odp-style']" mode="_do_special"/>
         </xsl:with-param>
       </xsl:call-template>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!--<xsl:with-param name="title"><xsl:apply-templates select="title" mode="inhalt"/></xsl:with-param>-->
 <xsl:template match="song" mode="file_single" name="filecontent">
   <xsl:param name="position" select="position()"/>
<!--  <xsl:call-template name="output_blkp"/>-->
   <xsl:call-template name="output_pages">
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
   <xsl:variable name="imgs">
     <xsl:apply-templates select="content//img" mode="get_add_images"/>
   </xsl:variable>
   <xsl:call-template name="output_odp">
     <xsl:with-param name="file" select="$file"/>
     <xsl:with-param name="content_nodes">
       <xsl:call-template name="filecontent">
         <xsl:with-param name="position" select="0"/>
       </xsl:call-template>
     </xsl:with-param>
     <xsl:with-param name="black_back" select="count($preset/black)"/>
     <xsl:with-param name="add_files" select="exsl:node-set($imgs)/copy[not(@tohref=preceding-sibling::copy/@tohref)]"/>
     <xsl:with-param name="add_styles">
       <xsl:apply-templates select="special[@type='odp-style']" mode="_do_special"/>
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
   <xsl:param name="impress_page_x" select="func:default($preset/set-fullimg/@x,0)"/>
   <xsl:param name="impress_page_y" select="func:default($preset/set-fullimg/@y,0)"/>
   <xsl:param name="impress_page_w" select="func:default($preset/set-fullimg/@width,28)"/>--><!-- everything in cm -->
   <xsl:param name="impress_page_h" select="func:default($preset/set-fullimg/@height,21)"/>
   <xsl:param name="odpName" select="func:get_image_name(.)"/>
   <xsl:param name="position" select="concat(position(),'_I')"/><!-- only relevant for standalone, TODO? -->
   <xsl:param name="xpos" select="func:default($preset/set-fullimg/@xpos,0.5)"/> <!-- 0 left, 0.5 center, 1 right -->
   <xsl:param name="ypos" select="func:default($preset/set-fullimg/@ypos,0.5)"/> <!-- also determines border distribution! -->
   <xsl:param name="legacy43" select="1"/> <!-- 1 is non-legacy -->
   <xsl:variable name="impress_page_ratio" select="$impress_page_w div $impress_page_h"/>
   <xsl:variable name="bgstyle">
     <xsl:choose>
       <xsl:when test="@blackbg">dp3</xsl:when>
       <xsl:when test="@whitebg">dp4</xsl:when>
       <xsl:otherwise>dp1</xsl:otherwise><!-- default: use bgcolor from master -->
     </xsl:choose>
   </xsl:variable>
   <xsl:variable name="img_border_x" select="func:default(@border,0)"/>
   <xsl:variable name="img_border_y" select="func:default(@border,0)*$legacy43"/>
   <xsl:variable name="img_info" select="tools:image-size(@href)"/>
   <xsl:variable name="img_ratio" select="$img_info/@width div $img_info/@height"/>
   <xsl:variable name="impress_w" select="func:if($img_ratio > $impress_page_ratio,
                                                  $impress_page_w - $img_border_x,
                                                  ($impress_page_h - $img_border_x)*$img_ratio)"/>
   <xsl:variable name="impress_h" select="func:if($img_ratio > $impress_page_ratio,
                                                  ($impress_page_w - $img_border_y) div $img_ratio,
                                                  $impress_page_h - $img_border_y)"/>
   <xsl:variable name="impress_x" select="$impress_page_x + $xpos*($impress_page_w - $impress_w)"/>
   <xsl:variable name="impress_y" select="$impress_page_y + $ypos*($impress_page_h - $impress_h)"/>
   <draw:page draw:name="{$position}" draw:style-name="{$bgstyle}" draw:master-page-name="Default">
     <office:forms form:automatic-focus="false" form:apply-design-mode="false"/>
     <draw:frame draw:style-name="gr1" draw:text-style-name="P2" draw:layer="layout" svg:width="{$impress_w}cm" svg:height="{$impress_h}cm" svg:x="{$impress_x}cm" svg:y="{$impress_y}cm">
       <draw:image xlink:href="{$odpName}" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
     </draw:frame>
   </draw:page>
 </xsl:template>

 <xsl:template mode="get_add_images" match="img">
   <xsl:variable name="img_info" select="tools:image-size(@href)"/>
   <copy fromhref="{@href}" tohref="{func:get_image_name(key('img_by_href',@href)[1])}" mime="{$img_info/@type}"/>
 </xsl:template>

 <xsl:template match="img" mode="_img_pager">
   <xsl:call-template name="output_img">
     <xsl:with-param name="impress_page_x" select="func:default($preset/set-partimg/@x,func:default($preset/set-fullimg/@x,0))"/>
     <xsl:with-param name="impress_page_y" select="func:default($preset/set-partimg/@y,func:default($preset/set-fullimg/@y,0)+0.1)"/>
     <xsl:with-param name="impress_page_w" select="
       func:if($preset/set-partimg/@aspectHack,28,
         string(func:default($preset/set-partimg/@width,func:default($preset/set-fullimg/@width,28)))
       )"/>
     <xsl:with-param name="impress_page_h" select="func:default($preset/set-partimg/@height,19.23)"/>
     <xsl:with-param name="xpos" select="func:default($preset/set-partimg/@xpos,func:default($preset/set-fullimg/@ypos,0.5))"/>
     <xsl:with-param name="ypos" select="func:default($preset/set-partimg/@ypos,func:default($preset/set-fullimg/@ypos,0.5))"/>
     <xsl:with-param name="odpName" select="@odpName"/>
     <xsl:with-param name="legacy43" select="func:default($preset/set-partimg/@aspectHack,1)"/>
   </xsl:call-template>
 </xsl:template>

 <!-- {{{ TEMPLATE output_odp (file, content_nodes, black_back)  - outputs an .odp (>file) with black(>black_back==1) or white(0) background using >content_nodes. There is also add_files -->
 <xsl:template name="output_odp">
   <xsl:param name="file"/>
   <xsl:param name="content_nodes" select="."/>
   <xsl:param name="black_back"/>
   <xsl:param name="add_files"/>
   <xsl:param name="add_styles"/>
   <zip:doc-zip href="{$file}" copy-select="$add_files">
     <exsl:document href="zip:store/mimetype" method="text"><!-- has to be first, and uncompressed! -->
       <xsl:text>application/vnd.oasis.opendocument.presentation</xsl:text>
     </exsl:document>
     <exsl:document href="content.xml" encoding="UTF-8" method="xml" indent="yes">
       <xsl:apply-templates select="document(func:default($preset/content,'oo-template/content.xml'))" mode="_output_odp_content">
         <xsl:with-param name="content_nodes" select="$content_nodes"/>
         <xsl:with-param name="style_nodes" select="$add_styles"/>
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

 <xsl:template match="office:automatic-styles" mode="_output_odp_content">
   <xsl:param name="style_nodes" select="."/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_output_odp_content"/>
     <xsl:copy-of select="$style_nodes"/>
   </xsl:copy>
 </xsl:template>

 <!-- {{{ FUNCTION func:_ooc_collect_parents_self(node) -->
 <func:function name="func:_ooc_collect_parents_self"> <!-- function, to be able to return a nodeset of input nodes w/o id(...) tricks -->
   <xsl:param name="node"/>
   <xsl:choose>
     <xsl:when test="$node/@copy-parent">
       <xsl:variable name="parent" select="$node/preceding-sibling::style:style[@style:name=$node/@copy-parent]"/> <!-- parent must be defined earlier, because nodeset will be enumerated in document order! -->
       <xsl:if test="count($parent|$node) != 2 or $parent/@style:family != $node/@style:family">
         <xsl:message terminate="yes">Bad copy-parent</xsl:message>
       </xsl:if>
       <func:result select="func:_ooc_collect_parents_self($parent)|$node"/>
     </xsl:when>
     <xsl:otherwise>
       <func:result select="$node"/>
     </xsl:otherwise>
   </xsl:choose>
 </func:function>
 <!-- }}} -->

 <xsl:template match="office:automatic-styles/style:style" mode="_output_odp_content">
   <xsl:copy>
     <xsl:choose>
       <xsl:when test="@copy-parent">
         <xsl:copy-of select="@*[not(name()='copy-parent')]"/>
         <xsl:for-each select="exsl:group-by-name(func:_ooc_collect_parents_self(.)/*)">
           <xsl:copy>
             <xsl:copy-of select="*/@*"/>
             <xsl:copy-of select="exsl:group-by-name(*/*)/*[last()]"/>
           </xsl:copy>
         </xsl:for-each>
       </xsl:when>
       <xsl:otherwise>
         <xsl:copy-of select="@*|node()"/>
       </xsl:otherwise>
     </xsl:choose>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="node()" mode="_output_odp_content">
   <xsl:param name="content_nodes"/>
   <xsl:param name="style_nodes"/>
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:apply-templates select="node()" mode="_output_odp_content">
       <xsl:with-param name="content_nodes" select="$content_nodes"/>
       <xsl:with-param name="style_nodes" select="$style_nodes"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="style:style[@style:name='Default-background']/style:graphic-properties" mode="_output_odp_style">
   <xsl:param name="black_back"/>
   <xsl:choose>
     <xsl:when test="$black_back > 0">
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

 <xsl:template match="office:master-styles/style:master-page" mode="_output_odp_style">
   <xsl:copy>
     <xsl:copy-of select="@*"/>
     <xsl:copy-of select="$preset/premaster/@*|$preset/premaster/node()"/>
<!--     <xsl:apply-templates select="node()" mode="_output_odp_style"/>-->
     <xsl:copy-of select="node()"/>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*|node()" mode="_output_odp_style">
   <xsl:param name="black_back"/>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_output_odp_style">
       <xsl:with-param name="black_back" select="$black_back"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>
 <!-- }}} -->

 <xsl:template name="output_pages">
   <xsl:param name="source"/>
   <xsl:param name="lbfrom"/>
   <xsl:param name="position" select="position()"/>
   <!--  select="title[1]/text()" -->
   <xsl:variable name="inHasImageOrSpecial">
     <xsl:apply-templates select="img" mode="file_single"/>
     <xsl:apply-templates select="special[@type='odp-page']" mode="_do_special">
       <xsl:with-param name="position" select="$position"/>
     </xsl:apply-templates>
   </xsl:variable>
   <xsl:choose>
     <xsl:when test="count(exsl:node-set($inHasImageOrSpecial)/node())"> <!-- if we have out-ouf-content image/special, discard all contents! -->
       <xsl:copy-of select="$inHasImageOrSpecial"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:for-each select="content">  <!-- or: content[not(exsl:node-set($...)/node())] -->
         <xsl:variable name="copy">
           <xsl:call-template name="copyright">
             <xsl:with-param name="inSong" select=".."/>
             <xsl:with-param name="lang" select="@lang"/>
             <xsl:with-param name="withArrangement" select="count(img)"/>
             <xsl:with-param name="withCcli" select="count($preset/ccli)"/>
           </xsl:call-template>
         </xsl:variable>
         <xsl:variable name="inNodes">
           <xsl:apply-templates select="."/>
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
           <xsl:with-param name="inCopyright">
             <xsl:if test="$copy!=''">
               <xsl:text>� </xsl:text>
<!--               <xsl:text>Copyright: </xsl:text>-->
               <xsl:value-of select="$copy"/>
             </xsl:if>
           </xsl:with-param>
           <xsl:with-param name="inSource" select="$source"/>
           <xsl:with-param name="inLBfrom" select="exsl:node-set($lbfrom)/*[1]"/>
           <xsl:with-param name="position" select="concat($position,'_',@lang,position())"/>
         </xsl:apply-templates>
       </xsl:for-each>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <!-- {{{ the page template -->
 <xsl:template match="/page" mode="_output_page">
   <xsl:param name="inCopyright"/><!-- Copyright: -->
   <xsl:param name="inSource"/><!-- Aus: -->
   <xsl:param name="inLBfrom"/><!-- Liednummer /Gr�n,Rot -->
   <xsl:param name="position"/><!-- Liedposition (f�r einzigartigen seitennamen) -->
   <xsl:variable name="tr1" select="set:leading(../page,.)"/>
   <xsl:variable name="tr2" select=".|set:trailing(../page,.)"/>
   <xsl:variable name="tr3" select="set:trailing($tr1,$tr1[@endpage][1])"/>
   <xsl:variable name="tr4" select="set:leading($tr2,$tr2[@endpage][1])|$tr2[@endpage][1]"/>
<!--   <xsl:variable name="inPgOf" select="func:if(count($tr3)+count($tr4)>1,concat(count($tr3)+1,'/',count($tr3)+count($tr4)))"/>-->
   <xsl:variable name="inPgOf" select="concat(count($tr3)+1,'/',count($tr3)+count($tr4))"/>
   <xsl:variable name="images-hlp">
     <xsl:apply-templates select="img" mode="_img_pager"/>
   </xsl:variable>
   <xsl:variable name="images" select="exsl:node-set($images-hlp)"/>
   <xsl:variable name="style" select="func:default($images/draw:page/@draw:style-name,'dp1')"/>
   <xsl:variable name="lb">
     <xsl:choose>
       <xsl:when test="not($preset/set-lb)"/>
       <xsl:when test="$images/draw:page and not(img/@force-lb)"/> <!-- should be only one img, because _songcontent adds page-break after img -->
       <xsl:when test="$inLBfrom[self::IWDD] and ($style='dp4' or ($style='dp1' and not(count($preset/black))))">PLBgreenW</xsl:when>
       <xsl:when test="$inLBfrom[self::GML] and ($style='dp4' or ($style='dp1' and not(count($preset/black))))">PLBredW</xsl:when>
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
     <xsl:if test="$preset/set-from">
       <draw:frame draw:style-name="gr3" draw:layer="layout">
         <xsl:copy-of select="$preset/set-from/@*|$preset/set-from/node()"/>
         <draw:text-box>
           <text:p text:style-name="P1"><xsl:copy-of select="$inSource"/></text:p><!-- TODO? handle formatting? -->
         </draw:text-box><xsl:value-of select="$nl"/>
       </draw:frame><xsl:value-of select="$nl"/>
     </xsl:if>
     <draw:frame draw:style-name="gr3" draw:text-style-name="P5" draw:layer="layout">
       <xsl:copy-of select="$preset/set-pgof/@*|$preset/set-pgof/node()"/>
       <draw:text-box>
         <text:p text:style-name="P5"><xsl:value-of select="$inPgOf"/></text:p>
       </draw:text-box><xsl:value-of select="$nl"/>
     </draw:frame><xsl:value-of select="$nl"/>
     <!-- Rotes/Gr�nes Lb -->
     <xsl:if test="string-length($lb)">
       <draw:frame draw:style-name="gr2" draw:text-style-name="{$lb}" draw:layer="layout">
<!--
         <xsl:copy-of select="$preset/set-lb/@*|$preset/set-lb/node()"/>
-->
         <xsl:copy-of select="func:default($preset/set-lb-img[$images/draw:page],$preset/set-lb)/@*|
                              func:default($preset/set-lb-img[$images/draw:page],$preset/set-lb)/node()"/>
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
   <xsl:variable name="nextEnd" select="set:leading($inNodes[self::page-cand],$inNodes[self::page-cand][@endpage or @break &lt; 0])|
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

 <xsl:template match="node()" mode="_page_fix">
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
                             count($tr1[child::text:span[@text:style-name='Txlang']])*0.5"/>
     </xsl:attribute>
     <xsl:attribute name="self"><!-- number of lines contained inside this <page-cand>..</page-cand> -->
       <xsl:value-of select="func:if(node(),count(text:p[@text:style-name!='P3'])*2+
                                            count(text:p[@text:style-name='P3'])
                                           ,0)"/>
     </xsl:attribute>
     <xsl:if test="@endpage and following-sibling::*">
       <xsl:message terminate="yes">unexpected nodes after /page-cand/@endpage</xsl:message>
     </xsl:if>
     <xsl:if test="following-sibling::*[1][self::page-cand]/@block">
       <xsl:attribute name="block">1</xsl:attribute>
     </xsl:if>
     <xsl:if test="following-sibling::*[1][self::page-cand]/@endpage">
       <xsl:attribute name="endpage">1</xsl:attribute>
     </xsl:if>
     <xsl:copy-of select="@*[name()!='no']|node()"/> <!-- may contain @block,@endpage -->
   </xsl:copy>
   <xsl:value-of select="$nl"/>
 </xsl:template>

 <!-- very first page-cand is not a viable break (except for @endpage!): remove -->
 <xsl:template match="/page-cand[@block][not(preceding-sibling::*)]" mode="_break_calc"/>
 <!-- this exactly matches the second page-cand from the @block,@endpage pull-up-logic in match="/page-cand" -->
 <xsl:template match="/page-cand[@block or @endpage][preceding-sibling::*[1][self::page-cand]]" mode="_break_calc"/>

 <xsl:template match="node()" mode="_break_calc">
   <xsl:copy-of select="."/>
 </xsl:template>
 <!-- }}} -->

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
   <xsl:apply-templates select="../title[@lang=mine:main_lang(current()/@lang)]">
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
       <pre><page-cand block="1"/></pre>
       <first text:style-name="P2"/>
       <indent text:style-name="P2"/>
     </base>
     <vers>
       <pre><page-cand block="1"/></pre>
       <first text:style-name='Pvers'><num fmt="#"/><xsl:text>.</xsl:text><text:tab/></first>
       <indent text:style-name='Pvers'><text:tab/></indent>
     </vers>
     <refr>
       <pre><page-cand block="1"/></pre>
       <first text:style-name='Prefr'><xsl:text>Refr:</xsl:text><text:tab/></first>
       <indent text:style-name='Prefr'><text:tab/></indent>
     </refr>
     <bridge>
       <pre><page-cand block="1"/></pre>
       <first text:style-name='Pbridge'><xsl:text>Bridge:</xsl:text><text:tab/></first>
       <indent text:style-name='Pbridge'><text:tab/></indent>
     </bridge>
     <ending>
       <pre><page-cand block="1"/></pre>
       <first text:style-name='Pending'><xsl:text>Schluss:</xsl:text><text:tab/></first>
       <indent text:style-name='Pending'><text:tab/></indent>
     </ending>
     <quotes lang="en" start="&#x201c;" end="&#x201d;"/>
     <quotes lang="de" start="&#x201e;" end="&#x201c;"/>
     <tick><xsl:text>&#x2019;</xsl:text></tick>
     <rep>
       <start>|:<text:tab/></start>
       <simpleend> :|</simpleend>
       <end> :|&#160;(<num fmt="#"/>x)</end>
       <indent><text:tab/></indent>
     </rep>
   </xsl:variable>
   <xsl:variable name="inNodes">
     <xsl:apply-templates select="*" mode="_songcontent">
       <xsl:with-param name="ctxt" select="exsl:node-set($config)|."/>
     </xsl:apply-templates>
     <page-cand endpage="1"/>
   </xsl:variable>
   <xsl:apply-templates select="exsl:node-set($inNodes)/*" mode="_sc_post">
     <xsl:with-param name="ctxt" select="exsl:node-set($config)|."/>
   </xsl:apply-templates>
 </xsl:template>

 <!-- {{{ songcontent postprocessing: _sc_post -->
 <xsl:template match="line" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:param name="solrep" select="@solrep|exsl:node-set(0)[not(current()/@solrep)]"/> <!-- @solrep not always present; TRICK: variable not allowed here... -->
   <xsl:param name="repindent" select="sum(preceding-sibling::*/@rep) + $solrep"/>
   <xsl:variable name="justxlang" select="not(../line[not(@xlang)])"/>

   <xsl:variable name="isfirst" select="@firstpos and (not(@xlang) or $justxlang)"/>
   <xsl:variable name="blockfmt" select="$ctxt/block/first[$isfirst]|$ctxt/block/indent[not($isfirst)]"/>
   <xsl:variable name="indent">
     <xsl:copy-of select="$blockfmt/node()"/>
     <xsl:call-template name="rep_it">
       <xsl:with-param name="inNodes" select="$ctxt/rep/indent/node()"/>
       <xsl:with-param name="anz" select="$repindent - $solrep"/>
     </xsl:call-template>
   </xsl:variable>

   <xsl:if test="not($blockfmt/@text:style-name)">
     <xsl:message terminate="yes">text:style-name is required</xsl:message>
   </xsl:if>

   <text:p text:style-name="{concat($blockfmt/@text:style-name,func:if(@xlang,'-xlang'))}">
     <xsl:copy-of select="$indent"/>
     <xsl:apply-templates select="node()" mode="_sc_post">
       <xsl:with-param name="ctxt" select="$ctxt"/>
     </xsl:apply-templates>
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

 <xsl:template match="/img" mode="_sc_post">
   <xsl:copy-of select="."/><xsl:value-of select="$nl"/>
 </xsl:template>

<!-- problem: overrides s-liner templates
 <xsl:template match="@*|node()" mode="_sc_post">
   <xsl:param name="ctxt"/>
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_sc_post">
       <xsl:with-param name="ctxt" select="$ctxt"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template> -->

 <xsl:template match="line/text()" mode="_sc_post">
   <xsl:value-of select="translate(normalize-space(.),'&#160;',' ')"/>
 </xsl:template>

 <xsl:template match="spacer" mode="_sc_post">
   <text:s text:c="{@no *3}"/>
 </xsl:template>

 <xsl:template match="hfill" mode="_sc_post">
   <!-- TODO? this is just damage containment -->
   <text:s text:c="20"/>
 </xsl:template>
 <!-- }}} -->

 <!--
<exsl:document href="/dev/stdout"><o><xsl:copy-of select="$inNodes"/></o></exsl:document>
 -->
 <!-- {{{ block tags -->
 <xsl:template match="img" mode="_songcontent">
   <xsl:param name="ctxt"/>
   <xsl:copy>
     <xsl:attribute name="odpName"><xsl:value-of select="func:get_image_name(key('img_by_href',@href)[1])"/></xsl:attribute>
     <xsl:copy-of select="@*"/>
   </xsl:copy>
   <page-cand break="-1"/>
 </xsl:template>
 <!-- }}} -->

 <!-- {{{ inline tags -->
 <xsl:template match="xlate" mode="_songcontent_inline">
   <xsl:param name="ctxt"/>
   <xsl:text>(�bersetzung:&#160;</xsl:text>
   <xsl:apply-templates select="*|text()" mode="_songcontent_inline">
     <xsl:with-param name="ctxt" select="$ctxt"/>
   </xsl:apply-templates>
   <xsl:text>)</xsl:text>
 </xsl:template>

 <!-- ignore certain known tags -->
 <xsl:template match="bible" mode="_songcontent_inline"/>
 <!-- }}} -->

 <!-- {{{ helpers for <special> interpolation -->
 <xsl:template match="song/special" mode="_do_special">
   <xsl:param name="position"/>
   <xsl:variable name="ctxt">
     <unique><xsl:value-of select="generate-id(..)"/>__</unique>
     <position><xsl:value-of select="$position"/></position>
   </xsl:variable>
   <!-- only if <song special="odp"> is set -->
   <xsl:if test="contains(concat(' ',../@special,' '),' odp ')">
     <xsl:apply-templates select="node()" mode="_special_interpolate">
       <xsl:with-param name="ctxt" select="exsl:node-set($ctxt)"/>
       <xsl:with-param name="uniquifyAttrs" select="dyn:evaluate(@uniquify)"/>
       <xsl:with-param name="interpolateNodes" select="dyn:evaluate(@interpolate)"/>
     </xsl:apply-templates>
   </xsl:if>
 </xsl:template>

 <xsl:template match="node()" mode="_special_interpolate">
   <xsl:param name="ctxt"/>
   <xsl:param name="uniquifyAttrs"/>
   <xsl:param name="interpolateNodes"/><!-- attrs or nodes -->
   <xsl:copy>
     <xsl:apply-templates select="@*|node()" mode="_special_interpolate">
       <xsl:with-param name="ctxt" select="$ctxt"/>
       <xsl:with-param name="uniquifyAttrs" select="$uniquifyAttrs"/>
       <xsl:with-param name="interpolateNodes" select="$interpolateNodes"/>
     </xsl:apply-templates>
   </xsl:copy>
 </xsl:template>

 <xsl:template match="@*" mode="_special_interpolate">
   <xsl:param name="ctxt"/>
   <xsl:param name="uniquifyAttrs"/>
   <xsl:param name="interpolateNodes"/>
   <xsl:choose>
     <xsl:when test="set:has-same-node(.,$uniquifyAttrs)">
       <xsl:attribute name="{name()}">
         <xsl:value-of select="$ctxt/unique"/>
         <xsl:value-of select="."/>
       </xsl:attribute>
     </xsl:when>
     <xsl:when test="set:has-same-node(.,$interpolateNodes)">
       <xsl:attribute name="{name()}">
         <xsl:value-of select="dyn:evaluate(.)"/>
       </xsl:attribute>
     </xsl:when>
     <xsl:otherwise>
       <xsl:copy-of select="."/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="text()" mode="_special_interpolate">
   <xsl:param name="ctxt"/>
   <xsl:param name="uniquifyAttrs"/>
   <xsl:param name="interpolateNodes"/>
   <xsl:choose>
     <xsl:when test="set:has-same-node(..,$interpolateNodes)">
       <xsl:copy-of select="dyn:evaluate(.)"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:copy-of select="."/>
     </xsl:otherwise>
   </xsl:choose>
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

 <!-- {{{ FUNCTION exsl:group-by-name(nodeset) -->
 <func:function name="exsl:group-by-name">
   <xsl:param name="nodeset"/>
   <xsl:variable name="hlp">
     <xsl:for-each select="$nodeset">
       <xsl:copy><xsl:value-of select="name()"/></xsl:copy>
     </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="ret">
     <xsl:for-each select="set:distinct(exsl:node-set($hlp)/*)">
       <xsl:copy>
         <xsl:copy-of select="$nodeset[name()=current()]"/>
       </xsl:copy>
     </xsl:for-each>
   </xsl:variable>
   <func:result select="exsl:node-set($ret)/*"/>
 </func:function>
 <!-- }}} -->

 <!-- {{{ FUNCTION func:default (value, default)  -  return $value, if it is not empty (node-set), otherwise $default -->
 <func:function name="func:default">
   <xsl:param name="value"/>
   <xsl:param name="default"/>
   <func:result select="exsl:node-set($value)|exsl:node-set($default)[not($value)]"/>
 </func:function>
 <!-- }}} -->

 <!-- {{{ FUNCTION func:if (do_first,first [,second])  -  return $first or $second -->
 <func:function name="func:if">
   <xsl:param name="do_first"/>
   <xsl:param name="first"/>
   <xsl:param name="second"/>
   <xsl:choose>
     <xsl:when test="$do_first">
       <func:result select="$first"/>
     </xsl:when>
     <xsl:otherwise>
       <func:result select="$second"/>
     </xsl:otherwise>
   </xsl:choose>
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
   <xsl:param name="nodeset"/>
   <xsl:param name="name"/>
   <func:result select="$nodeset[not(self::*) and name()=$name]"/>
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

 <!-- {{{ FUNCTION func:escape_file (inText)  - convert ���... -->
 <func:function name="func:escape_file">
   <xsl:param name="inText"/>
   <xsl:variable name="xfrom"> ��������,?'/</xsl:variable>
   <func:result>
     <xsl:apply-templates mode="_esc_file" select="thobi:separate($inText,$xfrom)"/>
   </func:result>
 </func:function>
 <xsl:template mode="_esc_file" match="split[@char='�']">ae</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='�']">oe</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='�']">ue</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='�']">Ae</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='�']">Oe</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='�']">Ue</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='�']">ss</xsl:template>
 <xsl:template mode="_esc_file" match="split[@char='�']">e</xsl:template>
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

 <func:function name="mine:main_lang"> <!-- {{{ main_lang('en+de')='en'   ('en+de',3)='de' -->
   <xsl:param name="lang"/>
   <xsl:param name="num" select="1"/>
   <xsl:variable name="split" select="thobi:separate($lang,'+')"/>
   <func:result select="$split[$num][self::text()]"/>
 </func:function>
 <!-- }}} -->

</xsl:stylesheet>
