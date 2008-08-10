#include "processor.h"

substBr:
<content>WS"\n"    -> <content>"\n"
<block>WS"\n"      -> <block>"\n"
</block>(WS"\n")*  -> <br></block>
(WS"\n")*</block>(WS"\n")*   -> <br></block>
(WS"\n")*          -> <br no="*" break="1"/>"\n"
<bf/>              ->

substSpacer:
"*"WS*          -> <spacer no="*"/>

substQuotes:
"\"".*"\""      -> <quote>*</quote>

substAkkord:
"|"CHAR         -> <akk note="C#/D#">CHAR</akk>
/* more to come! */

comments:
<!-- -->WS"\n"                    -> <!-- -->"\n"
(WS"\n")*<!-- -->WS"\n"(WS"\n")*  -> <br no="*+*">"\n"?<!-- -->"\n"

substAkkord:
"|"CHAR         -> <akk note="C#/D#">CHAR</akk>

|<-- done, TODO: do <akk> as NODE_AKK (? why); TODO: rework using the real xml-tree; TODO!: redo attrib as (kind of) argument for openNode
<bf suppress="1"/>  ->
OutputWhitespaceNormalization including empty-akk-WS-adjust.

numberIt:
<vers>          -> <vers no="">
<bridge>        -> <bridge no="">
<ending>        -> <ending no="">
<refr>          -> <refr no="">

OutputSubstitute:
(tex: "_"->"\\_", "\n *"->"\n")

