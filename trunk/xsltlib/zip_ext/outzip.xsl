<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                xmlns:mine="thax.home/zip-ext"
                extension-element-prefixes="mine exsl">

 <xsl:output method="xml" encoding="iso-8859-1" indent="no"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

 <xsl:template match="*">
   <xsl:variable name="file">xy.zip</xsl:variable>
   <xsl:variable name="copyfiles">
     <copy fromhref="testdata" tohref="testdata"/>
   </xsl:variable>
<!--  <xsl:variable name="copyfiles" select="copy"/>-->
<!--   <xsl:variable name="copyfiles"/>-->
   <mine:doc-zip href="{$file}" copy-select="$copyfiles">
     <exsl:document href="tst" encoding="utf8" method="xml" indent="yes" omit-xml-declaration="yes">
       <test/>
     </exsl:document>
   </mine:doc-zip>
 </xsl:template>

</xsl:stylesheet>
