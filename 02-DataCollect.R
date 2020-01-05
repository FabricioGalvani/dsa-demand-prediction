# ---
# script: 02-DataCollect
# subject: Looking for data
# date: 2019-07-30
# author: Marcus Di Paula
# github: github.com/marcusdipaula/
# linkedin: linkedin.com/in/marcusdipaula/
# ---



# 2. Looking for data:
#     - Identify entities (and its attributes) of the problem
#         See more at: https://www.teach-ict.com/as_a2_ict_new/ocr/AS_G061/315_database_concepts/attributes_entities/miniweb/pg3.htm
#
#     - Collect data that represents entities
#         Data: https://www.kaggle.com/c/grupo-bimbo-inventory-demand/data
#
#     - Which hypotheses could I suppose? I can think of these right now:
#         1-Fitting predictive models to distinct groups of clients or products may be more accurate than to all
#           clients or products as one single group.
#         2-New products may have more return than old ones.
#         3-The regions with higher returns of products may be the ones with the higher variety of products.
#
#     - Explore the data (superficially) to understand it
#
#     - Could I use an algorithm to address the issue or solve it? Which one?
#         Since its about a numeric forecast, I should use regression algorithms. I'd like to try an ensemble
#         learning approach to handle this task.
#         "Ensemble learning is a machine learning paradigm where multiple learners are trained to solve the same problem"
#         More at: https://cs.nju.edu.cn/zhouzh/zhouzh.files/publication/springerEBR09.pdf



# Data Description
#
# The dataset you are given consists of 9 weeks of sales transactions in Mexico. Every week, there
# are delivery trucks that deliver products to the vendors. Each transaction consists of sales and returns.
# Returns are the products that are unsold and expired. The demand for a product in a certain week is
# defined as the sales of this week subtracted by the return next week. The train and test datasets are split
# based on time.


# Things to note:
#
# - There may be products in the test set that don't exist in the train set. This is the expected behavior
#   of inventory data, since there are new products being sold all the time. Your model should be able to
#   accommodate this.
#
# - There are duplicate Cliente_ID's in cliente_tabla, which means one Cliente_ID may have multiple NombreCliente
#   that are very similar. This is due to the NombreCliente being noisy and not standardized in the raw data, so
#   it is up to you to decide how to clean up and use this information.
#
# - The adjusted demand (Demanda_uni_equil) is always >= 0 since demand should be either 0 or a positive value.
#   The reason that Venta_uni_hoy - Dev_uni_proxima sometimes has negative values is that the returns records
#   sometimes carry (delay?) over a few weeks.


# File descriptions
# |_ train.csv — the training set
# |_ test.csv — the test set
# |_ sample_submission.csv — a sample submission file in the correct format
# |_ cliente_tabla.csv — client names (can be joined with train/test on Cliente_ID)
# |_ producto_tabla.csv — product names (can be joined with train/test on Producto_ID)
# |_ town_state.csv — town and state (can be joined with train/test on Agencia_ID)

# Data fields
# |_ Semana — Week number (From Thursday to Wednesday)
# |_ Agencia_ID — Sales Storehouse ID
# |_ Canal_ID — Sales Channel ID
# |_ Ruta_SAK — Route ID (Several routes = Sales Storehouse)
# |_ Cliente_ID — Client ID
# |_ NombreCliente — Client name
# |_ Producto_ID — Product ID
# |_ NombreProducto — Product Name
# |_ Venta_uni_hoy — Sales unit this week (integer)
# |_ Venta_hoy — Sales this week (unit: pesos)
# |_ Dev_uni_proxima — Returns unit next week (integer)
# |_ Dev_proxima — Returns next week (unit: pesos)
# |_ Demanda_uni_equil — Adjusted Demand (integer) (This is the target you will predict)



# Loading the tidyverse packages (and installing them before, if not installed)
# More about it on: https://www.tidyverse.org/
if(!require(tidyverse)) { install.packages("tidyverse"); library(tidyverse) }
# if(!require(data.table)) { install.packages("data.table"); library(data.table) }

#___________________________________________________________________________________________________#
#                                                                                                   #
#                                                                                                   #
# REMEMBER: set the working directory and download there all the necessary data from:               #
# https://www.kaggle.com/c/grupo-bimbo-inventory-demand/data                                        #
#                                                                                                   #
#                                                                                                   #
#___________________________________________________________________________________________________#


# Loading the train dataset
dataset <- read_csv("train.csv",
                    col_types = cols(.default = "d"))


# dataset <- fread("train.csv", select = c("Demanda_uni_equil", 
#                                          "Semana" ,
#                                          "Agencia_ID" ,
#                                          "Canal_ID" ,
#                                          "Ruta_SAK" ,
#                                          "Cliente_ID" ,
#                                          "Producto_ID"))

