
# User Interface ----------------------------------------------------------

ui <- page_fluid(
  useShinyjs(),
  useWaiter(),
  shinyjs::inlineCSS(appCSS),
  # Custom CSS for styling
  tags$head(
    tags$style(HTML("
      .header-container {
        background: linear-gradient(135deg, #1e5799 0%, #2989d8 50%, #207cca 51%, #7db9e8 100%);
        color: white;
        padding: 20px;
        border-radius: 10px;
        margin-bottom: 20px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      }
      .header-title {
        font-size: 28px;
        font-weight: bold;
        margin-bottom: 5px;
        margin-left: 120px
      }
       .header-image {
        max-width: 100%;
        height: auto;
        margin-right: 15px;
      
      }
      .header-subtitle {
        font-size: 16px;
        opacity: 0.9;
        margin-left: 120px
      }
      .header-icon {
        font-size: 40px;
        margin-right: 15px;
      }
      .stats-box {
        background-color: rgba(255, 255, 255, 0.2);
        border-radius: 8px;
        padding: 10px;
        text-align: center;
        margin: 5px;
      }
      .centered-card {
        max-width: 800px;
        margin-left: auto;
        margin-right: auto;
        box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
      }
      .stats-number {
        font-size: 24px;
        font-weight: bold;
      }
      .stats-label {
        font-size: 12px;
      }
    "))
  ),
  # Login Page - Initially shown
  div(id = "login_page",
      style = "height: 100vh; width: 100vw; position: fixed; top: 0; left: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
      
      div(
        class = "container d-flex align-items-center justify-content-center",
        style = "height: 100%;",
        
        card(
          class = "shadow-lg",
          style = "max-width: 400px; width: 100%; border-radius: 12px; border: none;",
          
          card_header(
            class = "text-center bg-white border-0 pt-3", # Reduced padding
            tags$img(src = "https://www.emploi.cm/sites/emploi.cm/files/styles/medium/public/logo/shac_logo.jpeg?itok=CT1naUEG", 
                     height = "50px", class = "mb-1"), # Reduced image size and margin
            h3("Support Ticket System", class = "fw-bold text-primary mb-0") # Changed to h3 from h2
          ),
          
          card_body(
            style = "padding-top: 0.75rem; padding-bottom: 0.75rem;", # Reduced padding
            div(class = "text-center text-muted mb-3", # Reduced margin
                "Please enter your credentials"),
            
            div(class = "mb-3", # Reduced margin
                tags$label("Username", class = "form-label fw-semibold small"), # Added 'small' class
                div(class = "input-group",
                    tags$span(class = "input-group-text bg-light",
                              icon("user", "fa-sm")), # Smaller icon
                    div(class = "border-start-0", 
                        textInput("username", NULL, placeholder = "Enter your username", width = "100%"))
                )
            ),
            
            div(class = "mb-3", # Reduced margin
                tags$label("Password", class = "form-label fw-semibold small"), # Added 'small' class
                div(class = "input-group",
                    tags$span(class = "input-group-text bg-light",
                              icon("lock", "fa-sm")), 
                    div(class = "border-start-0", 
                        passwordInput("password", NULL, placeholder = "Enter your password", width = "100%"))
                )
            ),
            
            div(class = "d-flex justify-content-between align-items-center mb-3", # Reduced margin
                actionLink("new_user_create","New user ? (Please create an account)")
            ),
            
            actionButton("login", "Sign In", 
                         class = "btn-primary w-100 py-1", # Reduced padding
                         style = "border-radius: 6px; font-weight: 600;")
          ),
          
          card_footer(
            class = "text-center text-muted bg-white border-0 pb-3 small", # Reduced padding, added 'small' class
            "© 2025 Shwari Health. All rights reserved."
          )
        )
      )
  ),
  
  # Beautiful Header
  shinyjs::hidden(
    div(id ="main_app",
  div(class = "header-container",
      fluidRow(
        column(1,
               # Replace icon with image
               div(class = "header-image", 
                   tags$img(src = "shac_icon.png", 
                            height = "60px", 
                            alt = "Ticket System Logo")
               )
        ),
        column(7,
               div(class = "header-title", "Ticket System"),
               div(class = "header-subtitle", "Track system breakout reports by M&E")
        ),
        column(4,
               fluidRow(
                 column(4, 
                        div(class = "stats-box",
                            div(class = "stats-number", textOutput("tickets_opened")),
                            div(class = "stats-label", "Open")
                        )
                 ),
                 column(4, 
                        div(class = "stats-box",
                            div(class = "stats-number", textOutput("tickets_inprogress")),
                            div(class = "stats-label", "In Progress")
                        )
                 ),
                 column(4, 
                        div(class = "stats-box",
                            div(class = "stats-number", textOutput("tickets_resolved")),
                            div(class = "stats-label", "Resolved")
                        )
                 )
               )
        )
      )
  ),
  
  # Main content with navigation
  navset_card_tab(
    id = "nav_tabs" ,
    nav_panel(
      title = "Create Ticket",
      icon = icon("ticket-alt"),
      fluidRow(
        column(
          width = 3,
          div(
            id = "login_info_container",
            class = "login-status-box shadow-sm",
            style = "
    padding: 16px; 
    margin: 15px 0; 
    border-radius: 8px; 
    background-color: #f0f7ff; 
    border-left: 4px solid #4a89dc;
    transition: all 0.3s ease;
  ",  div(
              class = "d-flex align-items-center mb-3",
              div(
                class = "me-3 text-center",
                style = "
        background-color: #4a89dc; 
        color: white; 
        width: 50px; 
        height: 50px; 
        border-radius: 50%; 
        display: flex; 
        align-items: center; 
        justify-content: center;
      ",
                tags$i(class = "fa fa-user", style = "font-size: 1.5rem;")
              ),
              div(
                style = "flex-grow: 1;",
                h4(
                  id = "welcome_msg", 
                  "Welcome", 
                  style = "margin: 0; color: #2c3e50; font-weight: 600;"
                ),
                p(
                  id = "login_status", 
                  textOutput("log_username"),
                  style = "margin: 0; color: #4a89dc; font-size: 0.9rem;"
                )
              )
            ),
            
            # Status indicators
            div(
              class = "mb-3 p-2",
              style = "background-color: rgba(255,255,255,0.7); border-radius: 6px;",
              
              div(
                class = "d-flex align-items-center mb-2",
                tags$i(class = "fa fa-clock-o me-2", style = "color: #6c757d;"),
                div(
                  style = "flex-grow: 1;",
                  p(
                    style = "margin: 0; font-size: 0.85rem; color: #6c757d;",
                    "Login E-mail:"
                  ),
                  p(
                    textOutput("last_login_time"), 
                    style = "margin: 0; font-weight: 500; color: #2c3e50;"
                  )
                )
              ),
              
              div(
                class = "d-flex align-items-center",
                tags$i(class = "fa fa-shield me-2", style = "color: #6c757d;"),
                div(
                  style = "flex-grow: 1;",
                  p(
                    style = "margin: 0; font-size: 0.85rem; color: #6c757d;",
                    "Session status:"
                  ),
                  p(
                    style = "margin: 0; font-weight: 500; color: #2c3e50;",
                    tags$span(
                      class = "badge bg-success",
                      style = "font-weight: 400;",
                      "Active"
                    )
                  )
                )
              )
            ),
            
            # Bottom action buttons
            div(
              class = "d-grid gap-2",
              actionButton(
                "logout_btn", 
                "Sign Out", 
                icon = icon("sign-out"),
                class = "btn-sm btn-outline-secondary"
              )
            ),
          ),hr(),
          actionLink(
            "overview", 
            tagList(
              icon("check-circle"), 
              "Look tickets resolved (it may help!!)"
            ),
            style = "color: #4a89dc; text-decoration: underline;"
          )
          ),
        column(9,
          div(class = "centered-card",
              card(
                card_header("Submit New Ticket",class = "bg-primary text-white"),
                card_body(
                  fluidRow(
                  textInput("ticket_id","Ticket Id"),
                  textInput("ticket_name",labelMandatory("Name"),placeholder = "Your name"),
                  textInput("ticket_contact",labelMandatory("Phone contact"),placeholder = "+237670000000"),
                  selectInput("ticket_location", labelMandatory("Region"), choices = c("Center","East")),
                  selectInput("ticket_facility", "Facility", choices = ""),
                  textInput("ticket_function", "Position", placeholder = "ex: M&E associate,M&E mentor"),
                  selectInput("ticket_title", labelMandatory("Type of issue"), choices = c("Issues with DAMA",
                                                                                           "Issues with EMR",
                                                                                           "General issues with computer",
                                                                                           "Issues with equipments (modem,printers etc.)",
                                                                                           "Issues with DHIS2",
                                                                                           "Other"
                                                                                           )),
                  selectInput("ticket_priority", labelMandatory("Priority"), choices = c("High", "Medium", "Low")),
                  column(12,
                  textAreaInput("ticket_description", labelMandatory("Description"), placeholder = "Detailed explanation of the issue", height = "150px",width = "580px")),
                  textInput("reporter_email", labelMandatory("Your Email Address"), placeholder = ""),
                  tags$small(labelMandatory("Required field")),
                  hr(),
                  div(style = "text-align: center;",
                      actionButton("submit_ticket", "Submit Ticket", class = "btn-primary", width = "200px")
                  ),
                  textInput("created_at","Created at",value = format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
                 )
                )
              )
          )
          
        )
    )
    ),
    nav_panel(
      title = "Ticket Details",
      icon = icon("chart-line"),
      
      # Add custom CSS for better styling
      tags$head(
        tags$style(HTML("
      .ticket-sidebar {
        background-color: #f8f9fa;
        border-right: 1px solid #e9ecef;
        padding: 15px;
      }
      .section-header {
        color: #2989d8;
        font-weight: 600;
        margin-top: 15px;
        margin-bottom: 15px;
        border-bottom: 2px solid #e9ecef;
        padding-bottom: 8px;
      }
      .action-btn {
        margin-top: 10px;
        width: 100%;
      }
      .ticket-card {
        border-radius: 8px;
        box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        margin-bottom: 20px;
        transition: all 0.3s ease;
      }
      .ticket-card:hover {
        box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        transform: translateY(-2px);
      }
      .card-header-custom {
        background: linear-gradient(135deg, #1e5799 0%, #2989d8 100%);
        color: white;
        font-weight: bold;
        padding: 12px 15px;
        border-top-left-radius: 8px;
        border-top-right-radius: 8px;
      }
      .ticket-header {
        color: #1e5799;
        border-bottom: 2px solid #e9ecef;
        padding-bottom: 10px;
        margin-bottom: 15px;
      }
      .info-label {
        color: #495057;
        font-weight: 600;
      }
      .info-value {
        color: #212529;
      }
      .status-badge {
        display: inline-block;
        padding: 4px 8px;
        border-radius: 4px;
        font-size: 12px;
        font-weight: bold;
      }
      .status-open {
        background-color: #ffc107;
        color: #212529;
      }
      .status-in-progress {
        background-color: #17a2b8;
        color: white;
      }
      .status-resolved {
        background-color: #28a745;
        color: white;
      }
      .priority-high {
        color: #dc3545;
      }
      .priority-medium {
        color: #fd7e14;
      }
      .priority-low {
        color: #28a745;
      }
      .detail-section {
        background-color: #f8f9fa;
        border-radius: 8px;
        padding: 15px;
        margin-bottom: 15px;
      }
    "))
      ),
      
      layout_sidebar(
        sidebar = sidebar(
          class = "ticket-sidebar",
          h4(icon("search"), "Ticket Search", class = "section-header"),
          textInput("ticket_search", NULL, placeholder = "Type to search..."),
          selectInput("search_status", "Filter by Status", 
                      choices = c("All", "Open", "In Progress", "Resolved"),
                      selected = "Open"),
          #hr(),
          h4(icon("tools"), "Actions", class = "section-header"),
          selectInput("update_status", labelMandatory("Update Status"), 
                      choices = c("Select status" = "", "In Progress" = "In Progress", "Resolved" = "Resolved"),
                      selected = ""),
          selectInput("update_assigned", labelMandatory("Assign To"), 
                      choices = c("Select the person assigned" = "",
                                  "Gille Ngassam" = "gn123@102@shwarihealth.org",
                                  "Aureol Ngako" = "nna217@shwarihealth.org",
                                  "Yannick" = "yn@102@shwarihealth.org",
                                  "Kamdem Lens" = "knls204@shwarihealth.org",
                                  "ANNIE NGO OUM" = "noaj203@shwarihealth.org",
                                  "Yomi Alain" = "myra180@shwarihealth.org"),
                      selected = ""
                      ),
          actionButton("update_ticket", "Update Ticket", 
                       class = "btn-warning action-btn",
                       icon = icon("edit")),
        # hr(),
          conditionalPanel(
            condition = "input.update_status == 'Resolved'",
            h4(icon("check-circle"), "Resolution", class = "section-header"),
            textAreaInput("resolution_notes", labelMandatory("Resolution Notes"), height = "100px")
          ), hr(),
        div(
          class = "d-grid gap-2",
          actionButton(
            "logout_btn1", 
            "Sign Out", 
            icon = icon("sign-out"),
            class = "btn-sm btn-outline-secondary"
          )
        )
        ),
        
        # Active Tickets card with enhanced styling
        div(class = "ticket-card",
            card(
              card_header(
                div(
                  tags$span(icon("ticket-alt"), style = "margin-right: 8px;"),
                  tags$span("Active Tickets")
                ),
                class = "card-header-custom"
              ),
              card_body(
                shinycustomloader::withLoader(DTOutput("search_tickets_table"),loader = "dnaspin")
              )
            )
        ),
        
        # Ticket Information card 
        div(class = "ticket-card",
            card(
              card_header(
                div(
                  tags$span(icon("info-circle"), style = "margin-right: 8px;"),
                  tags$span("Ticket Information")
                ),
                class = "card-header-custom"
              ),
              card_body(
                conditionalPanel(
                  condition = "output.ticket_selected",
                  h3(textOutput("detail_title"), class = "ticket-header"),
                  layout_column_wrap(
                    width = 1/2,
                    div(class = "detail-section",
                        tags$p(
                          tags$span("Status: ", class = "info-label"),
                          tags$span(class = "status-badge", id = "status-badge", textOutput("detail_status", inline = TRUE))
                        ),
                        tags$p(
                          tags$span("Priority: ", class = "info-label"),
                          tags$span(id = "priority-label", textOutput("detail_priority", inline = TRUE))
                        ),
                        tags$p(
                          tags$span("Location: ", class = "info-label"),
                          tags$span(class = "info-value", textOutput("detail_location", inline = TRUE))
                        )
                    ),
                    div(class = "detail-section",
                        tags$p(
                          tags$span("Created by: ", class = "info-label"),
                          tags$span(class = "info-value", textOutput("detail_reporter", inline = TRUE))
                        ),
                        tags$p(
                          tags$span("Created at: ", class = "info-label"),
                          tags$span(class = "info-value", textOutput("detail_created", inline = TRUE))
                        ),
                        tags$p(
                          tags$span("Assigned to: ", class = "info-label"),
                          tags$span(class = "info-value", textOutput("detail_assigned", inline = TRUE))
                        )
                    )
                  ),
                  hr(),
                  div(class = "detail-section",
                      h4(icon("file-alt"), "Description"),
                      div(style = "white-space: pre-wrap;", textOutput("detail_description"))
                  ),
                  conditionalPanel(
                    condition = "output.is_resolved",
                    div(class = "detail-section",
                        h4(icon("check-double"), "Resolution"),
                        tags$p(
                          tags$span("Resolved at: ", class = "info-label"),
                          tags$span(class = "info-value", textOutput("detail_resolved", inline = TRUE))
                        ),
                        tags$p(
                          tags$span("Resolution Notes: ", class = "info-label")
                        ),
                        div(style = "white-space: pre-wrap; margin-top: 10px;", textOutput("detail_resolution"))
                    )
                  )
                ),
                conditionalPanel(
                  condition = "!output.ticket_selected",
                  div(style = "text-align: center; padding: 50px 20px;",
                      icon("hand-point-up", style = "font-size: 3rem; color: #6c757d; margin-bottom: 15px;"),
                      tags$h4("No Ticket Selected"),
                      tags$p("Please select a ticket from the table above to view its details. Just click on the row you want to make changes", style = "color: #6c757d;")
                  )
                )
              )
            )
        )
      ),
      
      # JavaScript to add dynamic classes based on status and priority
      tags$script(HTML("
    $(document).ready(function() {
      // Function to update status badge class
      function updateStatusClass() {
        var status = $('#detail_status').text().trim();
        $('#status-badge').removeClass('status-open status-in-progress status-resolved');
        
        if (status === 'Open') {
          $('#status-badge').addClass('status-open');
        } else if (status === 'In Progress') {
          $('#status-badge').addClass('status-in-progress');
        } else if (status === 'Resolved') {
          $('#status-badge').addClass('status-resolved');
        }
      }
      
      // Function to update priority class
      function updatePriorityClass() {
        var priority = $('#detail_priority').text().trim();
        $('#priority-label').removeClass('priority-high priority-medium priority-low');
        
        if (priority === 'High') {
          $('#priority-label').addClass('priority-high');
        } else if (priority === 'Medium') {
          $('#priority-label').addClass('priority-medium');
        } else if (priority === 'Low') {
          $('#priority-label').addClass('priority-low');
        }
      }
      
      // Watch for changes
      const observer = new MutationObserver(function(mutations) {
        updateStatusClass();
        updatePriorityClass();
      });
      
      // Start observing
      observer.observe(document.getElementById('detail_status'), { 
        childList: true, 
        characterData: true,
        subtree: true
      });
      
      observer.observe(document.getElementById('priority-label'), { 
        childList: true, 
        characterData: true,
        subtree: true
      });
    });
  "))
    ),
  selected = "Create Ticket"
  )))
) 
