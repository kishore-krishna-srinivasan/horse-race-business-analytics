# Author: Kishore Krishna Srinivasan

install.packages(c("e1071", "caret","ggplot2","dplyr", "tidyr", "knitr","zoo","corrplot","crayon","vtreat","keras","tensorflow","magrittr","class","Metrics","tune"))
library(ggplot2)
library(dplyr)
library(tidyr)
library(knitr)
library(zoo)
library(corrplot)
library(caret)
library(crayon)
library(vtreat)
library(keras)
library(magrittr)
library(tensorflow)
library(class)
library(Metrics)
library(lubridate)
library(hms)


#Data Cleaning
# Load data from a CSV file
winpred <- read.csv("all_races05_19.csv")

#print shape of the dataset
shape <- dim(winpred)

# Print the number of rows and columns
print(shape)

#print the info of dataset
str(winpred)

# Removing non-numeric characters and convert to numeric
winpred$pos <- as.numeric(gsub("[^0-9.]", "", as.character(winpred$pos)))
winpred$pos[is.na(winpred$pos)] <- 0

#filling na with mean and median
winpred$or <- ifelse(is.na(winpred$or), mean(winpred$or, na.rm = TRUE), winpred$or)
winpred$ts <- ifelse(is.na(winpred$ts), mean(winpred$ts, na.rm = TRUE), winpred$ts)
winpred$rpr <- ifelse(is.na(winpred$rpr), mean(winpred$rpr, na.rm = TRUE), winpred$rpr)

# Forward fill missing values in the 'fin_time' column
winpred$fin_time <- zoo::na.locf(winpred$fin_time)

# Extract minutes and seconds and creating a POSIXct object
winpred$fin_time <- as.POSIXct(strptime(winpred$fin_time, format = "%M:%OS"))

#Creating minutes and seconds and creating new columns
winpred$fin_minutes <- minute(winpred$fin_time)
winpred$fin_seconds <- second(winpred$fin_time)

#Forward filling the minutes and seconds columns
winpred$fin_minutes <- zoo::na.locf(winpred$fin_minutes)
winpred$fin_seconds <- zoo::na.locf(winpred$fin_seconds)

# Dropping unwanted columns
winpred <- winpred[, -c(which(names(winpred) %in% c('class','weight','damsire','band','btn','Race_Money','race_name','dist.m.','season','Race_Money','gear','comment','prize_money','dec_clean','time','date','act_score','Period','sp','fin_time')))]

# Drop rows where Month or Year is null
winpred <- na.omit(winpred[, c("race_ID","course","dist.f.","going","race_group","race_type","Runners","horse_name","trainer","jockey","pos","dec","age","lbs","or","ts","rpr","sire","dam","prob","Month", "Year","fin_minutes","fin_seconds","exp_chance")])

#Checking the Number of nulls Present In the Dataset
null_counts <- colSums(is.na(winpred))
print(null_counts)

#**************************************************************************************************

#Explanatory Data Analysis

#Analysis on horse winning streak
number_of_wins <- winpred %>%
  filter(pos == 1) %>%
  group_by(horse_name) %>%
  summarise(total_wins = n())

# Display as a matrix (table)
kable(number_of_wins, caption = "Number of Races Won by Each Horse")

#Analysis on distance over position
# Filter the data frame to include only relevant columns
distance_position_data <- winpred[, c("dist.f.", "pos")]

# Plot a boxplot for positions across different race distances
ggplot(distance_position_data, aes(x = as.factor(dist.f.), y = pos, group = as.factor(dist.f.))) +
  geom_boxplot(fill = "skyblue") +
  labs(title = "Position Distribution Across Different Race Distances",
       x = "Race Distance (furlongs)",
       y = "Position") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x-axis labels for better readability

#Analysis on age over position
# Select rows where pos is 1
winning_horses <- winpred[winpred$pos == 1, ]
ggplot(winning_horses, aes(x = cut(age, breaks = seq(0, max(age), by = 2)), y = lbs)) +
  geom_boxplot() +
  labs(title = "Box Plot of weight in lbs over Age Groups of Winning Horses",
       x = "Age Group",
       y = "Weight in lbs") +
  theme_minimal()

#Analysis based on Trainer and Jockey 
# Bar plot for the top N jockeys
top_n_jockeys <- 25
winpred %>%
  group_by(jockey) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(top_n_jockeys) %>%
  ggplot(aes(x = reorder(jockey, -count), y = count, fill = jockey)) +
  geom_bar(stat = "identity") +
  labs(title = paste("Top", top_n_jockeys, "Frequent Jockeys"), x = "Jockey", y = "Count") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Bar plot for the top N trainers
top_n_trainers <- 25
winpred %>%
  group_by(trainer) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(top_n_trainers) %>%
  ggplot(aes(x = reorder(trainer, -count), y = count, fill = trainer)) +
  geom_bar(stat = "identity") +
  labs(title = paste("Top", top_n_trainers, "Frequent Trainers"), x = "Trainer", y = "Count") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Summary statistics of 'rpr' by jockey
winpred %>%
  group_by(jockey) %>%
  summarise(mean_rpr = mean(rpr), median_rpr = median(rpr)) %>%
  arrange(desc(mean_rpr)) %>%
  head(10)

# Summary statistics of 'rpr' by trainer
winpred %>%
  group_by(trainer) %>%
  summarise(mean_rpr = mean(rpr), median_rpr = median(rpr)) %>%
  arrange(desc(mean_rpr)) %>%
  head(10)

# Identify the top 25 trainers
top_trainers <- winpred %>%
  group_by(trainer) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(25)

# Filter the dataset for only the top 25 trainers
cleaned_data_top_trainers <- winpred %>%
  filter(trainer %in% top_trainers$trainer)

# Violin plot of 'rpr' by 'trainer' (top 25)
ggplot(cleaned_data_top_trainers, aes(x = trainer, y = rpr)) +
  geom_violin(fill = "lightgreen", trim = FALSE) +
  labs(title = "Violin Plot of Racing Post Rating by Top 25 Trainers", x = "Trainer", y = "Racing Post Rating") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Identify the top 25 jockeys
top_jockeys <- winpred %>%
  group_by(jockey) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(25)

# Filter the dataset for only the top 25 jockeys
cleaned_data_top_jockeys <- winpred%>%
  filter(jockey %in% top_jockeys$jockey)

