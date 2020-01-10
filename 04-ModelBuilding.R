# ---
# script: 04-ModelBuilding
# subject: Model building
# date: 2020-01-05
# author: Marcus Di Paula
# github: github.com/marcusdipaula/
# linkedin: linkedin.com/in/marcusdipaula/
# ---



# 4. Building and validating models (orientated to the 5th phase)
#     - Train and test a ML model
#     - Which performance metrics should I rely on?
#     - Iteration




# variable to control exploration of models results
want_to_explore_models_results <- FALSE

# Loading caret package (and installint it before, if not installed)
# to work with regression tools
# More at: http://topepo.github.io/caret/
if(!require(caret)) {install.packages("caret"); library(caret)}

# Loading recipes package (and installint it before, if not installed)
# The recipes package is an alternative method for creating and preprocessing design matrices
# More at: https://tidymodels.github.io/recipes/
# http://topepo.github.io/caret/using-recipes-with-train.html
if(!require(recipes)) {install.packages("recipes"); library(recipes)}



#_______________________________________ Data split ______________________________________#

# Creating a random index to serve as reference to split the dataset into training and testing sets
index <- createDataPartition(y = small_sample$Demanda_uni_equil,
                             p = 0.01,
                             list = F); smaller_sample <- small_sample[index,]; rm(small_sample)

index <- createDataPartition(y = smaller_sample$Demanda_uni_equil,
                             p = 0.7,
                             list = F)

# Creating the training and testing sets
train <- smaller_sample[-index,]
test <- smaller_sample[index,]

str(train)


#_______________________________________ Pre-processing recipe ______________________________________#

# Creating a pre-processing recipe 
# More at: http://topepo.github.io/caret/using-recipes-with-train.html
# I'll use just the variables that are on the test dataset
# More at: https://www.kaggle.com/c/grupo-bimbo-inventory-demand/data
pre_proc_recipe <- recipe(Demanda_uni_equil ~ 
                            Semana +
                            Agencia_ID +
                            Canal_ID +
                            Ruta_SAK +
                            Cliente_ID +
                            Producto_ID, 
                          data = train) %>% step_normalize(all_predictors())



#_______________________________________ Train_Control ______________________________________#

# Setting up control parameters for training the models
# More at: http://topepo.github.io/caret/model-training-and-tuning.html#basic-parameter-tuning
# http://topepo.github.io/caret/model-training-and-tuning.html#the-traincontrol-function
# https://www.rdocumentation.org/packages/caret/versions/6.0-84/topics/trainControl

train_control <- trainControl(method = "repeatedcv", # the resampling method, repeated k-fold cross-validation.
                              # Repeated k-fold cross validation is preferred when you can afford the computational
                              # expense and require a less biased estimate.
                              
                              number = 3, # the number of folds in K-fold cross-validation, so we have 3-fold
                              # cross-validations
                              
                              repeats = 3, # repetitions of the previous k-fold cross-validation, so we have
                              # 3 repetitions of 3-fold cross-validations
                              # An illustration: https://www.evernote.com/l/AGKmXIbis1dHSbR_j9dblVk-t3klmWsL_i0/
                              
                              returnData = F, # a logical for saving the data into a slot called trainingData
                              
                              search = "random", # a random sample of possible tuning parameter combinations
                              # More at: http://topepo.github.io/caret/random-hyperparameter-search.html
                              
                              )

# trainControl function has an "allowParallel" parameter, you can see more at:
# http://topepo.github.io/caret/parallel-processing.html
#
# To know more about parallel processing (on Windows and Unix like systems):
# http://dept.stat.lsa.umich.edu/~jerrick/courses/stat701/notes/parallel.html


#_______________________________________ Algorithm_01 ______________________________________#


# eXtreme Gradient Boosting
#
# Caret method: 'xgbLinear'
#
# Type: Regression, Classification
#
# Tags (types or relevant characteristics according to the caret package guide):
# Boosting, Ensemble Model, Implicit Feature Selection, Supports Class Probabilities
#
# Tuning parameters: nrounds (# Boosting Iterations), 
#                    lambda (L2 Regularization), 
#                    alpha (L1 Regularization), 
#                    eta (Learning Rate)
#
# Required packages: xgboost
#
# More info: A model-specific variable importance metric is available.
#
# Link to know more: http://topepo.github.io/caret/
# or
# xgbTree


