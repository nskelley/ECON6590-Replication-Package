\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{creport}[9sep2025 \LaTeX custom class for creating reports]

\LoadClass[11pt]{article}

%% Packages
\RequirePackage[margin=1in, top=0.75in]{geometry}
\RequirePackage[utf8x]{inputenc}
\RequirePackage[dvipsnames]{xcolor}
% Links
\RequirePackage[colorlinks=true, allcolors={blue}]{hyperref}
\RequirePackage{amssymb, amsfonts, amsmath, mathrsfs, enumitem, tcolorbox, bbm, bm, graphicx, fullpage, mathtools, float, amsthm, xfrac, csquotes}
\RequirePackage[american]{babel}
% References
\RequirePackage[backend=biber,
    style=apa, 
    natbib=true,]{biblatex}
% \RequirePackage[round]{natbib}
% \RequirePackage[natbibapa]{apacite}
% \RequirePackage[makeroom]{cancel}
% Figures/graphics
\RequirePackage{tikz}
\RequirePackage{pgfplots}
% \RequirePackage{listings}
\RequirePackage{array}
% \RequirePackage{authblk}
\RequirePackage{setspace}

\pgfplotsset{compat=1.18}



%-------------------------------------------------------------------------------
%% Math operators
%-------------------------------------------------------------------------------
% Label for over/underbraces in math environments
\newcommand{\bracelabel}[2]{%
    \parbox{#1}{\centering\footnotesize\linespread{0.7}\selectfont%
        #2
    }
}

% Abbreviations for grouping symbols
\newcommand{\parl}{\left(}
\newcommand{\parr}{\right)}
\newcommand{\bracl}{\left[}
\newcommand{\bracr}{\right]}
\newcommand{\curll}{\left\{}
\newcommand{\curlr}{\right\}}
\newcommand{\anglel}{\left\langle}
\newcommand{\angler}{\right\rangle}

% Basic math commands
\newcommand{\real}{\mathbb{R}}
\newcommand{\rationals}{\mathbb{Q}}
\newcommand{\integers}{\mathbb{Z}}
\newcommand{\naturals}{\mathbb{N}}
\newcommand{\complex}{\mathbb{C}}
\newcommand{\rpoz}{\real_{++}}
\newcommand{\rnoneg}{\real_{+}}

% General math
\newcommand{\abs}[1]{\left|#1\right|} % absolute value
\newcommand{\inv}{^{-1}} % inverse
\newcommand{\st}{\;\text{s.t.}\;} % math operator for "such that"

% Updated bar (overline)
\newcommand{\smallbar}{\bar}
\renewcommand{\bar}[1]{\mkern 1.5mu\overline{\mkern-1.5mu#1\mkern-1.5mu}\mkern 1.5mu}

% Analysis, vector spaces, and topology
\newcommand{\tuple}[1]{\left\langle #1 \right\rangle} % tuple notation
\newcommand{\set}[1]{\left\{#1\right\}} % set notation
\newcommand{\setless}{\backslash} % A \ B notation
\newcommand{\vb}[1]{\boldsymbol{#1}} % shorthand for bolding vectors

% Matrices
\newcommand{\transpose}{^{\mathsf{T}}\!} % Transpose
\newcommand\tpose{\transpose}

% Statistics
\newcommand{\cov}{\text{cov}} % covariance
\newcommand{\corr}{\text{corr}} % correlation
\newcommand{\expect}{\mathbb{E}} % expectation
\newcommand{\iid}{\text{i.i.d.}\hspace{1ex}} % i.i.d.
\newcommand{\var}{\text{Var}} % variance
\newcommand{\dummy}{\mathbbm{1}\!} % indicator function

% Update existing operators (spacing, empty set)
\let\oldExists\exists
\renewcommand{\exists}{\oldExists\;}
\let\oldForall\forall
\renewcommand{\forall}{\;\oldForall\;}
\let\oldEmptyset\emptyset
\renewcommand{\emptyset}{\varnothing}


%-------------------------------------------------------------------------------
%% Presentation environments
%-------------------------------------------------------------------------------
% Proofs, counterexamples, and disproofs
\renewcommand\qedsymbol{$\blacksquare$}
\renewenvironment{proof}{{\raggedright \textit{\textbf{Proof.}}}}{\qed} % Proof

% Theorem styles
\newtheorem{lemma}{Lemma}
\newtheorem{theorem}{Theorem}
\newtheorem{proposition}{Proposition}
\newtheorem{corollary}{Corollary}
\newtheorem{axiom}{Axiom}
\newtheorem*{axiom*}{Axiom}
\newtheorem*{theorem*}{Theorem}
\newtheorem*{proposition*}{Proposition}

% Preformatted note command for notes on exhibits (environment to allow
%multi-paragraph notes)
\newenvironment{longnote}{%
    \begin{minipage}{0.6\textwidth}
        \footnotesize\textit{Note:}
}{%
    \end{minipage}
}


%-------------------------------------------------------------------------------
%% Notetaking environments and commands
%-------------------------------------------------------------------------------
% Colored/specially formatted notes (not environments)
\newcommand{\nb}[1]{{\textit{\color{purple}#1}}}
\newcommand{\tk}[1]{{\color{red}\textbf{TK: }#1}}