# Violin plot of 'rpr' by 'jockey' (top 25)
ggplot(cleaned_data_top_jockeys, aes(x = jockey, y = rpr)) +
  geom_violin(fill = "lightblue", trim = FALSE) +
  labs(title = "Violin Plot of Racing Post Rating by Top 25 Jockeys", x = "Jockey", y = "Racing Post Rating") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Scatter plot of 'rpr' for jockeys and trainers
ggplot(winpred, aes(x = rpr, y = rpr, color = "red")) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(title = "Correlation Between Jockey and Trainer Performance", x = "Racing Post Rating (Jockey)", y = "Racing Post Rating (Trainer)")

#Analysis Based On Dam and Sire
# Bar plot for the top N dams
top_n_dams <- 25
winpred %>%
  group_by(dam) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(top_n_dams) %>%
  ggplot(aes(x = reorder(dam, -count), y = count, fill = dam)) +
  geom_bar(stat = "identity") +
  labs(title = paste("Top", top_n_dams, "Frequent Dams"), x = "Dam", y = "Count") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Bar plot for the top N sire
top_n_sires <- 25
winpred %>%
  group_by(sire) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(top_n_sires) %>%
  ggplot(aes(x = reorder(sire, -count), y = count, fill = sire)) +
  geom_bar(stat = "identity") +
  labs(title = paste("Top", top_n_sires, "Frequent Sires"), x = "Sire", y = "Count") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Identify the top 25 dams
top_dams <- winpred %>%
  group_by(dam) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(25)

# Filter the dataset for only the top 25 dams
cleaned_data_top_dams <- winpred %>%
  filter(dam %in% top_dams$dam)

# Violin plot of 'rpr' by 'dam' (top 25)
ggplot(cleaned_data_top_dams, aes(x = dam, y = rpr)) +
  geom_violin(fill = "lightcoral", trim = FALSE) +
  labs(title = "Violin Plot of Racing Post Rating by Top 25 Dams", x = "Dam", y = "Racing Post Rating") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Identify the top 25 sires
top_sires <- winpred %>%
  group_by(sire) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  head(25)

# Filter the dataset for only the top 25 sires
cleaned_data_top_sires <- winpred %>%
  filter(sire %in% top_sires$sire)

# Violin plot of 'rpr' by 'sire' (top 25)
ggplot(cleaned_data_top_sires, aes(x = sire, y = rpr)) +
  geom_violin(fill = "lightyellow", trim = FALSE) +
  labs(title = "Violin Plot of Racing Post Rating by Top 25 Sires", x = "Sire", y = "Racing Post Rating") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Scatter plot of 'rpr' for dams and sires
ggplot(winpred, aes(x = rpr, y = rpr, color = "red")) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(title = "Correlation Between Dam and Sire Performance", x = "Racing Post Rating (Dam)", y = "Racing Post Rating (Sire)")

#**************************************************************************************************

#Data Pre-Processing 

# Define categorical and numerical columns
categorical_cols <- c("race_ID","course", "going", "race_group", "race_type", "horse_name", "trainer", "jockey", "sire", "dam")
numerical_cols <- c("dist.f.", "Runners", "age", "lbs", "or", "ts", "rpr", "prob","pos","dec","Month","Year","fin_minutes","fin_seconds","exp_chance")

# Winsorize numerical columns
winsorize <- function(x, probs = c(0.05, 0.95)) {
  quantiles <- quantile(x, probs = probs, na.rm = TRUE)
  x[x < quantiles[1]] <- quantiles[1]
  x[x > quantiles[2]] <- quantiles[2]
  x
}

# Handle categorical columns (frequency encoding)
winpred_processed <- winpred %>%
  mutate(across(all_of(categorical_cols), ~ as.integer(factor(., levels = names(table(.)), labels = as.integer(table(.))))))

# Applying Winsorize to remove outliers and scale numerical columns
winpred_processed[numerical_cols] <- lapply(winpred_processed[numerical_cols], winsorize)
winpred_processed[numerical_cols] <- lapply(winpred_processed[numerical_cols], scale)

# Computing the correlation matrix
cor_matrix <- cor(winpred_processed)

# Plotting the correlation matrix
corrplot(cor_matrix, method="number")

# Dropping prob column as it has high correlation with column "exp_chance"
winpred_processed <- winpred_processed[, -c(which(names(winpred_processed) %in% c('prob')))]

# Computing the correlation matrix after dropping Column "prob"
cor_matrix <- cor(winpred_processed)

# Plotting the correlation matrix after dropping Column "prob"
corrplot(cor_matrix, method="number")

#**************************************************************************************************

#Data Preparation For Training and Testing

# Create a TRAINING dataset using first 70% of the records
# and the remaining 30% is used as TEST
training_records <- round(nrow(winpred_processed) * 0.7)
train_data <- winpred_processed[1:training_records, ]
test_data <- winpred_processed[-(1:training_records), ]

target_variable <- "pos"

# Creating training and test sets
X_train <- train_data[, !names(train_data) %in% target_variable]
y_train <- train_data[[target_variable]]

X_test <- test_data[, !names(test_data) %in% target_variable]
y_test <- test_data[[target_variable]]

#***************************************************************************************************

#Machine Learning Model Building and Prediction

#Model 1
#Building SVR Model
install.packages("e1071")
library(e1071)

# Create sequences for SVR
sequence_length <- 10
create_sequences_svr <- function(data, sequence_length) {
  sequences <- list()
  for (i in 1:(nrow(data) - sequence_length)) {
    sequences[[i]] <- data[i:(i + sequence_length -1), ]
  }
  return(sequences)
}

# Prepare Sequences for SVR
train_sequences_svr <- create_sequences_svr(train_data, sequence_length)
test_sequences_svr <- create_sequences_svr(test_data, sequence_length)

# Extract features and target variable for SVR
train_X_svr <- sapply(train_sequences_svr, function(x) x[1:sequence_length, "pos"])
train_Y_svr <- sapply(train_sequences_svr, function(x) x[sequence_length, "pos"])

test_X_svr <- sapply(test_sequences_svr, function(x) x[1:(sequence_length), "pos"])
test_Y_svr<- sapply(test_sequences_svr, function(x) x[sequence_length, "pos"])


# Prepare input and output for SVR
train_X_svr <- t(as.matrix(train_X_svr))
train_Y_svr <- as.numeric(train_Y_svr)

test_X_svr <- t(as.matrix(test_X_svr))
test_Y_svr <- as.numeric(test_Y_svr)

