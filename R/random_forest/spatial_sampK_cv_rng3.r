spatial.cv.rf <- function(
  preds, y_var, train_set, 
  no_trees, min_node_size, my_weights, 
  model_name, model_path){
  
  #browser()
  
  h2o.init()
  
  # fit a RF model
  RF_obj <- fit_h2o_RF(
    dependent_variable = y_var, 
    predictors = preds, 
    training_dataset = train_set, 
    no_trees = no_trees, 
    min_node_size = min_node_size,
    my_weights = my_weights,
    model_nm = model_name)
  
  # make predictions
  predictions <- make_h2o_predictions(
    mod_obj = RF_obj, 
    dataset = train_set, 
    sel_preds = preds)
    
  h2o.saveModel(RF_obj, model_path, force = TRUE)
  
  h2o.shutdown(prompt = FALSE)
  
  predictions

}
