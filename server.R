
# Server ------------------------------------------------------------------

server <- function(input,output,session){
  
  
 # Update the facilities list based on the region
  
  observe({
    
    choices_fosa <- hf_data %>% 
                filter(Region ==  input$ticket_location) %>% 
                pull(`Health facility`) %>% 
                unique()
    
    updateSelectInput(session,"ticket_facility", choices = choices_fosa )
    
})
  
 # User login informations 
  
  
  current_user <- reactiveVal(NULL)
  current_role <- reactiveVal(NULL)
  
  values <- reactiveValues(
    authenticated = FALSE,
    user = NULL,
    role = NULL,
    email = NULL
  )
  
  old_pass <- reactive({
    loadPasswords()
  }) 
  
  y <- Waiter$new(html = tagList(
                    div(
                      style = "position: absolute; left: 10px; top: 8px; display: flex; align-items: center;",
                      spin_loaders(color = "black")
                    )
                  ),
                  color = "transparent"
  )
  
  
  observeEvent(input$login, {
    
    y$show()
    # Validate inputs
    req(input$username, input$password)
    
    # Find the user in database by username only (not by password)
    user_row <- which(old_pass()$username == input$username)
    
    # Check if user exists
    if (length(user_row) == 0) {
      shinyalert(
        title = "Login Failed",
        text = "Invalid username or password. Please try again.",
        type = "error"
      )
      return() # Important: stop execution here
    }
    
    # Get the stored password hash for this user
    stored_hash <- old_pass()$password[user_row]
    
    # Verify the password - should be a try-catch since hash might be invalid
    is_valid <- tryCatch({
      password_verify(stored_hash, input$password)
    }, error = function(e) {
      # If there's an error with the hash, return FALSE
      FALSE
    })
    
    if (!is_valid) {
      shinyalert(
        title = "Login Failed",
        text = "Invalid username or password. Please try again.",
        type = "error"
      )
      return() # Important: stop execution here
    }
    
    # Check if account is expired
    current_date <- Sys.Date()
    expiry_date <- as.Date(old_pass()$valid_till[user_row]) # Fixed: user_row instead of user_idx
    
    if (current_date > expiry_date) {
      shinyalert(
        title = "Login Failed",
        text = "Your account has expired",
        type = "error"
      )
      return() # Important: stop execution here
    }
    
    # Get user role 
    user_role <- old_pass()$role[user_row] # Fixed: user_row instead of user_idx
    
    # Login successful
    shinyalert(
      title = paste("Welcome,", input$username),
      text = paste("You have successfully logged in as", user_role),
      type = "success"
    )
    
    # Set logged in state and user info
    values$authenticated <- TRUE
    values$user <- input$username
    values$role <- user_role
    
    # Hide login page, show main content
    shinyjs::removeClass(selector = "body", class = "login-screen")
    shinyjs::hide("login_page")
    shinyjs::show("main_app")
    
    if(!old_pass()$role[user_row] == "admin"){
      hideTab("nav_tabs", target = "Ticket Details")
      showTab("nav_tabs", target = "Create Ticket")
    } else if(old_pass()$role[user_row] == "admin"){
      showTab("nav_tabs", target = "Ticket Details")
      hideTab("nav_tabs", target = "Create Ticket")
    }
    
    y$hide()
    
  })
  
  observeEvent(input$new_user_create,{
    
    showModal(
      modalDialog(
        title = div(
          class = "d-flex align-items-center",
          tags$i(class = "bi bi-person-plus me-2", style = "font-size: 1.2rem;"),
          "Create New Account"
        ),
        
        # Registration form fields
        div(
          class = "registration-form",
          
          # Username field
          div(class = "mb-3",
              tags$label("Username", class = "form-label", `for` = "modal_new_username"),
              textInput("modal_new_username", NULL, placeholder = "Choose a username", width = "100%"),
              div(id = "username_feedback", class = "invalid-feedback")
          ),
          
          # Email field
          div(class = "mb-3",
              tags$label("Email", class = "form-label", `for` = "modal_new_email"),
              textInput("modal_new_email", NULL, placeholder = "Enter your email address", width = "100%"),
              div(id = "email_feedback", class = "invalid-feedback")
          ),
          
          # Password field
          div(class = "mb-3",
              tags$label("Password", class = "form-label", `for` = "modal_new_password"),
              passwordInput("modal_new_password", NULL, placeholder = "Create a password", width = "100%"),
              div(id = "password_feedback", class = "invalid-feedback")
          ),
          
          # Confirm password field
          div(class = "mb-3",
              tags$label("Confirm Password", class = "form-label", `for` = "modal_confirm_password"),
              passwordInput("modal_confirm_password", NULL, placeholder = "Confirm your password", width = "100%"),
              div(id = "confirm_password_feedback", class = "invalid-feedback")
          ),
          
          # Error message container
          shinyjs::show(
            div(id = "modal_register_error", 
                class = "alert alert-danger mt-3", 
                role = "alert")
          )
        ),
        
        footer = tagList(
          modalButton("Cancel"),
          actionButton("modal_create_account", "Create Account", 
                       class = "btn-success", 
                       icon = icon("user-plus"))
        ),
        
        size = "m",
        easyClose = FALSE
      )
    )
    
    
  })
  
  observeEvent(input$modal_create_account,{
    
    username <- input$modal_new_username
    password <- input$modal_new_password
    role <- "user"
    email <- input$modal_new_email
    confirm_password <- input$modal_confirm_password
    valid_till = ymd(Sys.Date())+160
    
    # Reset previous error messages
    shinyjs::show("modal_register_error")
    
    # Validation
    has_error <- FALSE
    
    # Username validation
    if (nchar(username) < 3) {
      shinyjs::html("username_feedback", "Username must be at least 3 characters")
      shinyjs::addClass("modal_new_username", "is-invalid")
      has_error <- TRUE
    } else if (username %in% old_pass()$username) {
      shinyjs::html("username_feedback", "Username already exists")
      shinyjs::addClass("modal_new_username", "is-invalid")
      has_error <- TRUE
    } else {
      shinyjs::removeClass("modal_new_username", "is-invalid")
    }
    
    # Email validation
    if (!validate_email(email)$valid) {
      shinyjs::html("email_feedback", "Please enter a valid email address")
      shinyjs::addClass("modal_new_email", "is-invalid")
      has_error <- TRUE
    } else if (email %in% old_pass()$email) {
      shinyjs::html("email_feedback", "Email already registered")
      shinyjs::addClass("modal_new_email", "is-invalid")
      has_error <- TRUE
    } else {
      shinyjs::removeClass("modal_new_email", "is-invalid")
    }
    
    
    # Password validation
    if (nchar(password) < 6) {
      shinyjs::html("password_feedback", "Password must be at least 6 characters")
      shinyjs::addClass("modal_new_password", "is-invalid")
      has_error <- TRUE
    } else {
      shinyjs::removeClass("modal_new_password", "is-invalid")
    }
    
    # Confirm password validation
    if (password != confirm_password) {
      shinyjs::html("confirm_password_feedback", "Passwords do not match")
      shinyjs::addClass("modal_confirm_password", "is-invalid")
      has_error <- TRUE
    } else {
      shinyjs::removeClass("modal_confirm_password", "is-invalid")
    }
    
    
    if (!has_error) {
      password_hash <- tryCatch({
        sodium::password_store(password)
      }, error = function(e) {})
      
      new_user_created <- data.frame(
        username = username,
        password = password_hash,
        email = email,
        valid_till = ymd(valid_till),
        role = role,
        stringsAsFactors = FALSE
      )
      
      old_users_created <- old_pass() %>% 
                           mutate(valid_till =  ymd(valid_till))
      
      current_users <- new_user_created
      
      passbind <-  bind_rows(current_users, old_users_created)
      editPasswords(passbind)
      
      print(current_users)
      
      
      updateTextInput(session,"modal_new_username",value = "")
      updateTextInput(session,"modal_new_password",value = "")
      updateTextInput(session,"modal_confirm_password",value = "")
      updateTextInput(session,"modal_new_email",value = "")
      
      
      shinyalert(
        title = paste("Welcome,", current_role()),
        text = "You have successfully created a new account.",
        type = "success"
      )
      
      
  }
    
  })
  
  output$log_username <- renderText({
    req(old_pass())  # Only proceed if user_data is available
    user_row <- which(old_pass()$username == input$username)
    
      paste0(old_pass()$username[user_row])
    
  })
  

  
  ## LogOut
  
  observeEvent(input$logout_btn,{
    shinyjs::hide("main_app")
    shinyjs::show("login_page")
  })
  
  observeEvent(input$logout_btn1,{
    shinyjs::hide("main_app")
    shinyjs::show("login_page")
  })
  
  
  
  # Ticket creation
  
  mail_who_login <- reactive({
    
    user_row <- which(old_pass()$username == input$username)
    
  if(length(user_row>0)) {
    
    adress_mail <- old_pass()$email[user_row]
    
    return(adress_mail)
  }
    
  })
  
  output$last_login_time <- renderText({
    req(old_pass())  
        paste0(mail_who_login())
  })
  
  observe({
    email_placeholder <- mail_who_login()  
    updateTextInput(session, "reporter_email", value = email_placeholder)
  })
  
  shinyjs::hide("ticket_id")
  shinyjs::hide("created_at")
  selected_ticket <- reactiveVal(NULL)
  
  
  data_sheet <- reactive({
    loadData()
  })
  

  w <- Waiter$new(id = "submit_ticket",
                  html = tagList(
                    div(
                      style = "position: absolute; left: 10px; top: 8px; display: flex; align-items: center;",
                      spin_loaders(color = "black")
                    )
                  ),
                  color = "transparent"
                  )

# Ticket registration  -----------------------------------------------------

  
## Push the ticket registration into the googlesheet workbook --------------


  # Initialize reactive values to store ticket information
  rv <- reactiveValues(
    created_at = NULL,
    ticket_id = NULL,
    ticket_name = NULL,
    ticket_title = NULL,
    ticket_contact = NULL,
    ticket_facility =  NULL,
    ticket_function = NULL,
    ticket_location = NULL,
    ticket_priority = NULL,
    ticket_description = NULL,
    reporter_email = NULL,
    ticket_status = "Open",  
    resolution_notes = NA,   
    assigned_to = NA,       
    resolved_at = NA        
  )
  
  
 observeEvent(input$submit_ticket,{
   
   w$show()
   
    if(input$ticket_title == "") {
       shinyalert("Missing Information", "Please provide a ticket title.", type = "warning")
       return()
    }
   
   if(input$ticket_description == "") {
     shinyalert("Missing Information", "Please provide a ticket description.", type = "warning")
     return()
   }
   
   if(input$reporter_email == "") {
     shinyalert("Missing Information", "Please provide your email address.", type = "warning")
     return()
   }
   
   if (!validate_email(input$reporter_email)$valid) {
     shinyalert("Wrong Email Adress", "Please enter a valid email address.", type = "warning")
     return()
   }
   
   
   rv$created_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
   rv$ticket_id <- generate_ticket_id()
   rv$ticket_name <- input$ticket_name
   rv$ticket_title <- input$ticket_title
   rv$ticket_location <- input$ticket_location
   rv$ticket_priority <- input$ticket_priority
   rv$ticket_description <- input$ticket_description
   rv$reporter_email <- input$reporter_email
   rv$ticket_contact <- input$ticket_contact
   rv$ticket_facility <- input$ticket_facility
   rv$ticket_function <- input$ticket_function
   
   
   new_ticket_df <- data.frame(
     ticket_id = rv$ticket_id,
     created_at = rv$created_at,
     ticket_name = rv$ticket_name,
     ticket_contact = rv$ticket_contact,
     ticket_function = rv$ticket_function,
     ticket_title = rv$ticket_title,
     ticket_location = rv$ticket_location,
     ticket_facility = rv$ticket_facility,
     ticket_priority = rv$ticket_priority,
     ticket_description = rv$ticket_description,
     reporter_email = rv$reporter_email,
     ticket_status = rv$ticket_status,
     resolution_notes = ifelse(is.na(rv$resolution_notes), "", rv$resolution_notes),
     assigned_to = ifelse(is.na(rv$assigned_to), "", rv$assigned_to),
     resolved_at = ifelse(is.na(rv$resolved_at), "", rv$resolved_at),
     stringsAsFactors = FALSE
   )
   
   saveData(new_ticket_df)
   
   updateTextInput(session, "ticket_title", value = "")
   updateTextInput(session, "ticket_contact", value = "")
   updateTextInput(session, "ticket_facility", value = "")
   updateTextInput(session, "ticket_function", value = "")
   updateTextInput(session, "ticket_name", value = "")
   updateSelectInput(session, "ticket_location", selected = "Center")
   updateSelectInput(session, "ticket_priority", selected = "Low")
   updateTextAreaInput(session, "ticket_description", value = "")
   updateTextInput(session, "reporter_email", value = "")
   
   email_body <- paste0(
     "<html><body>",
     "<p>Dear   ", new_ticket_df$ticket_name,"</p>", 
     "<p>Thank you for submitting a ticket to our system.</p>",
     "<p>Your ticket <strong>#", new_ticket_df$ticket_id, "</strong> has been received and will be processed shortly.</p>",
     "<h3>Ticket Details:</h3>",
     "<ul>",
     "<li><strong>Title:</strong> ", new_ticket_df$ticket_title, "</li>",
     "<li><strong>Priority:</strong> ", new_ticket_df$ticket_priority, "</li>",
     "<li><strong>Region:</strong> ", new_ticket_df$ticket_location, "</li>",
     "</ul>",
     "<p>You will receive updates as your ticket progresses.</p>",
     "<p>Thank you,<br>The Support Team</p>",
     "</body></html>"
   )
   
   mailR::send.mail(
     from = "nna217@shwarihealth.org",  
     to = new_ticket_df$reporter_email,
     bcc = c("aureolngako@yahoo.fr"),
     subject = paste0("Ticket Submission Confirmation - #", new_ticket_df$ticket_id),
     body = email_body,
     html = TRUE,
     smtp = list(
       host.name = "smtp.gmail.com",
       port = 465,                    
       user.name = "nna217@shwarihealth.org",  
       passwd = password_shac,   
       ssl = TRUE                  
     ),
     authenticate = TRUE,
     send = TRUE
   )
   
   # Success message
   shinyalert(
     title = "Success", 
     text = paste0("Ticket ",rv$ticket_id, " has been created successfully! Please check your Email"), 
     type = "success"
   )
   
   print(data_sheet())
   
   
   w$hide()
   
 })
 

# Tickets details ---------------------------------------------------------

 

 filtered_search_tickets <- reactive({
   tickets <- data_sheet()
   
   if(nrow(tickets) == 0) return(tickets)
   
   # Apply status filter
   if(input$search_status != "All") {
     tickets <- tickets[tickets$ticket_status == input$search_status, ]
   }
   
   # Apply search text filter if provided
   if(!is.null(input$ticket_search) && input$ticket_search != "") {
     search_text <- tolower(input$ticket_search)
    # tickets <- tickets[
      # grepl(search_text, tolower(tickets$ticket_title)) | 
      #   grepl(search_text, toupper(tickets$ticket_id)) |
     #    grepl(search_text, tolower(tickets$ticket_status)) |
    #     grepl(search_text, toupper(tickets$ticket_priority)), 
   #  ]
     
     
     title_match <- grepl(search_text, tolower(as.character(tickets$ticket_title)), fixed = TRUE)
     id_match <- grepl(search_text, tolower(as.character(tickets$ticket_id)), fixed = TRUE)
     status_match <- grepl(search_text, tolower(as.character(tickets$ticket_status)), fixed = TRUE)
     priority_match <- grepl(search_text, tolower(as.character(tickets$ticket_priority)), fixed = TRUE)
     
     # Combine matches with OR logic
     matches <- title_match | id_match | status_match | priority_match
     
     # Return filtered data
     tickets <- tickets[matches, ]
     
   }
   
   tickets
 })
 
 
output$search_tickets_table <- renderDT({
   
   req(filtered_search_tickets())
   
   if(nrow(filtered_search_tickets()) == 0) {
     return(data.frame(Message = "No tickets found matching your search criteria."))
   }
   
   # Select and arrange columns for display
   display_data <- filtered_search_tickets()[, c("ticket_id","ticket_name","ticket_title","ticket_contact","ticket_location", "ticket_status", "ticket_priority", "created_at")]
   colnames(display_data) <- c("ID","Name", "Title","Phone number", "Region", "Status", "Priority", "Created At")
   
   # Format the table
   datatable(
     display_data,
     options = list(
       pageLength = 5,
       dom = 'tip',
       ordering = TRUE
     ),
     rownames = FALSE,
     selection = "single"
   ) %>% 
     formatStyle(
       'Status',
       backgroundColor = styleEqual(
         c("Open", "In Progress", "Resolved"),
         c("#f8d7da", "#fff3cd", "#d4edda")
       )
     ) %>%
     formatStyle(
       'Priority',
       backgroundColor = styleEqual(
         c("High", "Medium", "Low"),
         c("#f8d7da", "#fff3cd", "#d4edda")
       )
     )
 })
 
observeEvent(input$search_tickets_table_rows_selected, {
  req(input$search_tickets_table_rows_selected)
  # Get the selected row index
  row_index <- input$search_tickets_table_rows_selected
  # Get all the data
  all_tickets <- data_sheet()
  
  
  selected_row <- all_tickets[row_index,]
  ticket_id <- all_tickets %>% slice(row_index) %>% pull(ticket_id)
  ticket_detail <- all_tickets[all_tickets$ticket_id == ticket_id, ]
  selected_ticket(ticket_id)
  if (nrow(ticket_detail) > 0) {
    updateSelectInput(session, "update_status", selected = ticket_detail$ticket_status)
    updateSelectInput(session, "update_assigned", selected = ticket_detail$assigned_to)
     
    if(!is.na(ticket_detail$resolution_notes)) {
      updateTextAreaInput(session, "resolution_notes", value = ticket_detail$resolution_notes)
    } else {
      updateTextAreaInput(session, "resolution_notes", value = "")
    }
    
}
  
  
  
})

output$ticket_selected <- reactive({
  return(!is.null(selected_ticket()))
})

outputOptions(output, "ticket_selected", suspendWhenHidden = FALSE) 


# Ticket detail outputs

output$detail_title <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  
  if (!is.null(selected_ticket())) {
    ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
    ticket$ticket_title
  }
 
})