# Feature scaling
train_X_svr <- scale(train_X_svr)
test_X_svr <- scale(test_X_svr)

# Define the parameter grid for tuning
param_grid <- expand.grid(
  C = c(0.1, 1, 10),
  epsilon = c(0.1, 0.2, 0.5)
)

# Perform hyperparameter tuning using 10-fold cross-validation
svr_model <- svm(
  x = train_X_svr,
  y = train_Y_svr,
  scale = TRUE,
  type = "eps-regression",
  kernel = "radial",
  cost = param_grid$C[1],  
  epsilon = param_grid$epsilon[1]
)

# Make predictions on training and test data
train_predictions_svr <- predict(svr_model, train_X_svr)
test_predictions_svr <- predict(svr_model, test_X_svr)

# Evaluate the SVR model
train_rmse_svr <- sqrt(mean((train_predictions_svr - train_Y_svr)^2))
test_rmse_svr <- sqrt(mean((test_predictions_svr - test_Y_svr)^2))
train_mae_svr <- mean(abs(train_predictions_svr - train_Y_svr))
test_mae_svr <- mean(abs(test_predictions_svr - test_Y_svr))
train_r_squared_svr <- cor(train_predictions_svr, train_Y_svr)^2
test_r_squared_svr <- cor(test_predictions_svr, test_Y_svr)^2

# Print evaluation metrics for SVR model
cat("SVR RMSE (Train Data):", train_rmse_svr, "\n")
cat("SVR RMSE (Test Data):", test_rmse_svr, "\n")
cat("SVR MAE (Train Data):", train_mae_svr, "\n")
cat("SVR MAE (Test Data):", test_mae_svr, "\n")
cat("SVR R-squared (Train Data):", train_r_squared_svr, "\n")
cat("SVR R-squared (Test Data):", test_r_squared_svr, "\n")

# Creating data frame for Plotting
plot_data_test_svr <- data.frame(
  Actual = test_Y_svr,
  Predicted = as.vector(test_predictions_svr)
)

# Create the scatter plot for SVR
ggplot(plot_data_test_svr, aes(x = Actual, y = Predicted)) +
  geom_point(aes(color = "Actual"), alpha = 0.5) + 
  geom_point(aes(color = "Predicted"), alpha = 0.5) +
  labs(title = "Actual vs Predicted Values (SVR)", x = "Actual", y = "Predicted") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

#***************************************************************************************************

#Model 2
#Building Elastic Net Regression Model
install.packages("glmnet")
library("glmnet")

# Define the hyperparameter grid for Elastic Net
alpha_values <- seq(0, 1, by = 0.1)
lambda_values <- 10^seq(-3, 3, by = 0.5)
hyperparameter_grid <- expand.grid(alpha = alpha_values, lambda = lambda_values)

# Create sequences for Elastic Net
sequence_length <- 10
create_sequences_elastic_net <- function(data, sequence_length) {
  sequences <- list()
  for (i in 1:(nrow(data) - sequence_length + 1)) {
    sequences[[i]] <- data[i:(i + sequence_length - 1), ]
  }
  return(sequences)
}

# Prepare input and output for Elastic Net
train_sequences_elastic_net <- create_sequences_elastic_net(train_data, sequence_length)
test_sequences_elastic_net <- create_sequences_elastic_net(test_data, sequence_length)

# Extract features and target variable for Elastic Net
train_X_elastic_net <- sapply(train_sequences_elastic_net, function(x) x[1:sequence_length, "pos"])
train_X_elastic_net<- t(as.matrix(train_X_elastic_net))
train_Y_elastic_net <- as.vector(sapply(train_sequences_elastic_net, function(x) x[sequence_length, "pos"]))

test_X_elastic_net <- sapply(test_sequences_elastic_net, function(x) x[1:sequence_length, "pos"])
test_X_elastic_net <- t(as.matrix(test_X_elastic_net))
test_Y_elastic_net <- as.vector(sapply(test_sequences_elastic_net, function(x) x[sequence_length, "pos"]))

# Fit Elastic Net model with hyperparameter tuning
elastic_net_model <- cv.glmnet(
  x = train_X_elastic_net,
  y = train_Y_elastic_net,
  alpha = 0.5, 
  lambda = hyperparameter_grid$lambda,
  nfolds = 5
)

# Make predictions on training and test data
train_predictions_elastic_net <- predict(elastic_net_model, newx = train_X_elastic_net, s = "lambda.min")
test_predictions_elastic_net <- predict(elastic_net_model, newx = test_X_elastic_net, s = "lambda.min")

# Evaluate the Elastic Net model
train_rmse_elastic_net <- sqrt(mean((train_predictions_elastic_net - train_Y_elastic_net)^2))
test_rmse_elastic_net <- sqrt(mean((test_predictions_elastic_net - test_Y_elastic_net)^2))

# Calculate additional metrics
train_mae_elastic_net <- mean(abs(train_predictions_elastic_net - train_Y_elastic_net))
test_mae_elastic_net <- mean(abs(test_predictions_elastic_net - test_Y_elastic_net))
train_r_squared_elastic_net <- cor(train_predictions_elastic_net, train_Y_elastic_net)^2
test_r_squared_elastic_net <- cor(test_predictions_elastic_net, test_Y_elastic_net)^2

# Print evaluation metrics for Elastic Net model
cat("Elastic Net RMSE (Train Data):", train_rmse_elastic_net, "\n")
cat("Elastic Net RMSE (Test Data):", test_rmse_elastic_net, "\n")
cat("Elastic Net MAE (Train Data):", train_mae_elastic_net, "\n")
cat("Elastic Net MAE (Test Data):", test_mae_elastic_net, "\n")
cat("Elastic Net R-squared (Train Data):", train_r_squared_elastic_net, "\n")
cat("Elastic Net R-squared (Test Data):", test_r_squared_elastic_net, "\n")

# Creating data frame for Plotting
plot_data_test_elastic_net <- data.frame(
  Actual = test_Y_elastic_net,
  Predicted = as.vector(test_predictions_elastic_net),
)

# Creating the scatter plot for Elastic Net Predictions
ggplot(plot_data_test_elastic_net, aes(x = Actual, y = Predicted))+
  geom_point(aes(color = "Actual"), alpha = 0.5) + 
  geom_point(aes(color = "Predicted"), alpha = 0.5) +
  labs(title = "Actual vs Predicted Values (Elastic Net)", x = "Actual", y = "Predicted") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

