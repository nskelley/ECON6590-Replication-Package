\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{workingpaper}[11nov2025 \LaTeX custom class for working paper formatting]

\LoadClass[12pt, letterpaper]{article}

%% Packages
\RequirePackage[margin=1in]{geometry}
\RequirePackage[utf8x]{inputenc}
\RequirePackage[dvipsnames]{xcolor}

\RequirePackage[T1]{fontenc}
\usepackage{mathptmx} % ptm
\fontfamily{ptm}\selectfont
% Links
\RequirePackage[colorlinks=true, allcolors={blue}]{hyperref}
\RequirePackage{amssymb, amsfonts, amsmath, mathrsfs, enumitem, tcolorbox, bbm, bm, graphicx, fullpage, mathtools, float, amsthm, xfrac, csquotes}
\RequirePackage{caption}
\RequirePackage{subcaption}

\RequirePackage[american]{babel}

% References
\RequirePackage[
    backend=biber,
    style=apa, 
    natbib=true
]{biblatex}
\AtEveryBibitem{\clearfield{labelmonth}}
\renewcommand{\cite}{\textcite}

% Figures/graphics
\RequirePackage{tikz}
\RequirePackage{pgfplots}
\pgfplotsset{compat=1.18}

\RequirePackage{array}
\RequirePackage{authblk}
\RequirePackage{setspace}

\newcommand{\nb}[1]{{\textit{\color{purple}#1}}}
\newcommand{\tk}[1]{{\color{red}\textbf{TK: }#1}}

\def\@theabstract{}
\def\@keywords{}
\def\@jel{}

\renewcommand{\abstract}[1]{\def\@theabstract{#1}}
\newcommand{\keywords}[1]{\def\@keywords{#1}}
\newcommand{\jel}[1]{\def\@jel{#1}}

\newcommand{\maketitlepage}{%
    \maketitle
    \thispagestyle{empty}
    \setcounter{page}{0}
    \vspace{1em}

    \begin{center}
        \begin{minipage}{0.86\linewidth}
            \small
            \begin{center}
                \noindent\textbf{Abstract}
            \end{center}
            \vspace{-1em}

            \noindent\@theabstract
        \end{minipage}
        \vspace{2em}\normalsize

        \begin{minipage}{0.86\linewidth}
            \normalsize
            \noindent\textbf{Keywords:} \@keywords 
            \vspace{1em}

            \noindent\textbf{JEL Codes:} \@jel
        \end{minipage}
    \end{center}
    \clearpage
}