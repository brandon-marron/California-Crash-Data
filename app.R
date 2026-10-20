# Title: California Crashes Between 2021 to 2023
# Description: We created an app that allows the user to navigate different violations and see the outcome of the crash in California.
# Author: Brandon Marron

# =======================================================
# Required Packages
# =======================================================

library(shiny)
library(tidyverse)
library(leaflet)
library(plotly)
library(sf)
library(maps)

# =======================================================
# Import data
# =======================================================

crashes = read_csv(
  file = "crashes_2021_2023.csv",
  col_types = cols(
    CASE_ID             = col_double(),
    ACCIDENT_YEAR       = col_integer(),
    COLLISION_DATE      = col_date(format = "%Y-%m-%d"),
    COLLISION_TIME      = col_double(),
    HOUR                = col_double(),
    DAY_OF_WEEK         = col_integer(),
    COLLISION_SEVERITY  = col_character(),
    NUMBER_KILLED       = col_integer(),
    NUMBER_INJURED      = col_integer(),
    VIOLATION_CATEGORY  = col_character(),
    TYPE_OF_COLLISION   = col_character(),
    PEDESTRIAN_ACCIDENT = col_character(),
    BICYCLE_ACCIDENT    = col_character(),
    MOTORCYCLE_ACCIDENT = col_character(),
    TRUCK_ACCIDENT      = col_character(),
    COUNTY              = col_character(),
    CITY                = col_character(),
    LOCATION            = col_character(),
    POINT_X             = col_double(),
    POINT_Y             = col_double()
  )
)

# -------------------------------------------------------
# Cleaning
# -------------------------------------------------------
day_names = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

crashes = crashes %>%
  mutate(
    HOUR = if_else(COLLISION_TIME >= 0 & COLLISION_TIME <= 2359,
                   COLLISION_TIME %/% 100, NA_real_),
    DAY_OF_WEEK = factor(DAY_OF_WEEK, levels = 1:7, labels = day_names),
    county = str_squish(str_to_lower(COUNTY))
  )

# City names in LOCATION are title-case city names (verified against the data)
list_of_cities = c("Redding", "Chico", "Roseville", "Elk Grove", "Stockton", "Modesto", "San Jose", "Fremont",
                   "Oakland", "Berkeley", "San Francisco", "Fresno", "Visalia", "Bakersfield", "Santa Clarita",
                   "Los Angeles", "Long Beach", "Fontana", "San Bernardino", "Riverside", "Irvine", "Santa Ana",
                   "Anaheim", "Moreno Valley", "San Diego", "Chula Vista")

sorted_cities = sort(list_of_cities)
sorted_vio    = sort(unique(crashes$VIOLATION_CATEGORY))

# Severity in natural order (least to most severe)
severity_levels = c("possible injury", "minor injury", "severe injury", "fatal injury")
sorted_severity = intersect(severity_levels, unique(crashes$COLLISION_SEVERITY))

crashes = crashes %>%
  mutate(COLLISION_SEVERITY = factor(COLLISION_SEVERITY, levels = severity_levels))

#Defaults just in case if a category were ever missing from the data
default_vio = if ("DUI" %in% sorted_vio) "DUI" else sorted_vio[1]

# -------------------------------------------------------
# Map of California
# -------------------------------------------------------
cal_counties_sf = st_as_sf(maps::map(database = "county", plot = FALSE, fill = TRUE)) %>%
  filter(str_starts(ID, "california,")) %>%
  mutate(county = str_remove(ID, "^california,")) %>%
  st_transform(crs = 4326)