#**************************************************************************************************

#Model 3
#Building XGboost Model
install.packages("xgboost")
library(xgboost)

# Create sequences for XGBoost
sequence_length <- 10
create_sequences_xgb <- function(data, sequence_length) {
  sequences <- list()
  for (i in 1:(nrow(data) - sequence_length)) {
    sequences[[i]] <- data[i:(i + sequence_length -1), ]
  }
  return(sequences)
}

# Prepare input and output for XGBoost
train_sequences_xgb <- create_sequences_xgb(train_data, sequence_length)
test_sequences_xgb <- create_sequences_xgb(test_data, sequence_length)

# Extract features and target variable for XGBoost
train_X_xgb <- sapply(train_sequences_xgb, function(x) x[1:sequence_length, "pos"])
train_Y_xgb <- sapply(train_sequences_xgb, function(x) x[sequence_length, "pos"])

test_X_xgb <- sapply(test_sequences_xgb, function(x) x[1:(sequence_length), "pos"])
test_Y_xgb <- sapply(test_sequences_xgb, function(x) x[sequence_length, "pos"])

# Convert to matrix format for XGBoost
# Convert to matrix format for XGBoost
train_X_xgb <- t(as.matrix(train_X_xgb))
train_matrix_xgb <- xgb.DMatrix(data = train_X_xgb, label = as.numeric(train_Y_xgb))

test_X_xgb <- t(as.matrix(test_X_xgb))
test_matrix_xgb <- xgb.DMatrix(data = test_X_xgb, label = as.numeric(test_Y_xgb))

# Define the XGBoost model
model_xgb <- xgboost(
  data = train_matrix_xgb,
  objective = "reg:squarederror",
  nrounds = 10,
  print_every_n = 1
)

# Get feature importance scores
importance_scores <- xgb.importance(model = model_xgb)

# Make predictions on training and test data
train_predictions_xgb <- predict(model_xgb, as.matrix(train_X_xgb))
test_predictions_xgb <- predict(model_xgb, as.matrix(test_X_xgb))

# Evaluate the XGBoost model
rmse_xgb <- sqrt(mean((test_predictions_xgb - test_Y_xgb)^2))
mae_xgb <- mean(abs(test_predictions_xgb - test_Y_xgb))
r_squared_xgb <- cor(test_predictions_xgb, test_Y_xgb)^2

# Flatten the predictions as they might be returned as lists
train_predictions_xgb <- matrix(unlist(train_predictions_xgb), ncol = 1)
test_predictions_xgb <- matrix(unlist(test_predictions_xgb), ncol = 1)

# Calculate evaluation metrics for XGBoost model
train_rmse_xgb <- sqrt(mean((train_predictions_xgb - train_Y_xgb)^2))
train_mae_xgb <- mean(abs(train_predictions_xgb - train_Y_xgb))
train_r_squared_xgb <- cor(train_predictions_xgb, train_Y_xgb)^2

test_rmse_xgb <- sqrt(mean((test_predictions_xgb - test_Y_xgb)^2))
test_mae_xgb <- mean(abs(test_predictions_xgb - test_Y_xgb))
test_r_squared_xgb <- cor(test_predictions_xgb, test_Y_xgb)^2

# Print evaluation metrics for XGBoost model
cat("XGBoost RMSE (Train Data):", train_rmse_xgb, "\n")
cat("XGBoost RMSE (Test Data):", test_rmse_xgb, "\n")
cat("XGBoost MAE (Train Data):",train_mae_xgb, "\n")
cat("XGBoost MAE (Test Data):", test_mae_xgb, "\n")
cat("XGBoost R-squared (Train Data):", train_r_squared_xgb, "\n")
cat("XGBoost R-squared (Test Data):", test_r_squared_xgb, "\n")

# Create data frame for XGBoost testing data predictions
plot_data_test_xgb <- data.frame(
  Actual = test_Y_xgb,
  Predicted = as.vector(test_predictions_xgb)
)

# Create the scatter plot for XGBoost
ggplot(plot_data_test_xgb, aes(x = Actual, y = Predicted)) +
  geom_point(aes(color = "Actual"), alpha = 0.5) + 
  geom_point(aes(color = "Predicted"), alpha = 0.5) +
  labs(title = "Actual vs Predicted Values (XGBoost)", x = "Actual", y = "Predicted") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

#***************************************************************************************************

#Model 4
#Building Decision Tree Model
install.packages("rpart")
library(rpart)

# Define the decision tree model with hyperparameter tuning
tune_grid <- seq(0.001, 0.01, by = 0.001)
cp_values <- numeric(length(tune_grid))
rmse_values <- numeric(length(tune_grid))

# Assuming 'pos' is the target variable
formula <- as.formula("pos ~ .")

for (i in seq_along(tune_grid)) {
  cp <- tune_grid[i]
  tree_model <- rpart(formula, data = train_data, method = "anova", cp = cp)
  cp_values[i] <- cp
  rmse_values[i] <- sqrt(mean((predict(tree_model, newdata = test_data) - test_data$pos)^2))
}

# Find the optimal CP value
optimal_cp <- cp_values[which.min(rmse_values)]

# Train the final decision tree model with the optimal CP value
final_tree_model <- rpart(formula, data = train_data, method = "anova", cp = optimal_cp)

# Make predictions on training and test data
train_predictions_tree <- predict(final_tree_model, newdata = train_data)
test_predictions_tree <- predict(final_tree_model, newdata = test_data)

# Evaluate the decision tree model on training data
train_rmse_tree <- sqrt(mean((train_predictions_tree - train_data$pos)^2))
train_mae_tree <- mean(abs(train_predictions_tree - train_data$pos))
train_r_squared_tree <- cor(train_predictions_tree, train_data$pos)^2 

# Evaluate the decision tree model on test data
test_rmse_tree <- sqrt(mean((test_predictions_tree - test_data$pos)^2))
test_mae_tree <- mean(abs(test_predictions_tree - test_data$pos))
test_r_squared_tree <- cor(test_predictions_tree, test_data$pos)^2  


# Print evaluation metrics for the decision tree model on training and test data
cat("Decision Tree RMSE (Train Data):", train_rmse_tree, "\n")
cat("Decision Tree MAE (Train Data):", train_mae_tree, "\n")
cat("Decision Tree R-squared (Train Data):", train_r_squared_tree, "\n")

