# California Traffic Crash Analysis (2021-2023)
An interactive R Shiny application for exploring and analyzing traffic collision patterns across California from 2021 through 2023.

The application lets users examine nearly **472,000 crash records** by year, city, county, violation category, collision severity, collision type, day of the week, and time of day through interactive maps and visualizations. 

# Project Overview
Traffic collision data contains a large amount of geographic, temporal, and categorical information that can be difficult to interpret from raw data alone.

This project aims to create an interactive application that makes California crash data easier to explore and understand. We wish to explore and answer questions such as: 

- Where are certain types of crashes concentrated?
- Which violation categories appear most frequently?
- How do collision patterns vary across counties?
- When do crashes occur most often during the week or day?
- How does collision severity vary across different crash characteristics?

The app combines interactive geographic maps with exploratory visualizations, so users can investigate patterns using their own filters. 

# Dataset
The dataset contains **471,988 collision records and 20 variables** covering California crashes from 2021 to 2023. 

With key fields such as:
- Collision date and time
- Collision severity
- Number killed and/or injured
- Violation category
- Type of collision
- Pedestrian, bicycle, motorcycle, and truck indicators
- County and city
- Geographic coordinates

**Year Range**: 2021 - 2023
**Data source**: Statewide Integrated Traffic Records System (SWITRS)

# Tools Used
We used the following tools for this project:
- **RStudio** (R code)
- **Shiny**: interactive application framework
- **tidyverse**:  data manipulation and visualization
- **Leaflet**: interactive geographic maps
- **Plotly**: interactive charts
- **sf**: spatial data processing
- **maps**: California county geographic boundaries

# Data Preparation
Before diving into any analysis or data gathering, we first prepared the data. Using R, we took the necessary steps to clean the data by:

- Assigning explicit data types during import
- Converting collision dates to date objects
- Deriving the crash hour from collision time
- Converting numeric day-of-week values into readable weekday categories
- Standardizing county names for geographic joins
- Ordering collision severity from possible injury to fatal injury
- Preparing California county boundaries as spatial features for mapping

This lets us filter the data dynamically and join it with county-level geographic data. 

# Application Features
## 1. Interactive Crash Location Map
Users are welcomed with **Map 1**, where the user has full control over the following filters: 

- Year
- One or more California cities
- One or more violation categories
- Whether crash markers should be colored by collision severity or collision type

Individual collision records display their geographic coordinates, allowing users to explore where specific crash types occurred. 
```text
Note: 
Map 1 has the following default settings to be displayed:
Year: 2021
Cities: Berkeley
Violations: DUI
Color: Collision Severity 
```

## 2. County-Level Choropleth
Users can select Tab #2 called **Map 2**, which summarizes crashes across California counties. The user has the option to filter by the following: 

- Year
- Violation category
- One or more Collision severity

County boundaries are joined with the filtered crash totals and shaded by the number of matching collision records.

```text
Note:
Map 2 has the following default settings to be displayed:
Year: 2021
Violations: DUI
Collision Severity: possible injury, minor injury, severe injury, and fatal injury
```

## 3. Exploratory Analysis
The application also provides an additional tab called **More**. In this tab, we provide additional views for the selected year, violation category, and severity levels: 

- Crashes by County
- Crashes by Day of Week and Collision Severity
- Crashes by Hour of Day

Together, these views let you explore geographic and time-related patterns beyond crash locations. 

```text
Note:
More has the following default settings to be displayed:
Year: 2021
Violations: DUI
Collision Severity: possible injury, minor injury, severe injury, and fatal injury
```

# Key Findings
The analysis from the 2021-2023 datasets showed the following: 

- **Crash volume remained relatively stable across the three years**. The dataset contains **158,026**, **156,860**, and **157,102** in **2021**, **2022**, and **2023**, respectively.
- **Unsafe speed was the most frequently recorded violation category**, accounting for **138,700 crashes**, or approximately **29.4%** of all records.
- **Los Angeles County had the largest number of recorded crashes**, with **120,214 collisions**, representing approximately **25.5% of the entire dataset**.
- **Friday recorded the highest overall number of crashes**, with **75,802 collisions** across the three years.
- Crash frequency was the highest around **5:00 PM**, with about **36,183 recorded collisions**.
- The number of crashes classified as **fatal injury decreased from 4,023 in 2021 to 3,158 in 2023**, which is about a **21.5%** decline within the dataset.
- Recorded **DUI-related crashes decreased from 15,658 in 2021 to 14,190 in 2023**, which is about a **9.4% decrease**. 

These findings are descriptive and reflect crash counts in the dataset. County comparisons are not adjusted for differences in population, traffic volume, or vehicle miles traveled; therefore, we should not interpret them as measures of driving risk. 


# Repository Structure
```text
california-crash-analysis/
│
├── app.R
├── README.md
│
├── data/
│   └── README.md
│
└── images/
    ├── crash-location-map.png
    ├── county-choropleth.png
    └── exploratory-analysis.png
```

# Running the Application
The application requires R and the following packages: 

```R
library(shiny)
library(tidyverse)
library(leaflet)
library(plotly)
library(sf)
library(maps)
```

After downloading the dataset, ensure you save it as: 
```text
crashes_2021_2023.csv
```
in the project directory and run: 
```R
shiny::runApp()
```
### Alternatively 
The application is published on **Posit Connect**. Please see the **Links** section to access the application. 

[Links Section](https://github.com/brandon-marron/California-Crash-Data/tree/main#links)


# Limitations
This project analyzes raw collision counts, not collision rates. As a result, counties and cities with larger populations or higher traffic volumes would record more collisions. Additional analysis that incorporates population, roadway mileage, or vehicle miles traveled would be needed to compare relative crash risk across locations. 

# Links

**Application Link**: [California Traffic Crash Analysis (2021-2023)](https://brandonmarron-crashes-app.share.connect.posit.cloud/)

**LinkedIn**: [LinkedIn Profile](https://www.linkedin.com/in/brandonmarron)
