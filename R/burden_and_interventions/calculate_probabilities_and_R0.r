calculate_probs_and_R0 <- function(
  age_data, ID_0, age_band_tags, FOI, 
  age_band_lower_bounds, age_band_upper_bounds,
  total_pop, vec_phis){
  
  
  # ---------------------------------------- start
  
  
  # get age structure for the FOI location 
  ag_st <- age_data[age_data$ID_0 == ID_0, age_band_tags]
  
  # calculate n people in age group
  n_j <- ag_st * total_pop  
  
  
  # ---------------------------------------- calculate incidence of infections
  
  
  inf_1_prob <- calculate_primary_infection_prob( 
    FOI, 
    age_band_lower_bounds, 
    age_band_upper_bounds)
  
  inf_2_prob <- calculate_secondary_infection_prob( 
    FOI,
    age_band_lower_bounds, 
    age_band_upper_bounds)
  
  inf_3_prob <- calculate_tertiary_infection_prob(
    FOI,
    age_band_lower_bounds, 
    age_band_upper_bounds)
  
  inf_4_prob <- calculate_quaternary_infection_prob(
    FOI, 
    age_band_lower_bounds, 
    age_band_upper_bounds)
  
  inc_1_rate <- calc_average_prob_infect(inf_1_prob, age_band_upper_bounds, age_band_lower_bounds)
  
  inc_2_rate <- calc_average_prob_infect(inf_2_prob, age_band_upper_bounds, age_band_lower_bounds)
  
  inc_3_rate <- calc_average_prob_infect(inf_3_prob, age_band_upper_bounds, age_band_lower_bounds)
  
  inc_4_rate <- calc_average_prob_infect(inf_4_prob, age_band_upper_bounds, age_band_lower_bounds)
  
  infec_1_j <- calculate_case_number(inc_1_rate, n_j)
  
  infec_2_j <- calculate_case_number(inc_2_rate, n_j)
  
  infec_3_j <- calculate_case_number(inc_3_rate, n_j)
  
  infec_4_j <- calculate_case_number(inc_4_rate, n_j)
  
  total_infec_1 <- sum(infec_1_j) 
  
  total_infec_2 <- sum(infec_2_j)
  
  total_infec_3 <- sum(infec_3_j)
  
  total_infec_4 <- sum(infec_4_j)
  
  
  # ------------------------------------- calculate R0
  
  
  calculate_R0(
    FOI = FOI,
    N = total_pop,
    vec_infections = c(total_infec_1, total_infec_2, total_infec_3, total_infec_4), 
    vec_phis = vec_phis)
  
}