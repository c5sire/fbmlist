#' Server Side for Creation Material List from Scratch
#' 
#' @param input shinyserver input 
#' @param output shinyserver output
#' @param session shinyserver session
#' @param values reactive values
#' @author Omar Benites
#' @export


server_createlist <- function(input,output,session, values){
  
  
  gmtl_data_new <- eventReactive(input$fbmlist_connect_new, {
    
    dbf_file <- input$fbmlist_sel_list_new
    n <- length(input$fbmlist_sel_list_new)
  
    if(n==1){
      path <- fbglobal::get_base_dir()
      path <- file.path(path, dbf_file)
      germlist_db <- readRDS(path)
      
    }
    n_row <- nrow(germlist_db)
    
    germlist_db <-  mutate(germlist_db, IDX = 1:n_row)
    germlist_db
    
    
  }) 
  
  output$show_mtable_new <- reactive({
    return(!is.null(gmtl_data_new()))
  })
  

  outputOptions(output, 'show_mtable_new', suspendWhenHidden=FALSE)
  #outputOptions(output, 'show_save', suspendWhenHidden=FALSE)
  
  
  output$family_new_list <- renderUI({
 
    index_new <- gmtl_row_index_new()
    mtl_table_new <- gmtl_data_new()
    chosen_gmtl_table_new <-  mtl_table_new[index_new, ]
    family_list_choosen <- chosen_gmtl_table_new[,"Accession_Number"]
    
    
    #trait <- as.character(input$trait_pbaker)
    if(length(family_list_choosen)>0){

      lapply(1:length(family_list_choosen), function(i) {
        print(i)
        numericInput(paste0("n_input_wpb_", family_list_choosen[i]), label = paste0("", family_list_choosen[i]), value = 1)
      })  
    }
  })
  
  
  output$sel_list_new_btn <- renderUI({
  
    crop <- input$fbmlist_sel_crop_new
    type_db <- input$fbmlist_sel_type_new
    mtl_db_sel <- mtl_files()$short_name
    
    if(crop == "") {
      
      db_files_choices  <-  "" 
      sel_multiple <- FALSE 
      
    }   
    if(crop == "potato") { 
      
      if(type_db=="Institutional"){ 
        
        #db_files_choices <- list("dspotatotrials_dpassport.dbf", "potato_pedigree.dbf")
        #db_files_choices <- list("dspotatotrials_dpassport.rds", "potato_pedigree.rds")
        db_files_choices <- list("potato_pedigree.rds")
        sel_multiple <- FALSE                         
      }
      # Deprecated Code, just pedigree db ---------------------------------------
      # if(type_db=="Local"){ 
      #   
      #   db_files_choices <- mtl_db_sel[str_detect(mtl_db_sel , "PT")] 
      #   sel_multiple <- TRUE
      # }
      #
    }
    
    if(crop == "sweetpotato") {
      
      if(type_db=="Institutional") { 
        #db_files_choices <- list("dssweettrials_dpassport.rds" , "sweetpotato_pedigree.rds")
        db_files_choices <- list("sweetpotato_pedigree.rds")
        sel_multiple <- FALSE   
      }
      
      # Deprecated Code, just pedigree db ---------------------------------------
      # if(type_db=="Local"){ 
      #   db_files_choices <- mtl_db_sel[str_detect(mtl_db_sel , "SP")]
      #   sel_multiple <- TRUE 
      # }
      #
    }
    
    shiny::selectizeInput(inputId ="fbmlist_sel_list_new", label = "Select list", 
                          multiple =  sel_multiple, width="100%", choices = db_files_choices,
                          options = list(
                            placeholder = 'Please select an option below',
                            onInitialize = I('function() { this.setValue(""); }')
                          )
    )
  })
  
  output$fbmlist_foundclones_new <- renderText({
    
   mtl_table <- gmtl_data_new()
   mtl_headers <- c("Accession_Number", "Female_AcceNumb", "Female_codename", "Male_AcceNumb", 
                     "Male_codename", "Population", "Cycle", "Date_Created", "IDX") 
    
    mtl_table_names <- names(mtl_table)
    mtl_headers <- mtl_headers[mtl_headers %in% mtl_table_names]
    
    temp_mtl_table <- mtl_table[, mtl_headers]
    
    #If textarea is diferent from "" or whistesapces then search your genotypes
    if(input$fbmlist_txtarea_new!="" || !str_detect(input$fbmlist_txtarea_new, "[[:space:]]")){
      
      #trimming search filter
        search_filter <- str_split(input$fbmlist_txtarea_new,"\\n")[[1]]
        search_filter <- stringr::str_trim(search_filter,side = "both")
        search_filter <- as.character(search_filter)
        
        #extracting columns Accesion Number and Accesion Name
        material_db_accnum <- as.character(temp_mtl_table$Accession_Number)
        #material_db_accname <- as.character(temp_mtl_table$Accession_Name)
        
        material_acc_union <- material_db_accnum
        
        out_dbacc_search <- setdiff(search_filter, material_acc_union) #find the element which are NOT in the inserction
        out_dbacc_search <- out_dbacc_search[!is.na(out_dbacc_search)]
        out_dbacc_search <- out_dbacc_search[out_dbacc_search!=""]
        n_search <- length(out_dbacc_search)
        
        
        # Show messages according to accesion founder in accesion number or accesion name
        
        if(n_search>0){ #for accession number, flag =1
          out <- paste(out_dbacc_search, collapse = ", ")
          out <- paste("N= ", n_search, " accesion(s) were not found: ", out, sep="")
        } else {
          out <- paste("", sep = "")
        }
        out
        
    }
    
  })
  
  
  # RENDER_UI for User Inputs in Creation MTList ----------------------------  
  
  output$create_new_name <- renderUI({
    req(input$fbmlist_select_new)
    textInput("fbmlist_create_new_name", label = h4("New List Name"), value = "", placeholder = "Write a List Name")
  })

  output$researcher_new_name <- renderUI({
    req(input$fbmlist_select_new)
    textInput("fbmlist_researchername_new", label = h4("Reseacher Name"), value = "", placeholder = "Write Reseacher Name")
  })
  
  output$continent_new_name <- renderUI({
    req(input$fbmlist_select_new)
    continent_list <- unique(countrycode_data$continent)
    continent_list <- continent_list[!is.na(continent_list)]
    continent_list <- sort(continent_list)
    
    #selectInput("fbmlist_continent_new", label = h4("Continent"), choices = continent_list , placeholder = "Choose Continent")
    shiny::selectizeInput(inputId ="fbmlist_continent_new", label = "Select Continent", 
                          multiple =  FALSE, width="100%", choices = continent_list,
                          options = list(
                            placeholder = 'Please select an country below',
                            onInitialize = I('function() { this.setValue(""); }')
                          )
    )
  })
  
  output$country_new_name <- renderUI({
    
    req(input$fbmlist_select_new)
    #req(input$fbmlist_continent_new)
    continent_header <- input$fbmlist_continent_new
    
    if(continent_header == "" || is.null(continent_header)) { 
      
        continent_list <- "" 
        
    } else {
      
        continent_list <- filter(countrycode_data, continent == continent_header)
        continent_list <- select(continent_list, country.name)
        
    }
    
    shiny::selectizeInput(inputId ="fbmlist_country_new", label = "Select Country", 
                          multiple =  FALSE, width="100%", choices = continent_list,
                          options = list(
                            placeholder = 'Please select country below',
                            onInitialize = I('function() { this.setValue(""); }')
                          )
    )
  })
 
  output$breedercode_new_name <- renderUI({
    req(input$fbmlist_select_new)
    textInput("fbmlist_breedercode_new", label = h4("Breeder Code"), value = "", placeholder = "Write Breeder Code")
  })
  
  output$savelist_new_btn <- renderUI({
    
    req(input$fbmlist_select_new)
    shinysky::actionButton2("fbmlist_save_new", label = "Save List", icon = "save", icon.library = "bootstrap")
    
  })
  
  # Selection on generataed material list button ----------------------------------------------------
  output$fbmlist_table_new  <-  DT::renderDataTable({
    
    
    shiny::req(input$fbmlist_connect_new)
    #shiny::req(input$fbmlist_selectgenlist)
    
    shiny::withProgress(message = "Visualizing Table...",value= 0,  #withProgress
                        
                        {
                         
                          observe({
                            if (length(input$fbmlist_save_new)!= 0)
                              return()
                            isolate({
                              mtl_table <- gmtl_data_new()
                            })
                          })
                          

                          #input$savelist_new_btn
                          mtl_table <- gmtl_data_new()
                          
                          #p <- NULL
                          #if(!is.null(p)){ mtl_table <- gmtl_data_new()}
                         
                          mtl_headers <- c("Accession_Number", "Female_AcceNumb", "Female_codename", "Male_AcceNumb", 
                          "Male_codename", "Population", "Cycle", "Date_Created", "IDX") 
                          
                          mtl_table_names <- names(mtl_table)
                          mtl_headers <- mtl_headers[mtl_headers %in% mtl_table_names]
                          
                          temp_mtl_table <- mtl_table[, mtl_headers]

                          if(input$fbmlist_txtarea_new!=""){
                            
                            #temp_mtl_table <-  mutate(temp_mtl_table, IDX = 1:n())
                            
                            search_filter <- str_split(input$fbmlist_txtarea_new,"\\n")[[1]]
                            search_filter <- stringr::str_trim(search_filter,side = "both")
                            #mtl_table_f  <- filter(mtl_table, Accession_Number %in% search_filter)
                            mtl_table_f   <- filter(temp_mtl_table, Accession_Number %in% search_filter)
                            
                            
                            if(nrow(mtl_table_f)==0 &&  is.element("Accession_Name",names(mtl_table_f))) {
                              #mtl_table_f <- dplyr::filter(mtl_table, Accession_Name %in% search_filter)
                              mtl_table_f <- dplyr::filter(temp_mtl_table, Accession_Name %in% search_filter)
                              #row_click <- as.numeric(rownames(mtl_table_f))
                            }
                            
                            # SEARCH ACCESSION BY DIFFERENTE PEDRIGREE ATRIBUTES (Temporary disable)   
                            
                            # if(nrow(mtl_table_f)==0 &&  is.element("Female_AcceNumb",names(mtl_table_f))) {
                            #   
                            #   mtl_table_f <- dplyr::filter(temp_mtl_table, Female_AcceNumb %in% search_filter)
                            #   #row_click <- as.numeric(rownames(mtl_table_f))
                            # } 
                            # 
                            # if(nrow(mtl_table_f)==0 &&  is.element("Female_codename",names(mtl_table_f))) {
                            #   
                            #   mtl_table_f <- dplyr::filter(temp_mtl_table, Female_codename %in% search_filter)
                            #   #row_click <- as.numeric(rownames(mtl_table_f))
                            # }  
                            # 
                            # if(nrow(mtl_table_f)==0 &&  is.element("Male_AcceNumb", names(mtl_table_f))) {
                            #   
                            #   mtl_table_f <- dplyr::filter(temp_mtl_table, Male_AcceNumb %in% search_filter)
                            #   #row_click <- as.numeric(rownames(mtl_table_f))
                            # }    
                            # 
                            # if(nrow(mtl_table_f)==0 &&  is.element("Male_codename", names(mtl_table_f))) {
                            #   
                            #   mtl_table_f <- dplyr::filter(temp_mtl_table, Male_codename %in% search_filter)
                            #   #row_click <- as.numeric(rownames(mtl_table_f))
                            # }  
                            # 
                            # 
                            # if(nrow(mtl_table_f)==0  &&  is.element("Population", names(mtl_table_f))) {
                            #   #mtl_table_f <- dplyr::filter(mtl_table, Population %in% search_filter)
                            #   mtl_table_f <- dplyr::filter(temp_mtl_table, Population %in% search_filter)
                            #   #row_click <- as.numeric(rownames(mtl_table_f))
                            # }
                            # 
                            # 
                            # if(nrow(mtl_table_f)==0  &&  is.element("Cycle", names(mtl_table_f))) {
                            #   
                            #   mtl_table_f <- dplyr::filter(temp_mtl_table, Cycle %in% search_filter)
                            #   #row_click <- as.numeric(rownames(mtl_table_f))
                            # }  
                            # END SEARCH ACCESSION BY DIFFERENTE PEDRIGREE ATRIBUTES (Temporary disable)   

                            if(nrow(mtl_table_f)>0){ 
                              # Row click 
                              row_click <- as.numeric(mtl_table_f$IDX)
                              N <- rownames(mtl_table_f)%>% as.numeric(.)
                              print(N)
                            }

                            
                            #DT::datatable(mtl_table, rownames = FALSE, 
                            #DT::datatable(temp_mtl_table, rownames = FALSE,  ##temp_mtl_table is the all table
                            DT::datatable(mtl_table_f, rownames = FALSE,      ##filtered table
                                          options = list(scrollX = TRUE, scroller = TRUE),
                                          #selection = list( mode= "multiple",  selected =  rownames(mtl_table)), 
                                          selection = list( mode = "multiple", selected = N), 
                                          filter = 'bottom'#,
                                          # extensions = 'Buttons', options = list(
                                          #   dom = 'Bfrtip',
                                          #   buttons = 
                                          #     list(list(
                                          #       extend = 'collection',
                                          #       buttons = c('csv', 'excel'),
                                          #       text = 'Download'
                                          #     ))
                                          #   
                                          # )
                            )
  
                          } else {
   
                          #DT::datatable(mtl_table, rownames = FALSE, 
                            DT::datatable(temp_mtl_table, rownames = FALSE,
                                          options = list(scrollX = TRUE, scroller = TRUE),
                                          #selection = list( mode= "multiple",  selected =  rownames(mtl_table)), 
                                          selection = list( mode = "multiple"), 
                                          filter = 'bottom'#,
                                          # extensions = 'Buttons', options = list(
                                          #   dom = 'Bfrtip',
                                          #   buttons = 
                                          #     list(list(
                                          #       extend = 'collection',
                                          #       buttons = c('csv', 'excel'),
                                          #       text = 'Download'
                                          #     ))
                                          #   
                                          # )
                            )
                            
                        }
 
                          
                        }) #end of Progress
    
  } )
  
  #Row selected by User  ----------------------------------------------------
  gmtl_row_index_new <- eventReactive(input$fbmlist_select_new,{
  
    temp_mtl_table <- gmtl_data_new()
      
    if(input$fbmlist_txtarea_new!=""){
      
      #temp_mtl_table <-  mutate(temp_mtl_table, IDX = 1:n())
      
      search_filter <- str_split(input$fbmlist_txtarea_new,"\\n")[[1]]
      search_filter <- stringr::str_trim(search_filter,side = "both")
      #mtl_table_f  <- filter(mtl_table, Accession_Number %in% search_filter)
      mtl_table_f   <- filter(temp_mtl_table, Accession_Number %in% search_filter)
      
      
      if(nrow(mtl_table_f)==0 &&  is.element("Accession_Name",names(mtl_table_f))) {
        #mtl_table_f <- dplyr::filter(mtl_table, Accession_Name %in% search_filter)
        mtl_table_f <- dplyr::filter(temp_mtl_table, Accession_Name %in% search_filter)
        #row_click <- as.numeric(rownames(mtl_table_f))
      }
    
      # SEARCH ACCESSION BY DIFFERENTE PEDRIGREE ATRIBUTES (Temporary disable)
        
      # if(nrow(mtl_table_f)==0 &&  is.element("Female_AcceNumb",names(mtl_table_f))) {
      #   
      #   mtl_table_f <- dplyr::filter(temp_mtl_table, Female_AcceNumb %in% search_filter)
      #   #row_click <- as.numeric(rownames(mtl_table_f))
      # } 
      # 
      # if(nrow(mtl_table_f)==0 &&  is.element("Female_codename",names(mtl_table_f))) {
      #   
      #   mtl_table_f <- dplyr::filter(temp_mtl_table, Female_codename %in% search_filter)
      #   #row_click <- as.numeric(rownames(mtl_table_f))
      # }  
      # 
      # if(nrow(mtl_table_f)==0 &&  is.element("Male_AcceNumb", names(mtl_table_f))) {
      #   
      #   mtl_table_f <- dplyr::filter(temp_mtl_table, Male_AcceNumb %in% search_filter)
      #   #row_click <- as.numeric(rownames(mtl_table_f))
      # }    
      # 
      # if(nrow(mtl_table_f)==0 &&  is.element("Male_codename", names(mtl_table_f))) {
      #   
      #   mtl_table_f <- dplyr::filter(temp_mtl_table, Male_codename %in% search_filter)
      #   #row_click <- as.numeric(rownames(mtl_table_f))
      # }  
      # 
      # 
      # if(nrow(mtl_table_f)==0  &&  is.element("Population", names(mtl_table_f))) {
      #   #mtl_table_f <- dplyr::filter(mtl_table, Population %in% search_filter)
      #   mtl_table_f <- dplyr::filter(temp_mtl_table, Population %in% search_filter)
      #   #row_click <- as.numeric(rownames(mtl_table_f))
      # }
      # 
      # 
      # if(nrow(mtl_table_f)==0  &&  is.element("Cycle", names(mtl_table_f))) {
      #   
      #   mtl_table_f <- dplyr::filter(temp_mtl_table, Cycle %in% search_filter)
      #   #row_click <- as.numeric(rownames(mtl_table_f))
      # }
      
      ###   # END SEARCH ACCESSION BY DIFFERENTE PEDRIGREE ATRIBUTES (Temporary disable)
      
      if(nrow(mtl_table_f)>0){ 
        # Row click 
        row_click <- as.numeric(mtl_table_f$IDX)
        #N <- rownames(mtl_table_f)%>% as.numeric(.)
      } else {
        
        row_click <- NULL
      }
      
      row_click
    
    } else {
      
      row_select <- input$fbmlist_table_new_rows_selected #comand to get selected values		
      #row_filter <- input$fbmlist_table_new_rows_all #comand to get filtered values		    
      #row_mtlist_selection <- dplyr::intersect(row_select,row_filter)		     
      
      row_mtlist_selection <- sort(row_select)
      row_click <- row_mtlist_selection
      
      
    }
    
    print(row_click)
    row_click
    
    
    
})


  # Observers of fbmlist ----------------------------------------------------

  shiny::observeEvent(input$fbmlist_save_new,{
    
    index <- gmtl_row_index_new()
    
    #print(index)
    
    mtl_table <- gmtl_data_new()
    #print(mtl_table)
    
    chosen_gmtl_table_new <-  mtl_table[index, ]
    #print(chosen_gmtl_table_new)
    
    
    family_list_choosen <- chosen_gmtl_table_new[,"Accession_Number"]
    #print(family_list_choosen)
    
    
    # Logic parameter to do not combine dataset with cipnumber with points. any 
    #(if one of them is false, then has_point_cipnr is TRUE)
    has_point_cipnbr <- any(stringr::str_detect(string = chosen_gmtl_table_new[,"Accession_Number"], pattern = "\\."))
    
    # Getting Parameters from User Begin --------------------------------------------
    
    fbmlist_name_dbf  <- str_trim(string = input$fbmlist_create_new_name, side = "both")
    fbmlist_name_dbf  <- gsub("\\s+", "_", fbmlist_name_dbf)
    
    fbmlist_name_dbf_extra <- fbmlist_name_dbf #temp varible to check if name is empty

    fbmlist_researchername_dbf  <- str_trim(string = input$fbmlist_researchername_new, side = "both")
    fbmlist_researchername_dbf  <- gsub("\\s+", "_", fbmlist_researchername_dbf)
    
    fbmlist_continent_dbf  <- input$fbmlist_continent_new
    fbmlist_country_dbf  <- input$fbmlist_country_new

    fbmlist_breedercode_dbf  <- str_trim(string = input$fbmlist_breedercode_new, side = "both")
    fbmlist_breedercode_dbf   <- gsub("\\s+", "_", fbmlist_breedercode_dbf)
    
    crop <- input$fbmlist_sel_crop_new
    
    #if(crop=="potato")      {fbmlist_name_dbf <- paste("PT","fam",fbmlist_name_dbf,sep = "_")}
    if(crop=="potato")      {fbmlist_name_dbf <- paste("PT","clone", fbmlist_name_dbf, sep = "_")} #clone list based on Family List 
    #if(crop=="sweetpotato") {fbmlist_name_dbf <- paste("SP","fam",fbmlist_name_dbf,sep = "_")} 
    if(crop=="sweetpotato") {fbmlist_name_dbf <- paste("SP","clone", fbmlist_name_dbf, sep = "_")} #clone list based on Family List
    
    fbmlist_name_dbf <- fbmlist_name_dbf
     
    #All the files names --------------------------------------------
    
    db_files <- file_path_sans_ext(mtl_files()$short_name)
   
    if(length(index) == 0L){
   
      #shinyBS::createAlert(session, "alert_fbmlist_new", "fbdoneAlert", title = "Warning",style = "warning",
      #                     content = "Please select some rows for your Families", append = FALSE, dismiss = FALSE)
      
      shinysky::showshinyalert(session, "alert_fbmlist_new", paste("Please select some rows for your Families"), 
                               styleclass = "warning")
      
     } 
       
       else if(fbmlist_name_dbf %in% db_files) {
    
      #shinyBS::createAlert(session, "alert_fbmlist_new", "fbdoneAlert", title = "Warning",style = "warning",
      #                     content = "This list already exists", append = FALSE, dismiss = FALSE)
         
      shinysky::showshinyalert(session, "alert_fbmlist_new", paste("This list already exists. Please try again"), 
                                  styleclass = "warning")   
         
         
      
     } 
       else if(fbmlist_name_dbf_extra == ""){ 
    
      #shinyBS::createAlert(session, "alert_fbmlist_new", "fbdoneAlert", title = "Warning",style = "warning",
      #                     content = "Please Type a Material List Name", append = TRUE, dismiss = FALSE)
      shinysky::showshinyalert(session, "alert_fbmlist_new", paste("Please Type a Material List Name"), 
                                  styleclass = "warning")      
         
      
     } 
       else if(fbmlist_researchername_dbf ==""){

       #shinyBS::createAlert(session, "alert_fbmlist_new", "fbdoneAlert", title = "Warning",style = "warning",
       #                     content = "Please Type the name of the Researcher", append = TRUE, dismiss = FALSE)
         
       shinysky::showshinyalert(session, "alert_fbmlist_new", paste("Please Type the name of the Researcher"), 
                                  styleclass = "warning")       
         
    
     } 
       else if(fbmlist_breedercode_dbf ==""){
       #print("1")
#        shinyBS::createAlert(session, "alert_fbmlist_new", "fbdoneAlert", title = "Warning",style = "warning",
#                            content = "Please Type a Breeder Code for your Material List", append = TRUE, dismiss = FALSE)
         shinysky::showshinyalert(session, "alert_fbmlist_new", paste("Please Type a Breeder Code for your Material List"), 
                                  styleclass = "warning")     
     } 
       else if(has_point_cipnbr){
       #print("1")
       #shinyBS::createAlert(session, "alert_fbmlist_new", "fbdoneAlert", title = "Warning",style = "warning",
       #                     content = "Sorry, you can NOT use accession numbers with dots (.). Use Institutional database and Pedegree List", append = TRUE, dismiss = FALSE)
          
       shinysky::showshinyalert(session, "alert_fbmlist_new", paste("Sorry, you can NOT use accession numbers with dots (.). Use Institutional database and Pedegree List"), 
                                  styleclass = "warning")       
     } 
       else {
         
       #crop <- input$fbmlist_sel_crop_new
      
#      if(crop=="potato")      {fbmlist_name_dbf <- paste("PT","new",fbmlist_name_dbf,sep = "_")}
#      if(crop=="sweetpotato") {fbmlist_name_dbf <- paste("SP","new",fbmlist_name_dbf,sep = "_")} 
      
       #foreign::write.dbf(dataframe = chosen_gmtl_table, file = fbmlist_name_dbf, factor2char = FALSE)
       fbmlist_name_dbf <- paste(fbmlist_name_dbf,".rds", sep = "")
      
      # Contruction of the Intermediate DataBase (User inputs Table) ------------
      
      n_family_table <- data.frame(lapply(1:length(family_list_choosen), function(i) {
        input[[paste0("n_input_wpb_", family_list_choosen[i])]]
      }),stringsAsFactors = FALSE)
      
      names(n_family_table) <- family_list_choosen
      
      #cipnumbers (headers) from n_family_table
      header <- names(n_family_table) #cipnumbers (headers) from n_family_table
      
      #the number of repetition from n_family_table
      nrep <- as.numeric(as.vector(n_family_table[1,])) 
      
      out_cipnumber_creation <- unlist(lapply(1:length(header), function(x) cipnumber_creation(header[x], nrep[x])$cipnumbers_new))
      
      out_cipnumber_rep <- unlist(lapply(1:length(header), function(x) cipnumber_creation(header[x], nrep[x])$cipnumbers_rep))
       
      #out_access_namecode_creation <- unlist(lapply(1:length(header), function(x) accessname_code(fbmlist_breedercode_dbf , nrep[x])))
      out_access_namecode_creation <- unlist(lapply(1:length(header), function(x) accessname_code(fbmlist_breedercode_dbf, header[x], nrep[x])))
     
      
      user_parameters <-   list( Numeration = 1:length(out_cipnumber_creation),
                                 Accession_Number_crt =  out_cipnumber_creation,
                                 Accession_Number = out_cipnumber_rep,
                                 Accession_Name = NA,
                                 Accession_code = out_access_namecode_creation,
                                 Is_control = NA,
                                 Scale_audpc = NA,
                                 #Family_AcceNumb = NA
                                 Material_list_name = fbmlist_name_dbf, 
                                 Researcher_Name = fbmlist_researchername_dbf,
                                 Continent = fbmlist_continent_dbf,
                                 Country = fbmlist_country_dbf,
                                 Seed_source = NA,
                                 Simultaneous_trials = NA, #Jazmin puts the properly name
                                 Previous_trials = NA,
                                 Date_Created = format(Sys.Date(), "%d %m %Y")
                                #Breeder_Code = fbmlist_breedercode_dbf
      )

      #Extract cip_family information using dplyr::left_join
      intermediate_mlist_db <- as.data.frame(user_parameters, stringsAsFactors = FALSE)
      
      #saveRDS(intermediate_mlist_db,file =  "intemediate.rds")
      #saveRDS(chosen_gmtl_table_new,file =  "chosengmtl.rds")
      
      new_list_tbl <- dplyr::left_join(chosen_gmtl_table_new, intermediate_mlist_db, by = "Accession_Number")
      new_list_tbl <- new_list_tbl[,-1]
     
      names(new_list_tbl)[9] <- "Accession_Number"
      
      
      #print("new list tabla")
      # print(head(new_list_tbl))
      # print("new")
      
      orden <- headers_new_list() #from utils.R
      # print("orden")
      # print(orden)
      
      #saveRDS(new_list_tbl,"new_list_tbl1.rds")
      
      new_list_tbl <- new_list_tbl[,orden]
      
      if(input$new_type_trial=="Standard"){ #normal columns by default
        new_list_tbl <-new_list_tbl
      } else { #remove columns Is_Control, "Scale_Audpc"
        new_list_tbl <- dplyr::select(new_list_tbl, -Is_control, -Scale_audpc)
        new_list_tbl <- as.data.frame(new_list_tbl)
      }
      
      new_list_tbl <- new_list_tbl
      
      #saveRDS(intermediate_mlist_db,file = fbmlist_name_dbf)
      
      #using fbglobal
      path <- fbglobal::get_base_dir()
      path <- file.path(path,  fbmlist_name_dbf)
      saveRDS(new_list_tbl, file = path)
      
      
      
      #without fbglobal
      #saveRDS(new_list_tbl, file = fbmlist_name_dbf)
      ##
      
      #mtl_files()
      
      #shinyBS::createAlert(session, "alert_fbmlist_new", "fbdoneAlert", title = "Sucessfully Created!",
      #                     content = "Material List successfully created!", append = FALSE, dismiss = FALSE)
      
      shinyjs::reset("form")
      shinyjs::reset("form2")
      shinyjs::reset("fbmlist_sel_type_new")
      
      shinysky::showshinyalert(session, "alert_fbmlist_new", paste("Material List successfully created!", "success"), 
                     styleclass = "success")
      
      
   
      
       
    
      #shinyjs::js$refresh() 
      
    }
    
    
  })
  
  
  
  #   output$fbmlist_choosen_table_new  <- DT::renderDataTable({
  #     
  #     #print(input$foo)
  #     index_new <- gmtl_row_index_new()
  #     mtl_table_new <- gmtl_data_new()
  #     chosen_gmtl_table_new <-  mtl_table_new[index_new, ]
  #     chosen_gmtl_table_new
  #     
  #   }, options = list(searching = FALSE) )
  
  
}