model_xgbLinear <- train(pre_proc_recipe, # Recipes are a third method for specifying model terms but also allow 
                         # for a broad set of preprocessing options for encoding, manipulating, and transforming 
                         # data. They cover a lot of techniques that formulas cannot do naturally.
                         # More at: http://topepo.github.io/caret/using-recipes-with-train.html
                  
                         data = train, # the dataset to fit the model
                         
                         method = "xgbLinear", # the caret method for this algorithm
                         
                         trControl = train_control, # the control parameters setted above
                         
                         tuneLength = 5, # the total number of random unique combinations to tune parameters
                         # more at: http://topepo.github.io/caret/random-hyperparameter-search.html
                         
                         metric = "RMSE" # Root Mean Square Error (RMSE) is the standard deviation of the 
                         # residuals (prediction errors). RMSE will give a gross idea of how wrong all
                         # predictions are (0 is perfect), and Rsquared will give an idea of how well the
                         # model has fit the data (1 is perfect, 0 is worst)
                         )

# pryr::object_size(model_xgbLinear)

if(want_to_explore_models_results) {
  
  # Printing the model
  print(model_xgbLinear)
  
  # Looking at the final model
  print(model_xgbLinear$finalModel)
  
  # Ploting the tuning parameters (the randomly selected predictors by the metric used)
  plot(model_xgbLinear)
  
  # predictions
  score_xgbLinear <- tibble(historical = test$Demanda_uni_equil,
                            
                            forecast = predict.train(object = model_xgbLinear,
                                                     newdata = test,
                                                     type = "raw"))
  
  
  # adding a variable with the calc of residuals
  score_xgbLinear %<>% mutate(resids = historical - forecast) 
  
  # ploting the frequency of residuals
  score_xgbLinear %>% 
    ggplot(mapping = aes(x = resids)) +
    geom_histogram()
  
  # Quantile-Quantile Plots
  qqnorm(score_xgbLinear$resids)
  #qqline(score_xgbLinear$resids)
  
}

#Saving the model to use later
saveRDS(object = model_xgbLinear,
        file = "./models/model_xgbLinear.RDS")



#_______________________________________ Algorithm_02 ______________________________________#

# Auto ML with h2o package
# Mor info at:
# https://github.com/h2oai/h2o-tutorials/blob/master/h2o-world-2017/automl/R/automl_binary_classification_product_backorders.Rmd

# Loading the h2o package (and installing it, if not installed)
if(!require(h2o)) {install.packages("h2o"); library(h2o)}

# Initializing and connecting to a h2o instance
h2o.init(nthreads = -1, #Number of threads: -1 means use all cores on your machine
         max_mem_size = "6G")  #max mem size is the maximum memory to allocate to H2O

# Importing the dataset into a h2o cluster (creates a "H2OFrame" object)
df_h2o_cluster <- h2o.importFile("small_sample.csv")

# Looking at the description of the dataset
h2o.describe(df_h2o_cluster)

# Specifying the target variable (y) and the prediction ones (x)
y <- "Demanda_uni_equil"
x <- setdiff(names(df_h2o_cluster), c(y, "Demanda_uni_equil"))


# Training the model
auto_ml <- h2o.automl(y = y,
                      x = x,
                      training_frame = df_h2o_cluster,
                      max_models = 10) # this specifies the max number of models
      # does not include the two "ensemble models" that are trained at the end

# Printing the top models
print(auto_ml@leaderboard)

# The winner is the Gradient Boosting altorithm with id GLM_grid_1_AutoML_20200105_194217_model_1
# with a RMSE of 4.462385. RMSE give a gross idea of how wrong all predictions are (0 is perfect).
# The Algorithm_01 had a RMSE of 20.01098, so this one performed better.

# Saving the leader model in a binary format
h2o.saveModel(auto_ml@leader, path = "./models/auto_ml/")