cat("Decision Tree RMSE (Test Data):", test_rmse_tree, "\n")
cat("Decision Tree MAE (Test Data):", test_mae_tree, "\n")
cat("Decision Tree R-squared (Test Data):", test_r_squared_tree, "\n")

# Create data frame for Decision Tree testing data predictions
plot_data_test_tree <- data.frame(
  Actual = test_data$pos,
  Predicted = as.vector(test_predictions_tree)
)

# Scatter plot for combined data
ggplot(plot_data_test_tree , aes(x = Actual, y = Predicted)) +
  geom_point(aes(color = "Actual"), alpha = 0.5) + 
  geom_point(aes(color = "Predicted"), alpha = 0.5) +
  labs(title = "Actual vs Predicted Values (Decision Tree)", x = "Actual", y = "Predicted") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

#***************************************************************************************************

# Model 5
#Light Gradient Boosting Machine (LightGBM) Regression
install.packages("lightgbm")
library(lightgbm)

# Converting data frames to matrices
train_matrix <- as.matrix(X_train)
test_matrix <- as.matrix(X_test)

# Converting data to LightGBM Dataset
train_data <- lgb.Dataset(data = train_matrix, label = y_train)
test_data <- lgb.Dataset(data = test_matrix, label = y_test)

# Definition of LightGBM parameters
params <- list(
  objective = "regression",
  metric = "rmse",
  num_leaves = 31,
  learning_rate = 0.05,
  n_estimators = 100
)

# Training the model
set.seed(123) # For reproducibility
model <- lgb.train(params, train_data, valids = list(test = test_data), verbose = 0)

# Making predictions
train_predictions <- predict(model, train_matrix)
test_predictions <- predict(model, test_matrix)

# Calculation of evaluation metrics

# Mean Absolute Error
train_mae <- mean(abs(train_predictions - y_train))
test_mae <- mean(abs(test_predictions - y_test))

# RMSE (Root Mean Squared Error)
train_rmse <- sqrt(mean((train_predictions - y_train)^2))
test_rmse <- sqrt(mean((test_predictions - y_test)^2))

# R-squared
train_r_squared <- cor(train_predictions, y_train)^2
test_r_squared <- cor(test_predictions, y_test)^2

# Printing the metrics
cat("Mean Absolute Error for Train Data:", train_mae, "\n")
cat("Mean Absolute Error for Test Data:", test_mae, "\n")
cat("RMSE for Train Data:", train_rmse, "\n")
cat("RMSE for Test Data:", test_rmse, "\n")
cat("R-Squared for Train Data:", train_r_squared, "\n")
cat("R-Squared for Test Data:", test_r_squared, "\n")

# Creating a data frame for plotting
plot_data <- data.frame(
  Actual = y_test,
  Predicted = test_predictions
)

# Scatter plot
ggplot(plot_data, aes(x = Actual, y = Predicted)) +
  geom_point() +
  labs(x = "Actual", y = "Predicted", title = "Actual vs Predicted (LightGBM Model)") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

# Calculating variable importance for LightGBM Regression
importance <- lgb.importance(model)

# Converting the importance to a data frame
importance_df <- data.frame(
  Variable = rownames(importance),
  Importance = importance$Gain
)

# Ordering the data frame based on importance
importance_df <- importance_df[order(importance_df$Importance, decreasing = TRUE), ]

# Plotting the variable importance
ggplot(importance_df, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +  # Flipping axes for better readability
  labs(title = "Variable Importance in LightGBM Model",
       x = "Variable",
       y = "Importance") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90))

#Hyper parameter tuning for Light Gradient Boosting Machine Regression

# Converting the training and test data to LightGBM datasets
dtrain <- lgb.Dataset(data = as.matrix(X_train), label = y_train)

# Defining hyperparameters to tune the model
num_leaves_choices <- c(31, 50, 70)
learning_rate_choices <- c(0.01, 0.1, 0.3)
n_estimators_choices <- c(100, 200, 300)
max_depth_choices <- c(-1, 5, 10)

# Initializing the best model and its associated error
best_model <- NULL
best_rmse <- Inf

# Hyperparameter tuning loop
for (num_leaves in num_leaves_choices) {
  for (learning_rate in learning_rate_choices) {
    for (n_estimators in n_estimators_choices) {
      for (max_depth in max_depth_choices) {
        # Define model parameters
        params <- list(
          objective = "regression",
          metric = "rmse",
          num_leaves = num_leaves,
          learning_rate = learning_rate,
          n_estimators = n_estimators,
          max_depth = max_depth
        )
        
        # Training the model
        model <- lgb.train(params, dtrain, 100)
        
        # Making predictions and calculating RMSE
        predictions <- predict(model, as.matrix(X_test))
        rmse <- sqrt(mean((predictions - y_test)^2))
        
        # Updating the best model if current model is better
        if (rmse < best_rmse) {
          best_rmse <- rmse
          best_model <- model
        }
      }
    }
  }
}

# Making predictions using the best model
best_predictions <- predict(best_model, as.matrix(X_test))

# Calculation of evaluation metrics
test_mae <- mean(abs(best_predictions - y_test))
test_rmse <- sqrt(mean((best_predictions - y_test)^2))
test_r_squared <- cor(best_predictions, y_test)^2

# Printing the metrics
cat("Best RMSE:", best_rmse, "\n")
cat("Mean Absolute Error for Test Data:", test_mae, "\n")
cat("RMSE for Test Data:", test_rmse, "\n")
cat("R-Squared for Test Data:", test_r_squared, "\n")

# Creating a data frame for plotting
plot_data <- data.frame(
  Actual = y_test,
  Predicted = test_predictions
)

# Scatter plot
ggplot(plot_data, aes(x = Actual, y = Predicted)) +
  geom_point() +
  labs(x = "Actual", y = "Predicted", title = "Actual vs Predicted (Best LightGBM Model)") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

#***************************************************************************************************

# Model 6
# Linear Regression
install.packages("glmnet")
library("glmnet")

# Initializing a linear regression model
lin_model <- lm(y_train ~ ., data = X_train)

# Making predictions on the test set
y_pred_lm <- predict(lin_model, newdata = X_test)

# Calculating Root Mean Squared Error (RMSE)
rmse_lm <- sqrt(mean((y_pred_lm - y_test)^2))
cat("Root Mean Squared Error (RMSE) for Linear Regression Model : ", rmse_lm, "\n")

