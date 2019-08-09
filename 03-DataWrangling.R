# ---
# script: 03-DataWrangling
# subject: Exploring and Feature Engineering
# date: 2019-08-03
# author: Marcus Di Paula
# github: github.com/marcusdipaula/
# linkedin: linkedin.com/in/marcusdipaula/
# ---



# 3. Data preparation and Exploration (Feature Engineering oriented to the 4th phase)
#     - Is my dataset tidy?
#     - Is my dataset clean?
#     - Which correlations exists between all variables and to the target?
#     - There is any NA in my dataset? If so, how should I treat them? Which effects would it have?
#     - Should I narrowing in on observations of interest? Which effects would it have?
#     - Should I reduce my variables? Which effects would it have?
#     - Should I create new variables that are functions of existing ones? Which effects would it have?
#     - Should I binning variables? Which effects would it have?
#     - should I convert variables (categorical to numerical / vv)? Which effects would it have?
#     - Should I dummy coding categorical variables? Which effects would it have?
#     - Should I standardize numerical variables? Which effects would it have?
#     - Can I test my hypotheses?



# Loading the magrittr package (and installing it before, if not installed)
# for piping: %>%, %$% and %<>%. More at: https://magrittr.tidyverse.org/
if(!require(magrittr)) { install.packages("magrittr"); library(magrittr) }

# Loading the svglite package (and installing it before, if not installed)
# to plot SVG files. More at: https://en.wikipedia.org/wiki/Scalable_Vector_Graphics
if(!require(svglite)) { install.packages("svglite"); library(svglite) }

# Loading the GGally package (and installing it before, if not installed)
# to plot correlation heat maps and others extensions of ggplot2. 
# More at: http://ggobi.github.io/ggally/#ggally
if(!require(GGally)) { install.packages("GGally"); library(GGally) }

# Dataset structure
str(dataset)

# Numer of rows
nrow(dataset) # 74180464

# There is any NA?
any(is.na(dataset))
# VIM::aggr(dataset) # another way to see missing values (but you have to have memory)


#________________________________ Getting a smaller sample ________________________________#

# Getting a smaller sample to explore and removing the train dataset
# https://www.statisticssolutions.com/what-is-a-representative-sample/
small_sample <- sample_frac(tbl = dataset,
                            size = 0.3); rm(dataset)

# saving the small_sample object
# write_csv(x = small_sample,
#           path = "Data/small_sample.csv")

# small_sample <- read_csv("small_sample.csv",
#                          col_types = cols(.default = "d"))

#_________________________________ Exploring _________________________________#


# Structure
str(small_sample)

# Summary
summary(small_sample)

# the numbers of weeks
small_sample %>% distinct(Semana)

# Units sold by sales channels
# More about unit sales: https://www.investopedia.com/terms/u/unitsales.asp
small_sample %>%
  group_by(Canal_ID) %>%
  summarise(units_sold = sum(Venta_uni_hoy)) %>% 
  ggplot(mapping = aes(x = Canal_ID,
                       y = units_sold)) +
  geom_line(stat = "identity")

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_line_units_sold_Canal_ID.svg", 
       plot = last_plot(), 
       width = 11.25, # This have to be in inches, not in pixels, so for each pixel 
                      # we have approximately 0.01041667 inches
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_line_units_sold_Canal_ID.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")



# weight sold by sales channels
small_sample %>%
  group_by(Canal_ID) %>%
  summarise(weight_sold = sum(Venta_hoy)) %>% 
  ggplot(mapping = aes(x = Canal_ID,
                       y = weight_sold)) +
  geom_line(stat = "identity")

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_line_weight_sold_Canal_ID.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_line_weight_sold_Canal_ID.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


# Creating an object (dataset) with the best selling products
best_selling  <- small_sample %>%
                    select(Producto_ID, Venta_uni_hoy) %>%
                    group_by(Producto_ID) %>%
                    summarise(Sold_units = sum(Venta_uni_hoy)) %>%
                    arrange(desc(Sold_units)) 