output$detail_status <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ticket$ticket_status
  }
  
})

output$detail_priority <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ticket$ticket_priority
  }
})

output$detail_location <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  
  paste0(ticket$ticket_location," ","(",ticket$ticket_facility,")")
  
  }
})

output$detail_reporter <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ticket$reporter_email
  }
})

output$detail_created <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ticket$created_at
  }
})

output$detail_assigned <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ticket$assigned_to
  }
})

output$detail_description <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ticket$ticket_description}
})

output$is_resolved <- reactive({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  return(!is.na(ticket$resolved_at))}
})

outputOptions(output, "is_resolved", suspendWhenHidden = FALSE)
  
output$detail_resolved <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ifelse(is.na(ticket$resolved_at), "Not yet resolved", ticket$resolved_at)
  }
})

output$detail_resolution <- renderText({
  req(selected_ticket())
  all_tickets <- data_sheet()
  if (!is.null(selected_ticket)) {
  ticket <- all_tickets[all_tickets$ticket_id == selected_ticket(), ]
  ifelse(is.na(ticket$resolution_notes), "No resolution notes", ticket$resolution_notes)
  }
})


# Update the database

z <- Waiter$new(id = "update_ticket",
                html = tagList(
                  div(
                    style = "position: absolute; left: 10px; top: 8px; display: flex; align-items: center;",
                    spin_loaders(color = "black")
                  )
                ),
                color = "transparent"
)