# Mean Absolute Error (MAE)
mae_lm <- mean(abs(y_pred_lm - y_test))
cat("Mean Absolute Error (MAE) for Linear Regression Model : ", mae_lm, "\n")

# R-squared (R2)
rsquared_lm <- 1 - sum((y_test - y_pred_lm)^2) / sum((y_test - mean(y_test))^2)
cat("R-squared (R2)for Linear Regression Model : ", rsquared_lm, "\n") 

# Creating a data frame for plotting
plot_data_lm <- data.frame(
  Actual = y_test,
  Predicted = y_pred_lm
)

# Scatter plot
ggplot(plot_data_lm, aes(x = Actual, y = Predicted)) +
  geom_point() +
  labs(x = "Actual", y = "Predicted", title = "Actual test data vs Linear Regression Model predictions") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

# Calculating variable importance 
importance <- as.data.frame(caret::varImp(lin_model, scale = TRUE))

# Removing punctuation characters from field names
row.names(importance) <- gsub("[[:punct:][:blank:]]+", "", row.names(importance))

# Plotting the % importance ordered from lowest to highest
barplot(t(importance[order(importance$Overall), ,drop=FALSE]))

# Hyper-parameter Tuning Linear Regression using Ridge regularization

# Feature Scaling
X_train_scaled <- scale(X_train[, -1])  # Exclude the response variable
X_test_scaled <- scale(X_test[, -1], center = attr(X_train_scaled, "scaled:center"), scale = attr(X_train_scaled, "scaled:scale"))

# Converting the response variable to numeric
y_train_numeric <- as.numeric(y_train)

# Providing an Extended Lambda Grid
grid <- 10^seq(-1, 1, length = 1000)

# Fitting Ridge Regression model with cross-validation
set.seed(123)  # For reproducibility
cv_ridge <- cv.glmnet(X_train_scaled, y_train_numeric, alpha = 0, lambda = grid, nfolds = 10)  #Specifying folds for increased optimization

# Finding the optimal lambda
best_lambda <- cv_ridge$lambda.min

# Fitting the final model and make predictions
final_ridge_model <- glmnet(X_train_scaled, y_train_numeric, alpha = 0, lambda = best_lambda)
y_pred_ridge <- predict(final_ridge_model, newx = X_test_scaled)

# Evaluating the model (RMSE, MAE, R-squared)
rmse_ridge <- sqrt(mean((y_pred_ridge - y_test)^2))
mae_ridge <- mean(abs(y_pred_ridge - y_test))
rsquared_ridge <- 1 - sum((y_test - y_pred_ridge)^2) / sum((y_test - mean(y_test))^2)

#Printing the evaluation metrics
cat("Ridge Regression","\n")
cat("Root Mean Squared Error (RMSE) after tuning : ", rmse_ridge, "\n")
cat("Mean Absolute Error (MAE) after tuning : ", mae_ridge, "\n")
cat("R-squared after tuning:", rsquared_ridge, "\n")

# Plotting scatter plot
plot_data_ridge <- data.frame(Actual = y_test, Predicted = as.vector(y_pred_ridge))
ggplot(plot_data_ridge, aes(x = Actual, y = Predicted)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(x = "Actual", y = "Predicted", title = "Ridge Regression Predictions") +
  theme_minimal()

#***************************************************************************************************

# Model 7
# Building Gradient Boosting Regression model
install.packages("gbm")
library("gbm")

# Convert the response variable to a numeric vector
y_train_numeric <- as.numeric(as.character(y_train))
y_test_numeric <- as.numeric(as.character(y_test))

gbm_model <- gbm(
  formula = y_train ~ .,  # Specify the target variable
  distribution = "gaussian",  # For regression
  data = X_train,
  n.trees = 500,  # Initial number of trees
  interaction.depth = 3,  # Tree depth
  shrinkage = 0.1,  # Learning rate
)

# Make predictions on the train and test set using the best iteration
y_train_pred_gbm <- predict(gbm_model, newdata = X_train, type = "response")
y_test_pred_gbm <- predict(gbm_model, newdata = X_test, type = "response")

# Calculate evaluation metrics 
# Root Mean Squared Error (RMSE)
train_rmse_gbm <- sqrt(mean((y_train_pred_gbm - y_train)^2))
cat("Gradient Boosting Regression - Train Root Mean Squared Error (RMSE):", train_rmse_gbm, "\n")
test_rmse_gbm <- sqrt(mean((y_test_pred_gbm - y_test)^2))
cat("Gradient Boosting Regression - Root Mean Squared Error (RMSE):", test_rmse_gbm, "\n")


# Mean Squared Error (MSE)
train_mse_gbm <- mean((y_train_pred_gbm - y_train)^2)
cat("Gradient Boosting Regression - Train Mean Squared Error (MSE):", train_mse_gbm, "\n")
test_mse_gbm <- mean((y_test_pred_gbm - y_test)^2)
cat("Gradient Boosting Regression - Mean Squared Error (MSE):", test_mse_gbm, "\n")


# R-squared (R2)
train_rsquared_gbm <- 1 - sum((y_train - y_train_pred_gbm)^2) / sum((y_train - mean(y_train))^2)
cat("Gradient Boosting Regression - Train R-squared (R2):", train_rsquared_gbm, "\n")
test_rsquared_gbm <- 1 - sum((y_test - y_test_pred_gbm)^2) / sum((y_test - mean(y_test))^2)
cat("Gradient Boosting Regression - R-squared (R2):", test_rsquared_gbm, "\n")

# Create a data frame for plotting
plot_data_gbm <- data.frame(
  Actual = y_test,
  Predicted = y_test_pred_gbm
)

# Scatter plot
ggplot(plot_data_gbm, aes(x = Actual, y = Predicted)) +
  geom_point() +
  labs(x = "Actual", y = "Predicted", title = "Actual test data vs Gradient Boosting Regression predictions") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

# Calculate variable importance
importance_gbm <- gbm::relative.influence(gbm_model)

# Prepare data for ggplot2
importance_df <- data.frame(
  Variable = names(importance_gbm),
  Importance = importance_gbm
)

# Plotting bar graph for Variable importance
ggplot(importance_df, aes(x = Importance, y = reorder(Variable, Importance))) +
  geom_bar(stat = "identity", fill = "skyblue") +
  coord_flip() +  # Flip axes for better readability
  labs(title = "Variable Importance (Gradient Boosting Regression)",
       x = "Variable",
       y = "Relative Influence") +
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 90))  # Rotate x-axis labels


