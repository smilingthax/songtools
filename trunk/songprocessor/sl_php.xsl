<?xml version="1.0" encoding="iso8859-1"?>
<!-- Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

 <xsl:output method="text" encoding="iso8859-1"/>
 <xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>
 <xsl:strip-space elements="songs-out"/>

 <xsl:template match="/">
  <xsl:text>
  &lt;html>
   &lt;head>
    &lt;title>songs&lt;/title>
   &lt;/head>
   &lt;body>
    &lt;table>
    &lt;? $tcnt=1; </xsl:text><xsl:apply-templates select="songs-out/*" mode="list"/><xsl:text>
          $col[0]="#ffffff"; $col[1]="#afffaf"; $col[2]="#bfbfff"; $col[3]="#ffafaf"; $scnt=1;
          $txt[0]="Normal"; $txt[1]="Chris"; $txt[2]="David"; $txt[3]="Extra";
    $fn="/tmp/stat.file";
    @include $fn;
    if ($song) {
      $songlist[$songname[$song]]=$do;
    }
    for ($iB=1; $iB&lt;$tcnt; $iB++) {
      echo "&lt;tr>&lt;td bgcolor=\"".$col[$songlist[$songname[$iB]]]."\">".$realname[$iB];
      for ($iA=0; $iA&lt;4; $iA++) {
        echo "&lt;/td>&lt;td bgcolor=\"".$col[$iA]."\">&lt;a href=\"".$PHP_SELF."?id=".$id."&amp;iid=".$iid."&amp;song=".$iB."&amp;do=".$iA."\">".$txt[$iA]."&lt;/a>";
      } 
      echo "&lt;/td>&lt;/tr>\n";
    }
    if ($song) { 
      $f=fopen($fn,"w"); 
      fwrite($f,"&lt;"."?"); 
      for ($iA=1; $iA&lt;$tcnt; $iA++) {
        fwrite($f,'$songlist["'.$songname[$iA].'"]='.((int)$songlist[$songname[$iA]]).";\n");
      }
      fwrite($f,"?".">"); 
      fclose($f); } ?>
    &lt;/table>
   &lt;/body>
  &lt;/html>
  </xsl:text>
 </xsl:template>

 <xsl:template match="song" mode="list">
   <xsl:variable name="file"><xsl:value-of select="translate(title[1]/text(),' äöüÄÖÜß,?','_aouAOUs')"/></xsl:variable>
   <xsl:text>$songname[$tcnt]="</xsl:text><xsl:value-of select="$file"/><xsl:text>";</xsl:text>
   <xsl:text>$realname[$tcnt++]="</xsl:text><xsl:apply-templates select="title"/><xsl:text>";
</xsl:text>
 </xsl:template>

 <xsl:template match="song/title">
   <xsl:value-of select="."/><xsl:text>&lt;br></xsl:text><xsl:value-of select="$nl"/>
 </xsl:template>

</xsl:stylesheet>