observeEvent(input$update_ticket, {
  
  z$show()
  
  req(selected_ticket())
  all_tickets <- data_sheet()
  
  ticket_idx <- which(all_tickets$ticket_id == selected_ticket())
  old_status <- all_tickets$ticket_status[ticket_idx]
  new_status <- input$update_status
  
  
  # Update status
  all_tickets$ticket_status[ticket_idx] <- new_status
  
  # Update assigned person
  all_tickets$assigned_to[ticket_idx] <- input$update_assigned
  
  # If status changed to Resolved, update resolved_at and notes
  if(new_status == "Resolved" && old_status != "Resolved") {
    all_tickets$resolved_at[ticket_idx] <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    all_tickets$resolution_notes[ticket_idx] <- input$resolution_notes
  }
  
  #data_sheet(all_tickets)
  
  editData(all_tickets)
  
 # outputOptions(output, "ticket_selected", suspendWhenHidden = FALSE) 
  
  
  
  selected_ticket(NULL)
  
  updateSelectInput(session,inputId = "update_status",selected = "Open")
  updateSelectInput(session,inputId = "assigned_to",selected = "SI TEAM")
  
  specific_name <- if (input$update_assigned == "gn123@102@shwarihealth.org") {
    "Gilles"
  } else if (input$update_assigned == "nna217@shwarihealth.org") {
    "Aureol"
  } else if (input$update_assigned == "yn@102@shwarihealth.org") {
    "Yannick"
  } else if (input$update_assigned == "knls204@shwarihealth.org") {
    "Lens"
  } else if (input$update_assigned == "noaj203@shwarihealth.org") {
    "Annie"
  } else if (input$update_assigned == "yn1@102@shwarihealth.org") {
    "Alain"
  } else {
    NA 
  }
                  
  
  
  if (new_status != "Resolved") {
    
    ticket_idy <- all_tickets$ticket_id[ticket_idx]
    ticket_namex <- all_tickets$ticket_name[ticket_idx]
    ticket_titlex <- all_tickets$ticket_title[ticket_idx]  
    ticket_priotity <- all_tickets$ticket_priority[ticket_idx]
    email_reporter <- all_tickets$reporter_email[ticket_idx]
    ticket_region <- all_tickets$ticket_location[ticket_idx]
    resolution_notesx <- all_tickets$resolution_notes[ticket_idx]
    
    
    email_body <- paste0(
      "<html><body>",
      "<p>Dear  ", specific_name, ",</p>", 
      "<p>A new ticket has been assigned to you for resolution.</p>",
      "<p>Ticket <strong>#", ticket_idy, "</strong> requires your attention and has been added to your queue.</p>",
      "<h3>Ticket Details:</h3>",
      "<ul>",
      "<li><strong>Title:</strong> ", ticket_titlex, "</li>",
      "<li><strong>Priority:</strong> ", ticket_priotity, "</li>",
      "<li><strong>Region:</strong> ", ticket_region, "</li>",
      "<li><strong>Submitted by:</strong> ", ticket_namex, "</li>",
      "<li><strong>Email:</strong> ", email_reporter, "</li>",
      "</ul>",
      "<p>Please update the ticket status as you progress with the resolution.</p>",
      "<p>Thank you,<br>The Support Team</p>",
      "</body></html>"
    )
    
    
    mailR::send.mail(
      from = "nna217@shwarihealth.org",  
      to = input$update_assigned,
      bcc = c("aureolngako@yahoo.fr"),
      subject = paste0("Ticket - #", ticket_idy," ", "Assigned to You for Resolution"),
      body = email_body,
      html = TRUE,
      smtp = list(
        host.name = "smtp.gmail.com",
        port = 465,                    
        user.name = "nna217@shwarihealth.org",  
        passwd = password_shac,   
        ssl = TRUE                  
      ),
      authenticate = TRUE,
      send = TRUE
    )
    
    
    
  } else {
    
    ticket_idy <- all_tickets$ticket_id[ticket_idx]
    ticket_namex <- all_tickets$ticket_name[ticket_idx]
    ticket_titlex <- all_tickets$ticket_title[ticket_idx]  
    ticket_priotity <- all_tickets$ticket_priority[ticket_idx]
    email_reporter <- all_tickets$reporter_email[ticket_idx]
    ticket_region <- all_tickets$ticket_location[ticket_idx]
    resolution_notesx <- all_tickets$resolution_notes[ticket_idx]
    
    confirmation_email_body <- paste0(
      "<html><body>",
      "<p>Dear ", ticket_namex, ",</p>", 
      "<p>We are pleased to inform you that your ticket has been successfully resolved.</p>",
      "<p>Ticket <strong>#", ticket_idy, "</strong>: ", ticket_titlex, " has been marked as completed.</p>",
      "<h3>Resolution Details:</h3>",
      "<p>", resolution_notesx, "</p>",
      "<p>If you feel your issue has not been completely resolved, you can reopen this ticket by replying to this email within the next 7 days.</p>",
      "<p>Thank you for your patience,<br>The Support Team</p>",
      "</body></html>"
    )
    
    
    
    mailR::send.mail(
      from = "nna217@shwarihealth.org",  
      to = email_reporter ,
      cc = input$update_assigned,
      subject = paste0("Ticket - #", ticket_idy," ","Resolved"),
      body = confirmation_email_body,
      html = TRUE,
      smtp = list(
        host.name = "smtp.gmail.com",
        port = 465,                    
        user.name = "nna217@shwarihealth.org",  
        passwd = password_shac,   
        ssl = TRUE                  
      ),
      authenticate = TRUE,
      send = TRUE
    )
    
  }
  
 print(data_sheet())
  
  shinyalert("Success", "Ticket has been updated successfully!", type = "success")
  
  z$hide()
  
})

