#'get measurement baseline measurement data
#'@import dplyr
#'@import survival
#'@import ggplot2
#'@import ggfortify
#'@param cohortId_1
#'@param cohortId_2
#'@param cohortId_event
#'@param targetSurvivalEndDate
#'@export
eventFreeSurvival <- function(cohortId_1,
                              cohortId_2,
                              cohortId_event,
                              targetSurvivalEndDate){
  sub_totalCohort <- totalCohort %>% filter( cohortDefinitionId %in% c(cohortId_1,cohortId_2) )
  event_cohort    <- totalCohort %>% filter( cohortDefinitionId == cohortId_event )
  # unique(totalCohort$cohortDefinitionId)
  eventSubject <- event_cohort %>% select(subjectId, cohortStartDate)
  colnames(eventSubject)[2] <- "eventStartDate"
  
  templet <- sub_totalCohort %>% select(cohortDefinitionId,subjectId,cohortStartDate,cohortEndDate)
  
  eventReady <- left_join(sub_totalCohort,eventSubject, by = c("subjectId") ) %>%
    filter(cohortStartDate < eventStartDate) 
  eventInc <- left_join(templet,eventReady,by = c("cohortDefinitionId","subjectId","cohortStartDate","cohortEndDate") ) %>%
    mutate(eventDuration = as.numeric(difftime(eventStartDate,cohortStartDate,units = "days")),
           observDuration = as.numeric(difftime(cohortEndDate,cohortStartDate,units = "days")) ) %>%
    mutate(observDuration = if_else(observDuration>targetSurvivalEndDate,targetSurvivalEndDate,observDuration) )  %>%
    group_by(cohortDefinitionId, subjectId, cohortStartDate, observDuration) %>%
    summarise(survivalTime = min(eventDuration) ) %>%
    mutate(outcome = if_else(!is.na(survivalTime) & survivalTime <= observDuration, 1, 0) ) %>%
    mutate(survivalTime = if_else(!is.na(survivalTime),survivalTime,observDuration) ) %>%
    mutate(survivalTime = if_else(survivalTime > observDuration, targetSurvivalEndDate, survivalTime) )

  survfit <- survival::survfit( survival::Surv(survivalTime, outcome)~cohortDefinitionId, data = eventInc )
  
  ##result
  pvalue  <- survival::survdiff( survival::Surv(survivalTime, outcome)~cohortDefinitionId, data = eventInc )
  colourList <- c("red","blue","green","orange")
  eventFreeSurvivalPlot<- autoplot(survfit) + 
    scale_color_manual(values = colourList,aesthetics = "colour") +
    ylab("survival probability") + 
    xlab("time (years)") + 
    # annotate("text", label = "p-value < 0.001", x = 100, y = 0.85, size = 5) +
    theme_bw()+
    theme(legend.position = "none", 
          #c(0.9,0.85),
          legend.background = element_rect(colour = "black", size = 0.3),
          axis.text.x = element_text(size = 12),
          axis.title.x = element_text(size = 13),
          axis.text.y = element_text(size = 12),
          axis.title.y = element_text(size = 13),
          strip.text.x = element_text(size = 15))
  
  resultList <- list(pvalue = pvalue,
                     eventFreeSurvivalPlot = eventFreeSurvivalPlot)
  
}