<?xml version="1.0" encoding="iso-8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common"
                extension-element-prefixes="exsl">

 <!-- This "database" contains all the recognized Songbooks
 -->

 <xsl:key name="fromkey" match="book" use="@short"/>
 <xsl:variable name="bookTab">
   <book short="FJ1">Feiert Jesus!</book>
   <book short="FJ2">Feiert Jesus! 2</book>
   <book short="FJ3">Feiert Jesus! 3</book>
   <book short="ILJ1">In love with Jesus</book>
   <book short="ILJ2">In love with Jesus 2</book>
   <book short="DBH1">Du bist Herr 1</book>
   <book short="DBH2">Du bist Herr 2</book>
   <book short="DBH3">Du bist Herr 3</book>
   <book short="DBH4">Du bist Herr 4</book>
   <book short="DBH5">Du bist Herr 5</book>
   <book short="EKG">Evangelisches Kirchengesangbuch</book> <!-- altes gesangbuch -->
   <book short="EG">Evangelisches Gesangbuch</book>
   <book short="FL">Feiern &amp; Loben</book>
   <book short="Iwdd">Ich will dir danken</book> <!-- (grünes Liederbuch) -->
   <book short="Mneu">Neues Gesangbuch für die Evangelisch-methodistische Kirche</book>
   <book short="Smu">Singt mit uns</book>
   <book short="SdLdL1">Singt das Lied der Lieder, Band 1</book>
   <book short="SdLdL2">Singt das Lied der Lieder, Band 2</book>
   <book short="SdLdL3">Singt das Lied der Lieder, Band 3</book>
   <book short="JuF">Jesus - unsere Freude</book>
   <book short="Lut84">Lutherbibel 1984</book>
<!-- preliminary: -->
   <book short="Wied03">Wiedenester Jugendliederbuch 2002/2003</book>
   <book short="Wied15">Wiedenester Jugendliederbuch 15. Ausgabe</book>
   <book short="Ctw1+2">Come To Worship 1 + 2 (Melodie)</book>
   <book short="UL">Unser Liederbuch</book> 
   <book short="ML2">Meine Liederbuch 2: Ökumene heute</book> 
   <!-- GL: Gemeindelieder[GmL], Gotteslob[GL], Glaubenslieder[GlL] -->
   <book short="GL">Gemeindelieder (rotes Liederbuch)</book> 
   <book short="GLneu">Neue Gemeindelieder</book>
<!--   <book short="GL">Gotteslob (Katholisches Gesangbuch)</book>-->
<!-- unassigned: 
   <book short="SvJ0">Singt von Jesus</book> <!-- 1971 -->
   <book short="SvJ1">Singt von Jesus</book> <!-- 1981 -->
   <book short="SvJ2">Singt von Jesus, Band 2</book> <!-- 1990? -->
   <book short="SvJ3">Singt von Jesus, Band 3</book>
   <book short="Ll">Lebenslieder</book>
   <book short="LlP">Lebenslieder Plus</book>
   <book short="LuH">Lehre uns Herr</book>
   <book short="DgL">Das gute Land</book>
   <book short="LdL">Lied des Lebens</book>
   <book short="ML1">Meine Liederbuch (1:) für heute und morgen</book> 
   <book short=""></book> 
-->
<!-- maybe: 
   <book short="Rot" see="GL"/>
   <book short="Grün" see="Iwdd"/>
-->
 </xsl:variable>

 <xsl:template name="full-from">
   <xsl:param name="book"/>
   <xsl:for-each select="exsl:node-set($bookTab)"><!-- context change-->
     <xsl:variable name="ret" select="key('fromkey',$book)"/>
     <xsl:if test="not($ret)">
       <xsl:message terminate="yes">Unknown Songbook "<xsl:value-of select="$book"/>"</xsl:message>
       <xsl:value-of select="$book"/>
     </xsl:if>
     <xsl:value-of select="$ret/text()"/>
   </xsl:for-each>
 </xsl:template>
</xsl:stylesheet>
