<?xml version="1.0" encoding="utf-8"?>
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
   <book short="FJ4">Feiert Jesus! 4</book>
   <book short="FJTOGO">Feiert Jesus! to go</book>
   <book short="ILJ1">In love with Jesus</book>
   <book short="ILJ2">In love with Jesus 2</book>
   <book short="DBH1">Du bist Herr 1</book>
   <book short="DBH2">Du bist Herr 2</book>
   <book short="DBH3">Du bist Herr 3</book>
   <book short="DBH4">Du bist Herr 4</book>
   <book short="DBH5">Du bist Herr 5</book>
   <book short="EKG">Evangelisches Kirchengesangbuch</book> <!-- altes gesangbuch (BY?) -->
   <book short="EG">Evangelisches Gesangbuch</book>
   <book short="FL">Feiern &amp; Loben</book>
   <book short="IWDD">Ich will dir danken (grünes Liederbuch)</book> <!-- (grünes Liederbuch) -->
   <book short="GmL">Gemeindelieder (rotes Liederbuch)</book>
   <book short="NGmL">Neue Gemeindelieder</book>
   <book short="Mneu">Neues Gesangbuch für die Evangelisch-methodistische Kirche</book>
   <book short="SMU">Singt mit uns</book>
   <book short="SDLDL1">Singt das Lied der Lieder, Band 1</book>
   <book short="SDLDL2">Singt das Lied der Lieder, Band 2</book>
   <book short="SDLDL3">Singt das Lied der Lieder, Band 3</book>
   <book short="JUF">Jesus - unsere Freude</book>
   <book short="Lut84">Lutherbibel 1984</book>
   <book short="Wied03">Wiedenester Jugendliederbuch 2002/2003</book>
   <book short="Wied15">Wiedenester Jugendliederbuch 15. Ausgabe</book>
   <book short="Wied16">Wiedenester Jugendliederbuch 16. Ausgabe</book>
   <book short="Wied17">Wiedenester Jugendliederbuch 17. Ausgabe</book>
<!-- preliminary: -->
   <book short="CTW1+2">Come To Worship 1 + 2 (Melodie)</book>
   <book short="UL">Unser Liederbuch</book>
   <book short="ML2">Meine Liederbuch 2: Ökumene heute</book>
   <book short="SGIDH">So groß ist der Herr</book>
   <!-- GL: Gemeindelieder[GmL], Gotteslob[GL], Glaubenslieder[GlL] -->
   <book short="LL">Lebenslieder</book>
   <book short="LLP">Lebenslieder Plus</book>
   <book short="LUH">Lehre uns Herr</book>
   <book short="SVJ0">Singt von Jesus (1971)</book> <!-- 1971 -->
   <book short="SVJ1">Singt von Jesus (1981)</book> <!-- 1981 -->
   <book short="SVJ2">Singt von Jesus, Band 2</book> <!-- 1990? -->
   <book short="SVJ3">Singt von Jesus, Band 3</book>
   <book short="GL">Gotteslob (Katholisches Gesangbuch 1975)</book>
   <book short="GL13">Gotteslob (Katholisches Gesangbuch 2013)</book>
   <book short="LDL">Lied des Lebens</book>
   <book short="WT4">Worship Together Songbook 4.0</book>
   <book short="Gll">Glaubenslieder</book>
   <book short="Gll2">Glaubenslieder 2</book>
   <book short="KFJ">Kinder feiern Jesus</book>
   <book short="DGL">Das gute Land</book>
   <book short="KAA">Kommt, atmet auf</book>
   <book short="MLDL">Meine Lieder - Deine Lieder</book>
   <book short="DBHK1">Du bist Herr Kids 1</book>
   <book short="DBHK2">Du bist Herr Kids 2</book>
<!-- unassigned:
   <book short="ML1">Meine Liederbuch (1:) für heute und morgen</book>
   <book short=""></book>
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