# loading the products names
producto <- read_csv("producto_tabla.csv")

# Verifying if there is any na
any(is.na(best_selling))
any(is.na(producto))


# Joing tibbles together
# this left_join return all rows from x, and all columns from x and y 
# Rows in x with no match in y will have NA values in the new columns
left_join(x = best_selling,
          y = producto,
          by = "Producto_ID")

# let me try to return just the x that is found in y
inner_join(x = best_selling,
           y = producto,
           by = "Producto_ID")


# Ploting the top 10 sold products
inner_join(x = best_selling,
           y = producto,
           by = "Producto_ID") %>% 
    top_n(n = 10, 
          wt = Sold_units) %>% 
    ggplot(mapping = aes(y = Sold_units,
                         x = reorder(NombreProducto, Sold_units),
                         fill = -Sold_units) ) +
    # To plot the relationship between a continuous variable and a discrete variable,
    # you need to specify stat=”identity” when calling the geom_bar
    # This is the statistical transformation to use on the data for this layer
    geom_bar(stat = "identity") + 
    
    coord_flip() +
    
    labs(x = "",
         y = "Units sold",
         fill = "Color\nLegend",
         title = " Top 10 products sold") 
    

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_bar_Top_10_products_sold.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_bar_Top_10_products_sold.png", 
       plot = last_plot(), 
       width = 11.5, 
       height = 7.5,
       units = "in")

# Which sales channel has the higher negative return?
small_sample %>% 
  select(Venta_uni_hoy, Dev_uni_proxima, Canal_ID) %>% 
  mutate(negative_return = Venta_uni_hoy - Dev_uni_proxima) %>% 
  filter(negative_return < 0) %>% 
  group_by(Canal_ID) %>% 
  summarise(Venta_uni_hoy = sum(Venta_uni_hoy),
            Dev_uni_proxima = sum(Dev_uni_proxima),
            negative_return = sum(negative_return)) %>% 
  arrange(negative_return)

# How many units were sold on each sales channel?
small_sample %>% 
  select(Canal_ID, Venta_uni_hoy, Dev_uni_proxima) %>% 
  group_by(Canal_ID) %>% 
  summarise(units_sold = sum(Venta_uni_hoy)-sum(Dev_uni_proxima))

# Interesting. We can see that the sales channel 9 have the smallest quantity of units sold, 
# but none negative return. The sales channel 1 have the higher quantity of units sold, and
# the higher number of negative returns.
# The sales channel 2 and 4 are, respectively, the second and third places on quantity of units
# sold, but have a realy small quantity of negative returns. What can we learn from these two
# sales channels to replicate on the others? How can we sell more and have less returns?



# ploting a heat correlation map of the variables
# https://briatte.github.io/ggcorr/
ggcorr(small_sample,
       hjust = 0.75,
       label = TRUE,
       label_round = 3,
       layout.exp = 1)


# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/ggcorr.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/ggcorr.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")



#________________________________ Exploring Correlations ________________________________#

# Variables that showed strong correlation (from train.csv)

small_sample %$% cor(Canal_ID, Ruta_SAK)
small_sample %$% cor(Ruta_SAK, Producto_ID)
small_sample %$% cor(Venta_uni_hoy, Venta_hoy)
small_sample %$% cor(Venta_uni_hoy, Demanda_uni_equil)
small_sample %$% cor(Venta_hoy, Demanda_uni_equil)

# Canal_ID x Ruta_SAK = 0.47
# Ruta_SAK x Producto_ID = 0.29
# Venta_uni_hoy x Venta_hoy = 0.80
# Venta_uni_hoy x Demanda_uni_equil = 0.99
# Venta_hoy x Demanda_uni_equil = 0.80

# A positive linear correlation means that as the value of one variable increases, so
# does the value of the other variable. A negative linear correlation means the opposite, 
# so as the value of one variable increases, the value of the other decreases.



#________________________________ Correlation: Canal_ID x Ruta_SAK ________________________________#

