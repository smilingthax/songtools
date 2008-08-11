\NeedsTeXFormat{LaTeX2e}[1996/12/01]
\ProvidesClass{songfoil}
       [2007/08/03\space v1.0a\space SongFoil Class File,
        Copyright 2002,2003,2007 Tobias Hoffmann]
% Copyright by Tobias Hoffmann, Licence: LGPL, see COPYING

\input{songffnt.def}

\pagenumbering{arabic}

% These values chosen to fill 4/3 aspect ratio screen
\setlength{\paperwidth}{279mm}
\setlength{\paperheight}{208mm}
\pdfpagewidth = \paperwidth
\pdfpageheight = \paperheight

% Setup the Page with proper values
\setlength{\oddsidemargin}{-1.6cm}
\setlength{\topmargin}{-1.6cm}

\setlength\headsep{14\p@}
\addtolength{\headsep}{0.6cm}

\setlength\headheight{15\p@}
%\addtolength{\headheight}{0.4cm}
\addtolength{\headheight}{0.6cm}
\addtolength{\topmargin}{-0.2cm}

% \headsep+\headheight=14\p@+\15\p@=29\p@
\setlength\footskip{1in}
\addtolength\footskip{-29\p@}

\setlength\textheight{\paperheight}
\addtolength\textheight{-3in}
\addtolength{\textheight}{1.7cm}

\setlength\textwidth{\paperwidth}
\addtolength\textwidth{-2in}
\addtolength{\textwidth}{2.7cm}

\setlength{\parindent}{0pt}
\setlength{\listparindent}{0pt}
\setlength{\parskip}{0pt}
\setlength{\parsep}{0pt}
\setlength{\topsep}{0pt}

\setlength{\linewidth}{\paperwidth}
\addtolength{\linewidth}{+3.2cm}
\addtolength{\linewidth}{-2in}

\setlength\evensidemargin{0\p@}
\setlength\partopsep{2\p@ \@plus 1\p@ \@minus 1\p@}
\renewcommand\baselinestretch{0.88}
% No hypenation
\righthyphenmin=100
\lefthyphenmin=100

% Page layout
\newcommand\leftheader[1]{\gdef\@leftheader{#1}}
\newcommand\rightheader[1]{\gdef\@rightheader{#1}}
\newcommand\rightfooter[1]{\gdef\@rightfooter{#1}}
\newcommand\leftfooter[1]{\gdef\@leftfooter{#1}}
\leftheader{}
\rightheader{}
\rightfooter{}
\leftfooter{}

\setlength\arraycolsep{10\p@}
\setlength\tabcolsep{12\p@}
\setlength\arrayrulewidth{1\p@}
\setlength\doublerulesep{3\p@}
\setlength\tabbingsep\labelsep
\setlength\fboxsep{10\p@}
\setlength\fboxrule{1\p@}

\newsavebox\@tempfootbox
\newdimen\@tempfootht

\newcommand\ps@foilheadings{\let\@mkboth\@gobbletwo
  \def\@oddhead{\ifnum\c@page>0 {\reset@font\tiny\@leftheader\hfil\@rightheader}\else\hfill\fi}%
  \def\@oddfoot{\ifnum\c@page>0 {\sbox\@tempfootbox{\tiny\@leftfooter a\hfil\@rightfooter}%
      \@tempfootht\ht\@tempfootbox
      \advance\@tempfootht 5.66666\p@
      \reset@font\tiny\@leftfooter\hfil\@rightfooter}%
    \else
      {\hfil\reset@font\footnotesize\hfil}%
    \fi}%
  \let\@evenhead\@oddhead%
  \let\@evenfoot\@oddfoot%
}
\ps@foilheadings
\@lowpenalty   51
\@medpenalty  151
\@highpenalty 301
\@beginparpenalty -\@lowpenalty
\@endparpenalty -\@lowpenalty
\@itempenalty -\@lowpenalty

\endinput