# Values Box 

output$tickets_opened <- renderText({
  
 value <-  data_sheet() %>% 
            group_by(ticket_status) %>% 
            count() %>% 
            filter(ticket_status ==  "Open") %>% 
     {
     if(nrow(.) == 0) {
       0
     } else {
       pull(., n)
     }
   }
  
   paste(value)
  
})
  
output$tickets_inprogress <- renderText({
  
  
  value <-  data_sheet() %>% 
    group_by(ticket_status) %>% 
    count() %>% 
    filter(ticket_status ==  "In Progress") %>% 
    {
      if(nrow(.) == 0) {
        0
      } else {
        pull(., n)
      }
    }
  
  paste(value)
  
})

output$tickets_resolved <- renderText({
  
  value <-  data_sheet() %>% 
    group_by(ticket_status) %>% 
    count() %>% 
    filter(ticket_status ==  "Resolved") %>% 
    {
      if(nrow(.) == 0) {
        0
      } else {
        pull(., n)
      }
    }
  
  paste(value)
  
})

observe({
  # check if all mandatory fields have a value
  mandatoryFilled <-
    vapply(fieldsMandatory,
           function(x) {
             !is.null(input[[x]]) && input[[x]] != ""
           },
           logical(1))
  mandatoryFilled <- all(mandatoryFilled)
  
  
  shinyjs::toggleState(id = "submit_ticket", condition = mandatoryFilled)
})

