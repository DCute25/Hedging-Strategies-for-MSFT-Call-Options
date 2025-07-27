# Clean the memory and screen
rm(list = ls())
cat("\014")

# Install and load required libraries
if (!require("RQuantLib")) install.packages("RQuantLib", dependencies = TRUE)
if (!require("zoo")) install.packages("zoo", dependencies = TRUE)
if (!require("ggplot2")) install.packages("ggplot2", dependencies = TRUE)

library(RQuantLib)
library(zoo)
library(ggplot2)

# Set working directory
setwd("C:/Aalto/2024-2025/Period 2/Finen Risk Mana/Hedging Assignment")

# Step 1: Read and preprocess data
data <- read.csv("price_data.csv", header = TRUE)
data$Date <- as.Date(data$Date, format = "%Y-%m-%d")
price_data <- read.zoo(file = "price_data.csv", header = TRUE, sep = ",", format = "%Y-%m-%d")

# Constants
expiry_date <- as.Date("2021-06-15")  # Expiry date - Adjust manually
initial_date <- expiry_date - 45      # 45 days before expiry
T_days <- as.numeric(expiry_date - initial_date)
E <- 300                              # Strike price
r <- 0.05                             # Risk-free rate

# Filter relevant data
relevant_data <- data[data$Date >= initial_date & data$Date <= expiry_date, ]
n <- nrow(relevant_data)

# Functions
# Compute implied volatility using Newton-Raphson method
compute_volatility <- function(S, Cobs, T) {
  EuropeanOptionImpliedVolatility(
    type = "call",
    value = Cobs,
    underlying = S,
    strike = E,
    dividendYield = 0,
    riskFreeRate = r,
    maturity = T,
    volatility = 0.5  # Initial guess
  )
}

# Calculate option Greeks
calculate_greeks <- function(S, T, vola) {
  option <- EuropeanOption(
    type = "call",
    underlying = S,
    strike = E,
    riskFreeRate = r,
    maturity = T,
    volatility = vola,
    dividendYield = 0
  )
  return(list(delta = option$delta, vega = option$vega))
}

# Delta Hedging
delta_hedging <- function(frequency) {
  errors <- numeric(n - 1)
  deltas <- numeric(n)
  C_values <- numeric(n)
  S <- relevant_data$Underlying[1]
  Cobs <- relevant_data$C300[1]
  T <- T_days / 365
  
  vola <- compute_volatility(S, Cobs, T)
  greeks <- calculate_greeks(S, T, vola)
  deltas[1] <- greeks$delta
  C_values[1] <- Cobs
  
  for (i in seq(1, n - 1, by = frequency)) {
    if (i + frequency > n) break
    
    S_i <- relevant_data$Underlying[i]
    S_next <- relevant_data$Underlying[i + frequency]
    C_next <- relevant_data$C300[i + frequency]
    T <- T - (frequency / 365)
    
    A_i <- (C_next - C_values[i]) - deltas[i] * (S_next - S_i)
    errors[i] <- A_i^2
    
    greeks_next <- calculate_greeks(S_next, T, vola)
    deltas[i + frequency] <- greeks_next$delta
    C_values[i + frequency] <- C_next
  }
  return(list(errors = sum(errors, na.rm = TRUE) / length(errors[!is.na(errors)]), deltas = deltas))
}

# Delta-Vega Hedging
delta_vega_hedging <- function(frequency) {
  errors <- numeric(n - 1)
  alphas <- numeric(n)
  etas <- numeric(n)
  C_values <- numeric(n)
  S <- relevant_data$Underlying[1]
  Cobs <- relevant_data$C300[1]
  T <- T_days / 365
  T_rep <- T + 0.25  # Add 3 months for replicating option
  
  vola <- compute_volatility(S, Cobs, T)
  greeks <- calculate_greeks(S, T, vola)
  greeks_rep <- calculate_greeks(S, T_rep, vola)
  
  alpha <- greeks$delta - (greeks$vega / greeks_rep$vega) * greeks_rep$delta
  eta <- greeks$vega / greeks_rep$vega
  
  alphas[1] <- alpha
  etas[1] <- eta
  C_values[1] <- Cobs
  
  for (i in seq(1, n - 1, by = frequency)) {
    if (i + frequency > n) break
    
    S_i <- relevant_data$Underlying[i]
    S_next <- relevant_data$Underlying[i + frequency]
    C_next <- relevant_data$C300[i + frequency]
    dt <- frequency / 365
    T <- T - dt
    T_rep <- T_rep - dt
    
    greeks <- calculate_greeks(S_next, T, vola)
    greeks_rep <- calculate_greeks(S_next, T_rep, vola)
    
    alpha <- greeks$delta - (greeks$vega / greeks_rep$vega) * greeks_rep$delta
    eta <- greeks$vega / greeks_rep$vega
    
    A_i <- (C_next - C_values[i]) - (alphas[i] * (S_next - S_i) + etas[i] * (C_next - C_values[i]))
    errors[i] <- A_i^2
    
    alphas[i + frequency] <- alpha
    etas[i + frequency] <- eta
    C_values[i + frequency] <- C_next
  }
  return(list(errors = sum(errors, na.rm = TRUE) / length(errors[!is.na(errors)]), alphas = alphas, etas = etas))
}

# Main execution
delta_result_1d <- delta_hedging(1)
delta_result_5d <- delta_hedging(5)
delta_vega_result_1d <- delta_vega_hedging(1)
delta_vega_result_5d <- delta_vega_hedging(5)

# Display results
formatted_date <- format(expiry_date, "%Y.%m.%d")
cat(sprintf("Expiry date: %s\n", formatted_date))
cat(sprintf("Delta Hedging - 1-Day Frequency: %.10f\n", delta_result_1d$errors))
cat(sprintf("Delta Hedging - 5-Day Frequency: %.10f\n", delta_result_5d$errors))
cat(sprintf("Delta-Vega Hedging - 1-Day Frequency: %.10f\n", delta_vega_result_1d$errors))
cat(sprintf("Delta-Vega Hedging - 5-Day Frequency: %.10f\n", delta_vega_result_5d$errors))

# Plot Delta and Vega Dynamics with Days to Maturity
hedging_data <- data.frame(
  DaysToMaturity = T_days:1,
  Delta = delta_result_1d$deltas,
  Alpha = delta_vega_result_1d$alphas,
  Eta = delta_vega_result_1d$etas
)

p1 <- ggplot(hedging_data) +
  geom_line(aes(x = DaysToMaturity, y = Delta, color = "Delta")) +
  geom_line(aes(x = DaysToMaturity, y = Alpha, color = "Alpha")) +
  geom_line(aes(x = DaysToMaturity, y = Eta, color = "Eta")) +
  ggtitle("Hedging Positions vs Days to Maturity") +
  xlab("Days to Maturity") +
  ylab("Hedging Positions") +
  scale_color_manual(values = c("Delta" = "blue", "Alpha" = "red", "Eta" = "green")) +
  theme_minimal()

# Display the plot
print(p1)