# ===============================================
# Define UI
# ===============================================
ui <- fluidPage(
  
  titlePanel("Crashes in California from 2021 to 2023"),
  
  sidebarLayout(
    sidebarPanel(
      # ---------------------------------------------
      # first tab
      # ---------------------------------------------
      conditionalPanel(
        condition = "input.tabselected==1",
        h4("Map with Location of Crashes"),
        selectInput(inputId = "year1",
                    label = "Year:",
                    choices = c(2021, 2022, 2023)),
        checkboxGroupInput(inputId = "cities",
                           label = "Cities:",
                           choices = sorted_cities,
                           selected = "Berkeley"),
        checkboxGroupInput(inputId = "violation",
                           label = "Violations:",
                           choices = sorted_vio,
                           selected = default_vio),
        radioButtons(inputId = "color",
                     label = "Color:",
                     choices = c("Collision Severity", "Type of Collision"),
                     selected = "Collision Severity")
      ),
      
      # ---------------------------------------------
      # second tab
      # ---------------------------------------------
      conditionalPanel(
        condition = "input.tabselected==2",
        h4("Choropleth Map"),
        selectInput(inputId = "year2",
                    label = "Year:",
                    choices = c(2021, 2022, 2023)),
        radioButtons(inputId = "violation2",
                     label = "Violations:",
                     choices = sorted_vio,
                     selected = default_vio),
        checkboxGroupInput(inputId = "severity2",
                           label = "Collision Severity:",
                           choices = sorted_severity,
                           selected = sorted_severity)
      ),
      
      # ---------------------------------------------
      # third tab
      # ---------------------------------------------
      conditionalPanel(
        condition = "input.tabselected==3",
        h4("Exploratory Analysis"),
        selectInput(inputId = "year3",
                    label = "Year:",
                    choices = c(2021, 2022, 2023)),
        selectInput(inputId = "violation3",
                    label = "Violations:",
                    choices = sorted_vio,
                    selected = default_vio),
        checkboxGroupInput(inputId = "severity3",
                           label = "Collision Severity",
                           choices = sorted_severity,
                           selected = sorted_severity)
      )
      
    ),
    
    
    # -------------------------------------------------------
    # Main Panel with 3 tabsets
    # -------------------------------------------------------
    mainPanel(
      tabsetPanel(
        type = "tabs",
        tabPanel(title = "Map 1",
                 value = 1,
                 leafletOutput("map1", height = 600)),
        tabPanel(title = "Map 2",
                 value = 2,
                 leafletOutput("map2", height = 600)),
        tabPanel(title = "More",
                 value = 3,
                 plotlyOutput(outputId = "plot1"),
                 hr(),
                 plotOutput(outputId = "plot2"),
                 hr(),
                 plotOutput(outputId = "plot3")
        ),
        id = "tabselected"
      )
    )
    
  )
)



