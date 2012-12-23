numberIt:  (shet.xsl)
<vers>          -> <vers no="">
<bridge>        -> <bridge no="">
<ending>        -> <ending no="">
<refr>          -> <refr no="">

#include "processor.h"

substXlang:
[...<br/>]
^...<br/tag>     ->  <xlang>...</xlang><br/tag>    /* note: no <br> after preceding line! */
/* TODO?  ^^other lang ... */

normalizeBr:
<content>WS"\n"    -> <content>"\n"
<block>WS"\n"      -> <block>"\n"
</block>(WS"\n")*  -> <br></block>
(WS"\n")*</block>(WS"\n")*   -> <br></block>
(WS"\n")*          -> <br no="*" break="1"/>"\n"
<bf/>              ->

substSpacer:
"*"WS*          -> <spacer no="*"/>

substAkk:
"|"CHAR         -> <akk note="C#/D#">CHAR</akk>
/* more to come! */

comments:  (at different places)
<!-- -->WS"\n"                    -> <!-- -->"\n"
(WS"\n")*<!-- -->WS"\n"(WS"\n")*  -> <br no="*+*">"\n"?<!-- -->"\n"

ProcTraverse::flush():
  ... state machine to encapsulate everything not in a block tag into <base></base>

substQuote:  (in shet.xsl)
"\"".*"\""      -> <sq/>*<eq/>

|<-- done, TODO: do <akk> as NODE_AKK (? why); TODO: rework using the real xml-tree; TODO!: redo attrib as (kind of) argument for openNode
<bf suppress="1"/>  ->
OutputWhitespaceNormalization including empty-akk-WS-adjust.

OutputSubstitute:
(tex: "_"->"\\_", "\n *"->"\n")

