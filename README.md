# Hedging-Strategies-for-MSFT-Call-Options
This project investigates the effectiveness of delta and delta-vega hedging strategies for At-the-Money (ATM) Microsoft (MSFT) call options. Using real market data from Yahoo Finance and Refinitiv, the study evaluates hedging accuracy under varying re-hedging frequencies (daily vs. 5-day) and transaction cost scenarios.

# 📌 Project Highlights
🧠 Strategies Analyzed:

- Delta Hedging – minimizes sensitivity to small price changes in the underlying asset.

- Delta-Vega Hedging – extends delta hedging by accounting for changes in volatility.

🕒 Hedging Frequencies:

- Rebalancing portfolios every 1 day and every 5 days.

🔁 Robustness:

- Simulations are repeated 10 times using different option maturities to assess variability.

🧮 Error Metric:

- Mean Squared Error (MSE) used to quantify hedging accuracy.

📊 Tools Used:

- Python for data fetching, simulation, and portfolio construction.

- R for computing implied volatility and option Greeks (Delta and Vega).

# 📂 Repository Structure
- ├── option_ric_tools.py       # Python script for retrieving valid option RICs using Refinitiv API
- ├── price_data.csv            # Price data for MSFT and corresponding call/put options
- ├── Hedging Assignment.pdf    # Full technical report detailing the experiment, results, and conclusions
- ├── README.md                 # You're here

# ⚙️ How It Works
Data Collection:

- MSFT price data and option quotes (strikes ranging from 280 to 360) are fetched from Yahoo Finance and Refinitiv using custom Python scripts.

- Focused on ATM call options with 45-day maturities.

Hedging Implementation:

- Delta Hedging: Constructs a portfolio by adjusting positions in MSFT stock.

- Delta-Vega Hedging: Adds a second option with extended maturity to hedge against volatility using calculated alpha (Δ) and eta (κ) values.

Simulation:

- Hedging strategy is repeated over 10 different maturities (June 2021 – March 2022).

- Daily and 5-day rebalancing strategies are tested.

- Final accuracy is measured via average and standard deviation of MSEs.

# 🔍 Key Findings
Strategy	Frequency	Avg. MSE	Std. Dev
Delta Hedging	Daily	0.933	0.983
Delta Hedging	5-day	0.375	0.460
Delta-Vega	Daily	0.384	0.557
Delta-Vega	5-day	0.145	0.179

Delta-Vega hedging outperforms Delta-only hedging in both accuracy and consistency.

Less frequent rebalancing (5-day) results in lower errors due to reduced noise and transaction costs.
