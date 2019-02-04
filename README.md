# AbbreviationMaker
Shiny app to make an abbreviation list from all the abbreviations in a document: https://sahelanth.shinyapps.io/Abbreviator/ This saves time over going through manually and putting a list together yourself.

The heart of it is [the regexes Tessa Campbell presents here](https://twitter.com/ScientistTess/status/1083150336074764288). My addition is a method to automatically guess the meanings of the abbreviations it finds in your document, using either the HUGO gene nomenclature, the NCBI gene database, or the main search on abbreviations.com. Currently relies on webscraping.

TK: more polite version. Use a cached version of the HUGO gene names, the NCBI API, and the STANDS4 abbreviation API.

TK: more full-featured version, letting you select abbreviations.com subcategories to guess from and handling uploads in formats other than .doc and .docx.

TK: use the promises package to add async handling, to make it practical for more than a handful of people to use at once.