# The sales channel (Canal_ID variable) have a positive linear correlation of 0.47
# with the route (Ruta_SAK variable). It means that the higher a route ID,
# the higher a sales channel ID (in a proportion of 0.47). What does it mean in practical terms?
#
# It seems reasonable to understand that the sales channels should be associated with
# specific routes. And when a different (unusual) route is associated with (or used by) 
# an unconventional sales channel, it may be expressing a logistical inefficiency.
#
# In this case, the higher the correlation, the better, the more efficient the logistic would be.
#
# But, this relation between a sales channel and some specific route could be expressed by 
# the pearson correlation? If so, we do have a logistical inefficiency that could be worked on.

# how many unique values do we have in Canal_ID ?
length(unique(small_sample$Canal_ID)) # 9 unique sales channels

# contingency table of Canal_ID
table(small_sample$Canal_ID) # channel of ID 1 is the mode, with the higher frequency

# how many unique values do we have in Ruta_SAK ?
length(unique(small_sample$Ruta_SAK)) # 3194 unique routes

# creating a matrix of plots
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Canal_ID, Ruta_SAK) %>% 
  ggpairs()

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/ggpairs_Canal_ID_Ruta_SAK.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/ggpairs_Canal_ID_Ruta_SAK.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


# Violin plot
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Canal_ID, Ruta_SAK) %>% 
  ggplot(mapping = aes(x = Canal_ID,
                       y = Ruta_SAK)) +
  geom_violin() # the routes with lower ID's have higher variations on sales channels

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_violin_Ruta_SAK_Canal_ID.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_violin_Ruta_SAK_Canal_ID.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")



# Plot of unique routes by salles channel
small_sample %>% 
  #sample_frac(size = 0.01) %>% 
  select(Canal_ID, Ruta_SAK) %>% 
  group_by(Canal_ID) %>% 
  summarise(unique_routes = n_distinct(Ruta_SAK)) %>% 
  arrange(desc(unique_routes)) %>% 
  ggplot(mapping = aes(x = reorder(Canal_ID, unique_routes),
                       y = unique_routes,
                       fill = -unique_routes)) +
  geom_bar(stat = "identity") +
  coord_flip() + 
  labs(x = "Sales channel ID",
       y = "Count of unique routes",
       fill = "Color\nLegend",
       title = " Unique routes by Sales Channel")


# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_bar_Unique_routes_by_Sales_channel.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_bar_Unique_routes_by_Sales_channel.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


# Creating objects grouped by salles channels to make comparisons
comp_a <- small_sample %>% 
          select(Canal_ID, Ruta_SAK) %>% 
          group_by(Canal_ID) %>% 
          summarise(unique_routes = n_distinct(Ruta_SAK))


comp_b <- small_sample %>%
          group_by(Canal_ID) %>%
          summarise(Sold_units = sum(Venta_uni_hoy))


comp_ab <- inner_join(x = comp_a,
           y = comp_b,
           by = "Canal_ID"); rm(comp_a, comp_b)

# Feature engineering on variables to allow comparison
comp_ab$Canal_ID %<>% as_factor()
comp_ab$unique_routes %<>% clusterSim::data.Normalization(type = "n1")
comp_ab$Sold_units %<>% clusterSim::data.Normalization(type = "n1")

# Plot of comparison between Units sold (line) and Unique Routes (bars) on each channel
comp_ab %>%   
  
    ggplot(mapping = aes(x = Canal_ID)) +

    geom_bar(mapping = aes(y = unique_routes^2),
             stat = "identity") +

    geom_line(mapping = aes(y = Sold_units^2, 
                            group = 1),
              stat = "identity",
              color = "blue",
              size = 0.7,
              alpha = 0.4) +
    
    geom_point(mapping = aes(y = Sold_units^2),
               stat = "identity") + 
    
    labs(x = "Sales channels ID",
         y = "Amount (standardized then squared)",
         title = " Units Sold (line) and Unique Routes (bars) on each sales channel")
  
# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_bar_line_point_Sell_Comparison.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_bar_line_point_Sell_Comparison.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")
  
  
  
