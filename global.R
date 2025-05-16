
# Install packages --------------------------------------------------------

pacman::p_load(
  shiny,
  shinyjs,
  htmltools,
  shinyalert,
  lubridate,
  DT,
  googlesheets4,
  mailR,
  bslib,
  dplyr,
  waiter,
  sodium,
  here,
  rio,
  shinycustomloader
)


# App theme ---------------------------------------------------------------


saveData <- function(data) {
  data <- data %>% as.list() %>% data.frame()
  # Add the data as a new row
  sheet_append("1jtkLqJYiw854yOmj6kONkonSqolfSjl2fS0wdzJmjUU", data)
}



#saveData(df)

# Function to generate a unique 5-character alphanumeric ticket ID
generate_ticket_id <- function() {
  # Define possible characters (excluding easily confused ones like 0/O and 1/I)
  chars <- c(LETTERS[!(LETTERS %in% c("O", "I"))], 
             as.character(2:9))
  
  # Generate a random 5-character string
  ticket_id <- paste0(sample(chars, 12, replace = TRUE), collapse = "")
  
  return(ticket_id)
  
}


password_shac <- "vzqm ofko yqyu dgly"


validate_email <- function(email) {
  # Check if email is empty
  if (email == "") {
    return(list(valid = FALSE, message = "Please provide your email address."))
  }
  
  # Common email validation regex pattern
  pattern <- "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
  
  # Check if the email matches the pattern
  valid <- grepl(pattern, email)
  
  if(!valid) {
    return(list(valid = FALSE, message = "Please enter a valid email address."))
  }
  
  # Extract domain and TLD
  domain <- tolower(sub(".*@", "", email))
  tld <- sub(".*\\.", "", domain)
  
  # Check for common domain typos
  common_typo_corrections <- list(
    "gmial.com" = "gmail.com",
    "gmil.com" = "gmail.com",
    "gmal.com" = "gmail.com",
    "yaho.com" = "yahoo.com",
    "ymail.com" = "yahoo.com",
    "hotmial.com" = "hotmail.com",
    "hotmal.com" = "hotmail.com",
    "outlok.com" = "outlook.com"
  )
  
  # Check if the complete domain is in our typo list
  if(domain %in% names(common_typo_corrections)) {
    suggested <- common_typo_corrections[[domain]]
    return(list(valid = FALSE, 
                message = paste0("Did you mean ", suggested, "?")))
  }
  
  # Check for multiple @ symbols
  if(length(gregexpr("@", email)[[1]]) > 1) {
    return(list(valid = FALSE, message = "Email cannot contain multiple @ symbols."))
  }
  
  # List of common TLDs
  common_tlds <- c("com", "org", "net", "edu", "gov", "mil", "co.uk", "ca", "de", "fr", "au", "jp", "io")
  
  # List of accepted organization domains (including your custom domain)
  accepted_org_domains <- c("shwarihealth.org")
  
  # If the domain is in our accepted list, it's valid regardless of other checks
  if(domain %in% accepted_org_domains) {
    return(list(valid = TRUE, message = "Valid email"))
  }
  
  # Check if TLD might be a typo of a common TLD
  if(!(tld %in% common_tlds) && nchar(tld) <= 2) {
    return(list(valid = FALSE, message = paste0("Domain extension .", tld, " appears unusual. Did you mean .com?")))
  }
  
  # Additional validation for TLD length
  if(nchar(tld) < 2 || nchar(tld) > 6) {
    return(list(valid = FALSE, message = "Domain extension appears invalid."))
  }
  
  return(list(valid = TRUE, message = "Valid email"))
}




loadData <- function() {
 
read_sheet("1jtkLqJYiw854yOmj6kONkonSqolfSjl2fS0wdzJmjUU")
  
}

editData <- function(data,sheet,range){
  data <- data %>% as.list() %>% data.frame()
  # Modify a specific row
  range_write(
    ss = "1jtkLqJYiw854yOmj6kONkonSqolfSjl2fS0wdzJmjUU",
    sheet = "linelist", 
    data = data
  )
  
}


fieldsMandatory <- c("ticket_name","ticket_contact",
                     "ticket_location","ticket_title","ticket_priority",
                     "ticket_description","reporter_email")

fieldsMandatory1 <- c("update_status","update_assigned")


labelMandatory <- function(label) {
  tagList(
    label,
    span("*", class = "mandatory_star")
  )
}

appCSS <- ".mandatory_star { color: red; }"

loadPasswords <- function() {
  read_sheet("1jtkLqJYiw854yOmj6kONkonSqolfSjl2fS0wdzJmjUU",sheet = "users_passwords")
}

editPasswords <- function(data,sheet,range){
  data <- data %>% as.list() %>% data.frame()
  # Modify a specific row
  range_write(
    ss = "1jtkLqJYiw854yOmj6kONkonSqolfSjl2fS0wdzJmjUU",
    sheet = "users_passwords", 
    data = data
  )
  
}

#users <- data.frame(
#  username = c("user", "admin"),
#  password = sapply(c("user1", "admin1"),sodium::password_store),
#  role = c("user", "admin"),
#  email = c("aureolngako@gmail.com","nna217@shwarihealth.org"),
#  valid_till = ymd(c("2025-10-21","2025-10-31")),
#  stringsAsFactors = FALSE
#)



# Import HF data ----------------------------------------------------------

hf_data <- here("data","fosa.xlsx") %>% 
            import()

















