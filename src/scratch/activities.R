renv::install("grimbough/FITfileR")
renv::install("trackeR")

library(FITfileR)

file_path  <- "~/Downloads/Activities/11574189034_ACTIVITY.fit"
activity <- readFitFile(file_path)
records <- records(activity)

listMessageTypes(activity)
getMessagesByType(activity, message_type = "activity")

record <- records[[1]]

#####

library(trackeR)
library(sf)
track <- readGPX("~/Downloads/Activities/activity_11911329377.gpx")

