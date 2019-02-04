

library(shiny)

# Define UI for data upload app ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("Abbreviation List Maker"),
  
  helpText("Implements Tessa Campbell's (@ScientistTess) method for generating abbreviation lists.\nUpload a .doc or .docx file, and it'll return a list of all abbreviations in the file. If you check the checkbox, it can also try to automatically guess what each abbreviation stands for using the HUGO Gene Nomenclature tool; the NCBI gene database; or abbreviations.com. I only recommend HUGO at this time, because the other two are slow and require web scraping."),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Select a file ----
      fileInput("file1", "Choose doc or docx File",
                multiple = FALSE,
                accept = c("text/doc",
                           "text/docx",
                           ".doc",
                           ".docx")),
      
      
      
      # Horizontal line ----
      tags$hr(),
      
      checkboxInput("scrape_hgnc", "Guess abbreviation from HUGO", FALSE),
      checkboxInput("scrape_NCBI", "Guess abbreviation from NCBI gene database", FALSE),
      checkboxInput("scrape_abbrevs", "Guess abbreviation from abbreviations.com", FALSE)
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Data file ----
      tableOutput("contents")
      
    )
    
  )
)

# Define server logic to read selected file ----
server <- function(input, output) {
  
  require(rvest)
  
  output$contents <- renderTable({
    
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, head of that data file by default,
    # or all rows if selected, will be shown.
    
    req(input$file1)
    
    # when reading semicolon separated files,
    # having a comma separator causes `read.csv` to error
    tryCatch(
      {
        text <- paste(unlist(textreadr::read_document(input$file1$datapath)), collapse="\n")
        
        abbreviations <- as.data.frame(rbind(
          rowr::cbind.fill(Style="AA style", 
                Abbreviation=unique(stringr::str_extract_all(text, "[A-Z]{2,}")[[1]])),
          rowr::cbind.fill(Style="A&A style", 
                Abbreviation=unique(stringr::str_extract_all(text, "[A-Z]\\&[A-Z]")[[1]])),
          rowr::cbind.fill(Style="AaA style", 
                Abbreviation=unique(stringr::str_extract_all(text, "[A-Z]*[a-z][A-Z]")[[1]])),
          rowr::cbind.fill(Style="AA1 style", 
                Abbreviation=unique(stringr::str_extract_all(text, "[A-Z]{2,}[0-9]{1,}")[[1]])),
          rowr::cbind.fill(Style="AA-1 style", 
                Abbreviation=unique(stringr::str_extract_all(text, "[A-Z]{2,}\\-[0-9]{1,}")[[1]]))),
          stringsAsFactors=FALSE)
        
        names(abbreviations) <- c("Style", "Abbreviation")
        
        if(input$scrape_hgnc==TRUE){
          gene_names <- read_tsv("ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/hgnc_complete_set.txt")
          abbreviations$HGNC_guess <- NA
          unsafe_get_gene_name <- function(abbreviation){
            gene_names$name[grep(abbreviation, gene_names$symbol)[1]]}
          get_gene_name <- possibly(unsafe_get_gene_name, otherwise=NA)
        
          abbreviations$HGNC_guess <- map_chr(abbreviations$Abbreviation, get_gene_name)
        }
        
        if(input$scrape_abbrevs==TRUE){
          unsafe_get_abbrev <- function(abbreviation){
            paste0("https://www.abbreviations.com/", 
                   abbreviation) %>% read_html() %>%
              html_nodes(xpath="//p[contains(@class, 'desc')]") %>% html_text %>% `[`(2)
          }
          get_abbrev <- possibly(unsafe_get_abbrev, otherwise=NA)
          
          abbreviations$abbreviations.com_guess <- map_chr(abbreviations$Abbreviation, get_abbrev)
          
        }
        
        if(input$scrape_NCBI==TRUE){
          get_NCBI  <- function(abbreviation){
          result <- paste0("https://www.ncbi.nlm.nih.gov/gene/?term=", abbreviation) %>%
            read_html() %>% html_nodes(xpath="//table[contains(@class, 'jig-ncbigrid gene-tabular-rprt')]/tbody/tr/td") %>%
            `[`(2) %>% html_text
          
          if(length(result)==1){return(result)}else{return(NA)}
          }
          abbreviations$NCBI_gene_guess <- map_chr(abbreviations$Abbreviation, get_NCBI)
        }
          
      },
      error = function(e) {
        # return a safeError if a parsing error occurs
        stop(safeError(e))
      }
    )
    
    return(abbreviations)
    
    
  })
  
}

# Create Shiny app ----
shinyApp(ui, server)

