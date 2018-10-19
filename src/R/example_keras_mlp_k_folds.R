#https://blogs.rstudio.com/tensorflow/posts/2018-01-11-keras-customer-churn/
# Download data:
# https://community.watsonanalytics.com/wp-content/uploads/2015/03/WA_Fn-UseC_-Telco-Customer-Churn.xlsx


# Load libraries
library(keras)
library(lime)
library(tidyquant)
library(rsample)
library(recipes)
library(yardstick)
library(corrr)

churn_data_raw <- read_csv("WA_Fn-UseC_-Telco-Customer-Churn.csv")
glimpse(churn_data_raw)

# Remove unnecessary data
churn_data_tbl <- churn_data_raw %>%
  select(-customerID) %>%
  drop_na() %>%
  select(Churn, everything())

glimpse(churn_data_tbl)

# Split test/training sets
set.seed(100)
train_test_split <- initial_split(churn_data_tbl, prop = 0.8)
train_test_split

# Retrieve train and test sets
train_tbl <- training(train_test_split)
test_tbl  <- testing(train_test_split) 

k <- 8
indices <- sample(1:nrow(train_tbl))
folds <- cut(1:length(indices), breaks = k, labels = FALSE) 

# Because we will need to instantiate the same model multiple times,
# we use a function to construct it.
build_model <- function() {
  keras_model_sequential()

model_keras %>% 
  
  # First hidden layer
  layer_dense(
    units              = 16, 
    kernel_initializer = "uniform", 
    activation         = "relu", 
    input_shape        = dim(train_data)[[2]]) %>% 
  
  # Dropout to prevent overfitting
  layer_dropout(rate = 0.1) %>%
  
  # Second hidden layer
  layer_dense(
    units              = 16, 
    kernel_initializer = "uniform", 
    activation         = "relu") %>% 
  
  # Dropout to prevent overfitting
  layer_dropout(rate = 0.1) %>%
  
  # Output layer
  layer_dense(
    units              = 1, 
    kernel_initializer = "uniform", 
    activation         = "sigmoid") %>% 
  
  # Compile ANN
  compile(
    optimizer = 'adam',
    loss      = 'binary_crossentropy',
    metrics   = c('accuracy', 'mae')
  )
}

num_epochs <- 50
all_mae_histories <- NULL
all_acc_histories <- NULL

for (i in 1:k) {
  cat("processing fold #", i, "\n")
  
  # Prepare the validation data: data from partition # k
  val_indices <- which(folds == i, arr.ind = TRUE)
  val_data <- train_tbl[val_indices,]
  partial_train_data <- train_tbl[-val_indices,]
  
  # Create recipe
  rec_obj <- recipe(Churn ~ ., data = partial_train_data) %>%
    step_discretize(tenure, options = list(cuts = 6)) %>%
    step_log(TotalCharges) %>%
    step_dummy(all_nominal(), -all_outcomes()) %>%
    step_center(all_predictors(), -all_outcomes()) %>%
    step_scale(all_predictors(), -all_outcomes()) %>%
    prep(data = partial_train_data)
  
  # Predictors
  partial_train_targets <- ifelse(pull(partial_train_data, Churn) == "Yes", 1, 0)
  partial_train_data <- bake(rec_obj, newdata = partial_train_data) %>% select(-Churn)
  
  val_targets  <- ifelse(pull(val_data, Churn) == "Yes", 1, 0)
  val_data  <- bake(rec_obj, newdata = val_data) %>% select(-Churn)

  # Build the Keras model (already compiled)
  model <- build_model()

  # Fit the keras model to the training data
  history <- model %>%
    fit(x = as.matrix(partial_train_data), 
        y = partial_train_targets,
        batch_size = 50, 
        epochs = num_epochs,
        validation_data = list(as.matrix(val_data), val_targets))
  mae_history <- history$metrics$val_mean_absolute_error
  acc_history <- history$metrics$acc
  
  all_mae_histories <- rbind(all_mae_histories, mae_history)
  all_acc_histories <- rbind(all_acc_histories, acc_history)
}

average_mae_history <- data.frame(
  epoch = seq(1:ncol(all_mae_histories)),
  validation_mae = apply(all_mae_histories, 2, mean)
)
ggplot(average_mae_history, aes(x = epoch, y = validation_mae)) + geom_line()

all_acc_histories <- data.frame(
  epoch = seq(1:ncol(all_acc_histories)),
  validation_acc = apply(all_acc_histories, 2, mean)
)
ggplot(all_acc_histories, aes(x = epoch, y = validation_acc)) + geom_line()

