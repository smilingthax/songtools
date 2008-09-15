<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl">

 <!-- This "database" contains all the recognized language tags
      they are chosen consistent to ISO 639-1/2 (see documentation of @lang in songs.xml)
 -->

 <xsl:key name="langkey" match="lang" use="@short"/>
 <xsl:variable name="langTab">
   <lang short="de">Deutsch</lang>
   <lang short="en">Englisch</lang>
   <lang short="la">Latein</lang>
   <lang short="es">Spanisch</lang>
   <lang short="ca">Katalanisch</lang>
   <lang short="it">Italienisch</lang>
   <lang short="he">Hebräisch</lang>
   <lang short="fr">Französisch</lang>
   <lang short="sv">Schwedisch</lang>
   <lang short="sw">Swahili</lang>
   <lang short="ln">Lingála</lang>
   <lang short="zu">Zulu</lang>
   <lang short="bg">Bulgarisch</lang>
   <lang short="grc">Griechisch</lang><!-- Alt-griechisch -->
   <lang short="el">Griechisch</lang><!-- Neu-griechisch -->
 </xsl:variable>

 <xsl:template name="full-lang">
   <xsl:param name="lang"/>
   <xsl:for-each select="exsl:node-set($langTab)"><!-- context change-->
     <xsl:variable name="ret" select="key('langkey',$lang)"/>
     <xsl:if test="not($ret)">
       <xsl:message terminate="yes">Unknown language "<xsl:value-of select="$lang"/>"</xsl:message>
       <xsl:value-of select="$lang"/>
     </xsl:if>
     <xsl:value-of select="$ret/text()"/>
   </xsl:for-each>
 </xsl:template>
</xsl:stylesheet>