#________________________________ Correlation: Ruta_SAK x Producto_ID ________________________________#

# The route (Ruta_SAK variable) has a positive linear correlation of 0.29 with the product
# (Producto_ID variable).
#
# It seems reasonable to understand that we have an association of some products with some
# routes. This relation can be understood as being of proportion 0.29 (for every 1 unit of 
# one variable we have 0.29 unit of the other).


# how many unique values do we have in Producto_ID ?
length(unique(small_sample$Producto_ID)) # 1685 unique products on this sample dataset

# how many unique values do we have in Ruta_SAK ?
# 3194 unique routes according to the previous calculations
# small_sample %>% select(Ruta_SAK) %>% distinct() %>% arrange(Ruta_SAK)

# Routes ordered by frequency
forcats::fct_count(as_factor(small_sample$Ruta_SAK)) %>% arrange(desc(n))

# creating a matrix of plots
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Producto_ID, Ruta_SAK) %>% 
  ggpairs() # I dont get much of it

# Saving the plot as a PNG 
ggsave(file = "Plots/ggpairs_Ruta_SAK_Producto_ID.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


# Getting a summary of products on each route
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Producto_ID, Ruta_SAK) %>% 
  group_by(Ruta_SAK) %>% 
  summarise(product_count = n()) %>% 
  summary

# frequency of routes
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Ruta_SAK) %>% 
  ggplot() + 
  geom_histogram(mapping = aes(x = Ruta_SAK), bins = 20)

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_histogram_Ruta_SAK.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_histogram_Ruta_SAK.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


#________________________________ Correlation: Venta_uni_hoy x Venta_hoy ________________________________#

# The units sold (Venta_uni_hoy variable) have a positive linear correlation of 0.80
# with the weight sold (Venta_hoy variable).
#
# This make sense, since we are talking about the same variable, the sold products, but just 
# in different units (units x weights).
#
# What could be the possible reason to differences in this relation?
# Reasons may include: 
#       different weights for each unit
#       


# creating a matrix of plots
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Venta_hoy, Venta_uni_hoy) %>% 
  ggpairs()

# Saving the plot as a PNG 
ggsave(file = "Plots/ggpairs_Venta_uni_hoy_Venta_hoy.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


# Let's see the sum of units sold and weight by sales channel
fraction <- small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Venta_hoy, Venta_uni_hoy, Canal_ID) %>% 
  group_by(Canal_ID) %>% 
  summarise(units_sold = sum(Venta_uni_hoy),
            weight_sold = sum(Venta_hoy)) %>% 
  arrange(Canal_ID) ; print(fraction)

# Feature engineering of Canal_ID variable on fraction dataset
fraction$Canal_ID %<>% as_factor()

# Ploting the units sold and weight by by sales channel
fraction %>% 
  
ggplot(mapping = aes(x = Canal_ID)) +
  
  geom_bar(mapping = aes(y = units_sold),
           stat = "identity") +
  
  geom_line(mapping = aes(y = weight_sold),
            stat = "identity",
            group = 1,
            color = "blue",
            alpha = 0.4) +
  
  geom_point(mapping = aes(y = weight_sold),
             stat = "identity") + 
  
  scale_y_sqrt() + # to better see the low amounts I'm modifying the y axis
  
  labs(x = "Sales channels",
       y = "Sqrt of ammount",
       title = " Units sold (bar) and Weight (line) by each sales channel")

# Take a look at channels 2 and 4. They have almost the same amount of units sold, but a
# significative difference in weight sold. Let's see the proportion of this difference?

fraction[2:3,] %>% mutate(weight_4_each_unit = sold_weight / sold_units) 
# The result show that for each weight sold through channel 4, we have approximately 1.8 weight sold 
# through channel 2, even though they have approximately the same amount of units sold.

# pryr::object_size(best_selling, comp_ab, fraction, producto, small_sample) # verifying the objects size

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_bar_line_point_Comparison_Units_Weight.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_bar_line_point_Comparison_Units_Weight.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")



