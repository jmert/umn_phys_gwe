umn_phys_gwe
============

Solutions to the School of Physics and Astronomy at the University of Minnesota's past Graduate Written Exams (GWE). The solutions can be built by running `xelatex` on `solutions.tex`.

There is also an accompanying file, `flashcards.tex`, which provide a set of quick references in physics in flashcard form. The document makes use of the `flashcards` package and can be easily modified to make use of different types of pre-cut papers; the default makes use of Avery 5371 perforated paper.

Notes on compiling the documents
--------------------------------
Because I mainly have taken care of these sets of solutions myself, I have not worried to much about portability to other systems. In particular, I make use of the XeLaTeX system rather than the typical pdfLaTeX system, so there are additional font dependencies beyond what TeXLive typically provides. If you find that the documents do not compile on your machine, you can easily change the selected fonts by modifying (or commenting out) lines that make use of the `\setmathfont`, `\setmainfont`, or `\setsansfont` macros.
