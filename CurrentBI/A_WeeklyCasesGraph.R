##:::::::::::::::::::::::::::::::::
##  Graphs weekly cases counts and average cabinet price.
##  Andrew Borst 
##  Last Update 4/10/20
##:::::::::::::::::::::::::::::::::
library(tidyverse)
library(readr)
library(lubridate)
library(reshape2)
library(odbc)
library(jsonlite)

setwd("C:/Users/aborst/Documents")

j <- read_json("configuration.json")
login <- j[[1]]$login

con <- dbConnect(odbc(),
                 Driver = "SQL Server",
                 Server = "IN-SQL01",
                 Database = "COIN",
                 UID = login,
                 PWD = rstudioapi::askForPassword(),
                 Port = 1433)

v <- dbGetQuery(con, "SELECT * FROM vwReportKeyData")

v$SubmittedDate <- as.Date(v$SubmittedDate)

caseorders <- v %>% 
    select(JobNumber, SubmittedDate, OrderCaseTotal, AdjustPrice, OrderTotal, Brand, ProductLine, Overlay) %>% 
    filter(OrderCaseTotal > 0) %>%
    filter(OrderCaseTotal != "NULL") %>%  
    filter(year(SubmittedDate) == 2020) %>% 
    mutate(OrderCaseTotal = as.integer(OrderCaseTotal)) %>% 
    mutate(weekNo = case_when(is.na(SubmittedDate) ~ 99, TRUE ~ isoweek(SubmittedDate))) %>%
    mutate_if(is.numeric, funs(ifelse(is.na(.), 0, .))) %>% 
    mutate(NetPrice = OrderTotal + AdjustPrice)

weeklyBrand <- caseorders %>% 
    group_by(weekNo, Brand) %>% 
    summarise(Cases = sum(OrderCaseTotal), CaseAverage = sum(NetPrice)/sum(OrderCaseTotal)) 

weeklyBoth <- caseorders %>% 
  group_by(weekNo) %>% 
  summarise(Cases = sum(OrderCaseTotal), CaseAverage = sum(NetPrice)/sum(OrderCaseTotal)) %>% 
  mutate(Brand = "Both")  
  

ggplot(weeklyBrand) +
  geom_bar(aes(weekNo, Cases, fill=Brand), stat="identity") +
  geom_line(aes(weekNo, CaseAverage, color=Brand)) +
  geom_line(data=weeklyBoth, aes(weekNo, CaseAverage))