#________________________________ Correlation: Venta_uni_hoy x Demanda_uni_equil ________________________________#

# The units sold (Venta_uni_hoy variable) have a positive linear correlation of 0.99 with 
# the adjusted demand (Demanda_uni_equil variable).
#
# The 'adjusted demand' probably is the demand modified to be a positive value (if the returned units 
# are subtracted from the units sold, this adjustment would be necessary). It seems reasonable to 
# believe that it has the same value or even weight of units sold (Venta_uni_hoy variable),
# since they seem to represent the same thing.
#
# It seems reasonable to understand that if I would try to forecast the units sold, I would be 
# forecasting the adjusted demand.


# creating a matrix of plots
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Demanda_uni_equil, Venta_uni_hoy) %>% 
  ggpairs()

# Saving the plot as a PNG 
ggsave(file = "Plots/ggpairs_Venta_uni_hoy_Demanda_uni_equil.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


# Let's plot a comparison between these two metrics (units sold and adjusted demand) on each sales channel
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Demanda_uni_equil, Venta_uni_hoy, Canal_ID) %>% 
  group_by(Canal_ID) %>% 
  summarise(Venta_uni_hoy = sum(Venta_uni_hoy),
            Demanda_uni_equil = sum(Demanda_uni_equil)) %>% 
  
  ggplot(mapping = aes(x = as_factor(Canal_ID) ) ) +
  
  geom_bar(mapping = aes(y = Venta_uni_hoy),
           stat = "identity") +
  
  geom_line(mapping = aes(y = Demanda_uni_equil),
            stat = "identity",
            group = 1,
            color = "blue",
            alpha = 0.4) +
  
  geom_point(mapping = aes(y = Demanda_uni_equil),
             stat = "identity",
             size = 1.5) +
  
  scale_y_sqrt() + # Squared Y scale to get a better view
  
  labs(x = "Sales Channel",
       y = "(Sqrt of) Amount",
       title = " Units sold (bar) and adjusted demand (line + dots) on each sales channel")
  
# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_bar_line_point_Comparison_Units_Demand.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_bar_line_point_Comparison_Units_Demand.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")



#________________________________ Correlation: Venta_hoy x Demanda_uni_equil ________________________________#

# The weight sold (Venta_hoy variable) has a positive linear correlation of 0.80 with 
# the adjusted demand (Demanda_uni_equil variable).
#
# The 'adjusted demand' probably is the demand modified to be a positive value (if the returned units 
# are subtracted from the units sold, this adjustment would be necessary). It seems plausible to 
# see a strong correlation between the adjusted demand and the weight sold, since they represent
# the same thing, but in different units.

# creating a matrix of plots
small_sample %>% 
  sample_frac(size = 0.01) %>% 
  select(Demanda_uni_equil, Venta_hoy) %>% 
  ggpairs()

# Saving the plot as a PNG 
ggsave(file = "Plots/ggpais_Venta_hoy_Demanda_uni_equil.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")




#________________________________ Correlation between test.csv variables ________________________________#


# Correlation btwn the variables in the test.csv
small_sample %>% 
  
  mutate(Canal_ID_sqrted = sqrt(Canal_ID),
         Cliente_ID_sqrted = sqrt(Cliente_ID),
         Ruta_SAK_sqrted = sqrt(Ruta_SAK)) %>%
  
  select(Canal_ID_sqrted,
         Cliente_ID_sqrted,
         Ruta_SAK_sqrted,
         Canal_ID,
         Semana,
         Agencia_ID,
         Ruta_SAK,
         Cliente_ID,
         Producto_ID,
         #Demanda_uni_equil,
         Venta_uni_hoy) %>% 
  
  sample_frac(size = 0.01) %>% 
  
  ggcorr(label = TRUE, 
         label_round = 3, 
         hjust = 0.75, layout.exp = 1)

# I got a small improvment in the correlation between some square rooted variables and the target one 
# (Demanda_uni_equil)