# Hyperparameter Tuning Gradient Boosting Regression model
# Convert the response variable to a numeric vector
y_train_numeric <- as.numeric(as.character(y_train))
y_test_numeric <- as.numeric(as.character(y_test))

# Define the hyperparameter grid
grid <- expand.grid(
  n.trees = 500,
  interaction.depth = 7,
  shrinkage = 0.01,
  n.minobsinnode = 15
)

# Set up the control parameters for cross-validation
ctrl <- trainControl(
  method = "cv",
  number = 5,
  verboseIter = TRUE
)

# Train the model using train function for hyperparameter tuning
gbm_tuned <- caret::train(
  x = X_train,
  y = y_train_numeric,
  method = "gbm",
  trControl = ctrl,
  tuneGrid = grid
)

# Get the best model
best_model <- gbm_tuned$finalModel

# Make predictions on the test set
y_train_pred_gbm_tuned <- predict(best_model, newdata = X_train, n.trees = best_model$n.trees)
y_test_pred_gbm_tuned <- predict(best_model, newdata = X_test, n.trees = best_model$n.trees)

# Calculate evaluation metrics
# Root Mean Squared Error (RMSE)
train_rmse_gbm_tuned <- sqrt(mean((y_train_pred_gbm_tuned - y_train_numeric)^2))
cat("Tuned Gradient Boosting Model - Train Root Mean Squared Error (RMSE):", train_rmse_gbm_tuned, "\n")
test_rmse_gbm_tuned <- sqrt(mean((y_test_pred_gbm_tuned - y_test_numeric)^2))
cat("Tuned Gradient Boosting Model - Root Mean Squared Error (RMSE):", test_rmse_gbm_tuned, "\n")

# Mean Squared Error (MSE)
train_mse_gbm_tuned <- mean((y_train_pred_gbm_tuned - y_train_numeric)^2)
cat("Tuned Gradient Boosting Model - Train Mean Squared Error (MSE):", train_mse_gbm_tuned, "\n")
test_mse_gbm_tuned <- mean((y_test_pred_gbm_tuned - y_test_numeric)^2)
cat("Tuned Gradient Boosting Model - Mean Squared Error (MSE):", test_mse_gbm_tuned, "\n")

# R-squared (R2)
train_rsquared_gbm_tuned <- 1 - sum((y_train_numeric - y_train_pred_gbm_tuned)^2) / sum((y_train_numeric - mean(y_train_numeric))^2)
cat("Tuned Gradient Boosting Model - Train R-squared (R2):", train_rsquared_gbm_tuned, "\n")
test_rsquared_gbm_tuned <- 1 - sum((y_test_numeric - y_test_pred_gbm_tuned)^2) / sum((y_test_numeric - mean(y_test_numeric))^2)
cat("Tuned Gradient Boosting Model - R-squared (R2):", test_rsquared_gbm_tuned, "\n")

# Create a data frame for plotting
plot_data_gbm_tuned <- data.frame(
  Actual = y_test_numeric,
  Predicted = y_test_pred_gbm_tuned
)

# Scatter plot for the tuned model
ggplot(plot_data_gbm_tuned, aes(x = Actual, y = Predicted)) +
  geom_point() +
  labs(x = "Actual", y = "Predicted", title = "Actual test data vs Tuned Gradient Boosting Model predictions") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

#***************************************************************************************************

#Model 8
# Building Linear Regression model
install.packages("glmnet")
library("glmnet")

lm_model <- lm(y_train ~ ., data = X_train)

# Make predictions on the training set
y_train_pred_lm <- predict(lm_model, newdata = X_train)

# Make predictions on the test set
y_test_pred_lm <- predict(lm_model, newdata = X_test)

# Calculate evaluation metrics 
# Root Mean Squared Error (RMSE)
train_rmse_lm <- sqrt(mean((y_train_pred_lm - y_train)^2))
cat("Linear Regression - Train Root Mean Squared Error (RMSE):", train_rmse_lm, "\n")
test_rmse_lm <- sqrt(mean((y_test_pred_lm - y_test)^2))
cat("Linear Regression - Test Root Mean Squared Error (RMSE):", test_rmse_lm, "\n")

# Mean Squared Error (MSE)
train_mse_lm <- mean((y_train_pred_lm - y_train)^2)
cat("Linear Regression - Train Mean Squared Error (MSE):", train_mse_lm, "\n")
test_mse_lm <- mean((y_test_pred_lm - y_test)^2)
cat("Linear Regression - Test Mean Squared Error (MSE):", test_mse_lm, "\n")

# R-squared (R2)
train_rsquared_lm <- 1 - sum((y_train - y_train_pred_lm)^2) / sum((y_train - mean(y_train))^2)
cat("Linear Regression - Train R-squared (R2):", train_rsquared_lm, "\n") 
test_rsquared_lm <- 1 - sum((y_test - y_test_pred_lm)^2) / sum((y_test - mean(y_test))^2)
cat("Linear Regression - Test R-squared (R2):", test_rsquared_lm, "\n")

# Create a data frame for plotting
plot_data_lm <- data.frame(
  Actual = y_test,
  Predicted = y_test_pred_lm
)

# Scatter plot with a linear regression line
ggplot(plot_data_lm, aes(x = Actual, y = Predicted)) +
  geom_point() +
  labs(x = "Actual", y = "Predicted", title = "Actual test data vs Linear Regression predictions") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

# Calculate variable importance 
importance_lm <- caret::varImp(lm_model, scale = FALSE)

# Prepare data for ggplot2
importance_df <- data.frame(
  Variable = rownames(importance_lm),
  Importance = importance_lm$Overall
)

# Plotting bar graph for Variable importance
ggplot(importance_df, aes(x = Importance, y = reorder(Variable, Importance))) +
  geom_bar(stat = "identity", fill = "skyblue") +
  coord_flip() +  # Flip axes for better readability
  labs(title = "Variable Importance (Linear Regression)",
       x = "Variable",
       y = "Importance") +
  theme_minimal()+
  theme(axis.text.x = element_text(angle = 90))  # Rotate x-axis labels

# Hyperparameter Tuning Linear Regression using Lasso regularization
# Convert data to matrix format (required by glmnet)
X_train_matrix <- as.matrix(X_train[, -1])  # Exclude the response variable
y_train_numeric <- as.numeric(y_train)
X_test_matrix <- as.matrix(X_test[, -1])

