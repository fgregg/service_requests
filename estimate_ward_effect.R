library(broom)

service_requests = read.csv("./2022_service.csv")

service_requests$WARD = relevel(as.factor(service_requests$WARD), "42")
service_requests$SR_TYPE = as.factor(service_requests$SR_TYPE)

completed_service_requests = service_requests[service_requests$completed == 1, ]
not_immediately_closed = completed_service_requests[completed_service_requests$time_to_completion >= 1, ]

model = lm(log(time_to_completion) ~ 1 + SR_TYPE + WARD,
           not_immediately_closed)

summary(model)

tidy_lmfit <- tidy(model)

write.csv(tidy_lmfit, "ward_parameters.csv")