# More about feature construction: 
# https://machinelearningmastery.com/discover-feature-engineering-how-to-engineer-features-and-how-to-get-good-at-it/
# https://medium.com/ml-research-lab/chapter-6-how-to-learn-feature-engineering-49f4246f0d41
#
# As the author of this article says: "The best results come down to you, the practitioner, crafting the features".
# Is not an easy thing to do, but certainly it pays of the effort made on it.
# Since I'm not good enough at it yet, I'll use the original features in the dataset.




#________________________________ Hypotheses test ________________________________#

str(small_sample)

# - The a priori hypotheses assumed were:
#
#     1 - Fitting predictive models to distinct groups of clients or products may be more accurate than to all
#         clients or products as one single group.
#
#     2 - New products may have more return than old ones.
#
#     3 - The regions with higher returns of products may be the ones with the higher variety of products.
#
# The first hipothesis could be tested by a clustering approach. I'll test it latter, since I'm out of time.
#
# After the data exploration, I can say that I cannot test the 2nd hypothesis, since my dataset don't allow
# me to know if a product is new or old.
#
# Lets test the 3rd hipothesis:


# I'll choose the Agencia_ID variable since it represents regions, that can be retrieved from town_state.csv by
# the Agencia_ID.

length(unique(small_sample$Agencia_ID)) # 552

# What is the linear correlation here?
# Agencia_ID — Sales Storehouse ID
# Producto_ID — Product ID
small_sample %$% cor(Agencia_ID, Producto_ID) # we have a very small linear correlation btwn them


# Getting the numbers grouped into a dataset
comparison_a <- small_sample %>% 
  select(Agencia_ID, Producto_ID, Dev_uni_proxima) %>% 
  group_by(Agencia_ID) %>% 
  summarise(unique_products = n_distinct(Producto_ID),
            returned_units = sum(Dev_uni_proxima)) %>% 
  arrange(desc(unique_products)); print(comparison_a) # Just these 10 lines shows us that the regions with higher
                                                      # variety of products don't have the the higher returns of 
                                                      # products. But lets print it to get a better view


# Feature engineering
# ordering rows by descending returned_units, then getting the top 10 rows
comparison_a %<>% 
  arrange(desc(returned_units)) %>% 
  top_n(10)  
# normalization of unique_products and returned_units, so we can compare them
comparison_a$unique_products %<>%  clusterSim::data.Normalization(type = "n1")
comparison_a$returned_units %<>%  clusterSim::data.Normalization(type = "n1")

# Ploting
comparison_a %>% 
  
  top_n(-8) %>% # I had to take out 2 lines because they are outliers
  
  ggplot(mapping = aes(x = reorder(as_factor(Agencia_ID), -returned_units^2) )) +
  
  geom_bar(mapping = aes(y = returned_units^2),
           stat = "identity") +
  
  geom_line(mapping = aes(y = unique_products^2),
            stat = "identity",
            group = 1,
            color = "blue",
            alpha = 0.4,
            size = 0.7) +
  
  geom_point(mapping = aes(y = unique_products^2),
             stat = "identity") +
  
  labs(x = "Top 8 Sales Storehouses (ordered by sum of returned units)",
       y = "Amount (normalized then squared)",
       title = " Comparison between Returned units (bar) and Variety of products (line + points)")


# This plot help us refute the null hiphotesis number 3, so we accept the contrary of it: the regions with higher
# return of products are not the ones with higher variety of products.

# Saving the plot as a PNG and a SVG
ggsave(file = "Plots/geom_bar_line_point_Comparison_Returned_Variety.svg", 
       plot = last_plot(), 
       width = 11.25, 
       height = 7.5,
       units = "in")

ggsave(file = "Plots/geom_bar_line_point_Comparison_Returned_Variety.png", 
       plot = last_plot(), 
       width = 7.5, 
       height = 7.5,
       units = "in")


# Things to consider when testing the 1st hipothesis
# https://www.datacamp.com/community/tutorials/k-means-clustering-r
# https://www.datanovia.com/en/blog/types-of-clustering-methods-overview-and-quick-start-r-code/