# Set up a grid of lambda values for tuning
lambdas <- 10^seq(-2, 5, length = 100)

# Fit Lasso Regression model with cross-validation
cv_lasso <- cv.glmnet(X_train_matrix, y_train_numeric, alpha = 1, lambda = lambdas, nfolds = 5)

# Find the optimal lambda
best_lambda <- cv_lasso$lambda.min

# Fit the final Lasso model and make predictions on the training set
final_lasso_model <- glmnet(X_train_matrix, y_train_numeric, alpha = 1, lambda = best_lambda)
y_train_pred_lasso <- predict(final_lasso_model, newx = X_train_matrix)

# Make predictions on the test set
y_test_pred_lasso <- predict(final_lasso_model, newx = X_test_matrix)

# Calculate evaluation metrics 
# Root Mean Squared Error (RMSE) 
train_rmse_lasso <- sqrt(mean((y_train_pred_lasso - y_train)^2))
cat("Tuned Linear Regression (Lasso) - Train Root Mean Squared Error (RMSE):", train_rmse_lasso, "\n")
test_rmse_lasso <- sqrt(mean((y_test_pred_lasso - y_test)^2))
cat("Tuned Linear Regression (Lasso) - Test Root Mean Squared Error (RMSE):", test_rmse_lasso, "\n")

# Mean Squared Error (MSE) 
train_mse_lasso <- mean((y_train_pred_lasso - y_train)^2)
cat("Tuned Linear Regression (Lasso) - Train Mean Squared Error (MSE):", train_mse_lasso, "\n")
test_mse_lasso <- mean((y_test_pred_lasso - y_test)^2)
cat("Tuned Linear Regression (Lasso) - Test Mean Squared Error (MSE):", test_mse_lasso, "\n")

# R-squared (R2) 
train_rsquared_lasso <- 1 - sum((y_train - y_train_pred_lasso)^2) / sum((y_train - mean(y_train))^2)
cat("Tuned Linear Regression (Lasso) - Train R-squared (R2):", train_rsquared_lasso, "\n")
test_rsquared_lasso <- 1 - sum((y_test - y_test_pred_lasso)^2) / sum((y_test - mean(y_test))^2)
cat("Tuned Linear Regression (Lasso) - Test R-squared (R2):", test_rsquared_lasso, "\n")

# Create a data frame for plotting
plot_data <- data.frame(
  Actual = y_test,
  Predicted = as.vector(y_test_pred_lasso)
)

# Scatter plot with a line of best fit
ggplot(plot_data, aes(x = Actual, y = Predicted )) +
  geom_point() +
  labs(x = "Actual", y = "Predicted", title = "Actual test data vs. Tuned Linear Regression (Lasso) Predictions ") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  theme_minimal()

#***************************************************************************************************

#Model 9
# Random Forest
install.packages("randomForest")
library(randomForest)

# Ensure that pos is a numeric value
y_train <- as.numeric(as.character(y_train))
y_test <- as.numeric(as.character(y_test))

# Training random forest model
rf_model <- randomForest(x = X_train, y = y_train, ntree = 100)

print(rf_model)

# Feature importance diagram
importance <- importance(rf_model)
feature_importance <- data.frame(Feature = rownames(importance), Importance = importance[, 'IncNodePurity'])

ggplot(feature_importance, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_bar(stat = 'identity') +
  theme_minimal() +
  coord_flip() +  
  xlab('Feature') +
  ylab('Importance') +
  ggtitle('Feature Importance in Random Forest Model')

# Check the generalization effect of test set

# Use test sets to make predictions.
test_predictions_rf <- predict(rf_model, newdata = X_test)

# Calculate performance metrics: RMSE/MAE/R2
rf_rmse <- sqrt(mean((test_predictions_rf - y_test)^2))
rf_mae <- mean(abs(test_predictions_rf - y_test))
r_squared <- function(actual, predicted) {
  tss <- sum((actual - mean(actual))^2)
  rss <- sum((actual - predicted)^2)
  r_squared <- 1 - (rss / tss)
  return(r_squared)
}
rf_r2 <- r_squared(y_test, test_predictions_rf)

print(paste("RF RMSE:", rf_rmse))
print(paste("RF MAE:", rf_mae))
print(paste("RF R2:", rf_r2))

# Scatter plot
plot_data_rf <- data.frame(Actual = y_test, Predicted = test_predictions_rf)
ggplot(plot_data_rf, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed", linewidth = 1.5) +
  theme_minimal() +
  xlab("Actual Value") +
  ylab("Predicted Value") +
  ggtitle("Scatter Plot of Actual vs. Predicted Values (Random Forest)")

#***************************************************************************************************

#Model 10
# XGBoost
install.packages("xgboost")
library(xgboost)

# Prepare training and test data
dtrain <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)
dtest <- xgb.DMatrix(data = as.matrix(X_test))

# Set XGBoost parameters. 
params <- list(
  booster = "gbtree",
  objective = "reg:squarederror",
  eta = 0.1,
  max_depth = 6,
  subsample = 0.7,
  colsample_bytree = 0.7
)

# Training model
xgb_model <- xgb.train(params = params, data = dtrain, nrounds = 100)

print(xgb_model)

### Check the generalization effect of test set

# Make a prediction on the test set
test_predictions_xgb <- predict(xgb_model, newdata = dtest)

# Calculate performance metrics
xgb_rmse <- sqrt(mean((test_predictions_xgb - y_test)^2))
xgb_mae <- mean(abs(test_predictions_xgb - y_test))
r_squared <- function(actual, predicted) {
  tss <- sum((actual - mean(actual))^2)
  rss <- sum((actual - predicted)^2)
  r_squared <- 1 - (rss / tss)
  return(r_squared)
}
xgb_r2 <- r_squared(y_test, test_predictions_xgb)

print(paste("XGB RMSE:", xgb_rmse))
print(paste("XGB MAE:", xgb_mae))
print(paste("XGB R2:", xgb_r2))

# Scatter plot
plot_data_xgb <- data.frame(Actual = y_test, Predicted = test_predictions_xgb)
ggplot(plot_data_xgb, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed", linewidth = 1.5) +
  theme_minimal() +
  xlab("Actual Value") +
  ylab("Predicted Value") +
  ggtitle("Scatter Plot of Actual vs. Predicted Values (XGBoost)")

#***************************************************************************************************