observe({
  # check if all mandatory fields have a value
  mandatoryFilled <-
    vapply(fieldsMandatory1,
           function(x) {
             !is.null(input[[x]]) && input[[x]] != ""
           },
           logical(1))
  mandatoryFilled <- all(mandatoryFilled)
  
  
  shinyjs::toggleState(id = "update_ticket", condition = mandatoryFilled)
})

observe({
  
  if(is.null(input$search_tickets_table_rows_selected)){
    
    shinyjs::disable("update_status")
    shinyjs::disable("update_assigned")
    
  } else if(input$search_tickets_table_rows_selected > 0){
    
    shinyjs::enable("update_status")
    shinyjs::enable("update_assigned")
    
  }
  
  #print(input$search_tickets_table_rows_selected)
  
  
})

output$table_overview <- renderDT({
  
  DT::datatable(
    data_sheet() %>% 
      select(ticket_id, ticket_title, ticket_priority, ticket_facility, 
             ticket_status, resolution_notes, assigned_to) %>% 
      filter(ticket_status == "Resolved") %>% select(-ticket_status),
    options = list(
      pageLength = 10,
      autoWidth = TRUE,
      scrollX = TRUE,
      order = list(list(0, 'desc')),  # Sort by ticket_id in descending order
      dom = 'Bfrtip',
      buttons = c('copy', 'csv', 'excel', 'pdf')
    ),
    rownames = FALSE,
    filter = 'top',
    class = 'cell-border stripe',
    colnames = c('Ticket ID', 'Title', 'Priority', 'Facility',
                 'Resolution Notes', 'Assigned To')
  )
  
})

observeEvent(input$overview, {
 
  showModal(
    modalDialog(
      title = div(
        class = "d-flex align-items-center",
        tags$i(class = "bi bi-person-plus me-2", style = "font-size: 1.2rem;"),
        "Tickets resolved in the database"
      ),
      size = "l",
      div(
        DTOutput("table_overview")
      ),
      footer = tagList(
        modalButton("Cancel")
      )
    )
  )
  
})

  
}