# ===============================================
# Server Logic
# ===============================================
server <- function(input, output) {
  
  # ---- Tab 1 data: crashes in chosen cities / violations / year ----
  filtered_data = reactive({
    req(input$cities, input$violation)
    
    crashes %>%
      filter(
        ACCIDENT_YEAR == as.integer(input$year1),
        LOCATION %in% input$cities,
        VIOLATION_CATEGORY %in% input$violation,
        !is.na(POINT_X), !is.na(POINT_Y)
      ) %>%
      mutate(label = paste0(format(COLLISION_DATE, "%m/%d/%Y"), " ", VIOLATION_CATEGORY))
  })
  
  # ---- Tab 2 data: counts by county ----
  vio = reactive({
    crashes %>%
      filter(
        ACCIDENT_YEAR == as.integer(input$year2),
        VIOLATION_CATEGORY == input$violation2,
        COLLISION_SEVERITY %in% input$severity2
      ) %>%
      group_by(county) %>%
      summarise(vio_crashes = n(), .groups = "drop")
  })
  
  ca_map = reactive({
    validate(need(length(input$severity2) > 0, "Select at least one collision severity."))
    validate(need(nrow(vio()) > 0, "No crashes match these filters."))
    left_join(cal_counties_sf, vio(), by = "county") %>%
      mutate(vio_crashes = replace_na(vio_crashes, 0L))
  })
  
  # ---- Tab 3 data: shared by all three plots ----
  more_data = reactive({
    validate(need(length(input$severity3) > 0, "Select at least one collision severity."))
    
    d = crashes %>%
      filter(
        ACCIDENT_YEAR == as.integer(input$year3),
        VIOLATION_CATEGORY == input$violation3,
        COLLISION_SEVERITY %in% input$severity3
      )
    validate(need(nrow(d) > 0, "No crashes match these filters."))
    d
  })
  
  # ------------------------------------------------
  # TAB 1: Map of crash locations
  # ------------------------------------------------
  output$map1 <- renderLeaflet({
    d = filtered_data()
    validate(need(nrow(d) > 0, "No crashes match these filters."))
    
    severity_color = c("possible injury" = "#ffeda0",
                       "minor injury"    = "#fd8d3c",
                       "severe injury"   = "#e31a1c",
                       "fatal injury"    = "#800026")
    
    if (input$color == "Collision Severity") {
      pal = colorFactor(palette = severity_color,
                        domain = names(severity_color),
                        levels = names(severity_color))
      vals = as.character(d$COLLISION_SEVERITY)
      legend_title = "Collision Severity"
    } else {
      pal = colorFactor(palette = "Paired",
                        domain = sort(unique(crashes$TYPE_OF_COLLISION)))
      vals = d$TYPE_OF_COLLISION
      legend_title = "Type of Collision"
    }
    
    leaflet(d, options = leafletOptions(preferCanvas = TRUE)) %>%
      addTiles() %>%
      addCircleMarkers(lng = ~POINT_X,
                       lat = ~POINT_Y,
                       radius = 5,
                       stroke = FALSE,
                       fillColor = pal(vals),
                       fillOpacity = 0.85,
                       label = ~label) %>%
      addLegend(position = "bottomleft",
                pal = pal,
                values = vals,
                title = legend_title,
                opacity = 1)
  })
  
  
  # -----------------------------------------------
  # TAB 2: Choropleth (California counties)
  # -----------------------------------------------
  output$map2 <- renderLeaflet({
    m = ca_map()
    mx = max(m$vio_crashes)
    zero_color = "lightgray"
    
    if (mx <= 5) {
      lv = 0:mx
      cols = c(zero_color, scales::viridis_pal()(mx))
      labs = as.character(lv)
      fill_colors = cols[m$vio_crashes + 1]
    } else {
      b = pretty(c(1, mx), n = 8)
      b = c(0, b[b > 0])                      
      k = length(b) - 1
      bin_cols = scales::viridis_pal()(k)
      
      lo = b[-length(b)] + 1
      hi = b[-1]
      bin_labs = ifelse(lo == hi,
                        scales::comma(lo),
                        paste0(scales::comma(lo), "–", scales::comma(hi)))
      
      cols = c(zero_color, bin_cols)
      labs = c("0", bin_labs)
      
      idx = cut(m$vio_crashes, breaks = b, labels = FALSE, right = TRUE)
      fill_colors = ifelse(m$vio_crashes == 0, zero_color, bin_cols[idx])
    }
    
    m %>%
      leaflet() %>%
      addTiles() %>%
      addPolygons(
        fillColor = fill_colors,
        fillOpacity = 1,
        weight = 1,
        color = "white",
        label = paste0(str_to_upper(m$county), ": ",
                       m$vio_crashes, " ",
                       input$violation2, " Crashes")
      ) %>%
      addLegend(
        colors = cols,
        labels = labs,
        title = paste0(input$violation2, " Crashes"),
        position = "bottomleft",
        opacity = 1
      )
  })
  
  # -----------------------------------------------
  # TAB 3: additional graphics
  # -----------------------------------------------
  output$plot1 <- renderPlotly({
    p = more_data() %>%
      count(COUNTY) %>%
      ggplot(aes(x = reorder(COUNTY, -n), y = n)) +
      geom_col(fill = "skyblue") +
      labs(title = paste0(input$violation3, " Crashes per County"),
           x = "County", y = "Number of Crashes") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1))
    ggplotly(p)
  })
  
  output$plot2 <- renderPlot({
    more_data() %>%
      count(DAY_OF_WEEK, COLLISION_SEVERITY, .drop = FALSE) %>%
      filter(COLLISION_SEVERITY %in% input$severity3) %>%
      ggplot(aes(x = DAY_OF_WEEK, y = n, fill = COLLISION_SEVERITY)) +
      geom_col() +
      facet_wrap(~ COLLISION_SEVERITY) +
      labs(title = paste0(input$violation3, " Crashes per Day of the Week (Faceted by Severity)"),
           x = "Day of the Week", y = "Number of Crashes",
           fill = "Collision Severity") +
      theme_minimal()
  })
  
  output$plot3 <- renderPlot({
    more_data() %>%
      filter(!is.na(HOUR)) %>%
      count(HOUR) %>%
      ggplot(aes(x = HOUR, y = n)) +
      geom_col(fill = "lightgreen") +
      scale_x_continuous(breaks = seq(0, 23, 2)) +
      labs(title = paste0(input$violation3, " Crashes per Hour"),
           x = "Hour of Day (0-23)", y = "Number of Crashes") +
      theme_minimal()
  })
  
} # closes server


# ===============================================
# Run the application
# ===============================================
shinyApp(ui = ui, server = server)