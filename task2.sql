# ============================================================
# BA TASK2 - DYNAMIC PRICING SIMULATION
# Thompson Sampling with Contextual Beta Distributions
# ============================================================
pip install numpy pandas scipy

import numpy as np
import pandas as pd

# ------------------------------------------------------------
# 1. SET RANDOM SEED
# ------------------------------------------------------------

np.random.seed(42)


# ------------------------------------------------------------
# 2. DEFINE CONTINUOUS PRICE ARMS
# ------------------------------------------------------------

prices = np.array([
    80,
    90,
    100,
    110,
    120,
    130,
    140,
    150
], dtype=float)


# ------------------------------------------------------------
# 3. INITIAL BETA PARAMETERS
# ------------------------------------------------------------

alpha = np.ones(len(prices))
beta = np.ones(len(prices))


# ------------------------------------------------------------
# 4. SIMULATION SETTINGS
# ------------------------------------------------------------

rounds = 100
customers_per_round = 100

results = []


# ------------------------------------------------------------
# 5. COMPETITOR PRICE
# ------------------------------------------------------------

competitor_price = 110


# ------------------------------------------------------------
# 6. CONVERSION PROBABILITY FUNCTION
# ------------------------------------------------------------

def conversion_probability(price, competitor_price):

    base_probability = 0.35

    price_effect = np.exp(
        -0.025 * (price - 80)
    )

    competitive_effect = np.exp(
        0.015 * (competitor_price - price)
    )

    probability = (
        base_probability
        * price_effect
        * competitive_effect
    )

    return np.clip(probability, 0.01, 0.80)


# ------------------------------------------------------------
# 7. THOMPSON SAMPLING
# ------------------------------------------------------------

for round_number in range(1, rounds + 1):

    # --------------------------------------------------------
    # SIMULATE COMPETITIVE SHOCK
    # --------------------------------------------------------

    if round_number % 20 == 0:

        competitor_price += np.random.choice(
            [-20, -10, 10, 20]
        )

    competitor_price = max(
        60,
        min(160, competitor_price)
    )


    # --------------------------------------------------------
    # SAMPLE POSTERIOR BETA DISTRIBUTION
    # --------------------------------------------------------

    sampled_conversion_rates = np.random.beta(
        alpha,
        beta
    )


    # --------------------------------------------------------
    # ADD PRICE REVENUE EFFECT
    # --------------------------------------------------------

    expected_revenue = (
        prices *
        sampled_conversion_rates
    )


    # --------------------------------------------------------
    # SELECT BEST PRICE
    # --------------------------------------------------------

    selected_index = np.argmax(
        expected_revenue
    )

    selected_price = prices[selected_index]


    # --------------------------------------------------------
    # REAL-TIME CONSUMER CONVERSION
    # --------------------------------------------------------

    true_conversion_rate = conversion_probability(
        selected_price,
        competitor_price
    )


    conversions = np.random.binomial(
        customers_per_round,
        true_conversion_rate
    )


    non_conversions = (
        customers_per_round -
        conversions
    )


    # --------------------------------------------------------
    # UPDATE BETA POSTERIOR
    # --------------------------------------------------------

    alpha[selected_index] += conversions

    beta[selected_index] += non_conversions


    # --------------------------------------------------------
    # CALCULATE REVENUE
    # --------------------------------------------------------

    revenue = (
        selected_price *
        conversions
    )


    # --------------------------------------------------------
    # STORE RESULTS
    # --------------------------------------------------------

    results.append({

        "round": round_number,

        "price": selected_price,

        "competitor_price":
            competitor_price,

        "customers":
            customers_per_round,

        "conversions":
            conversions,

        "conversion_rate":
            conversions /
            customers_per_round,

        "revenue":
            revenue,

        "alpha":
            alpha[selected_index],

        "beta":
            beta[selected_index]
    })


# ------------------------------------------------------------
# 8. CREATE RESULT DATAFRAME
# ------------------------------------------------------------

results_df = pd.DataFrame(results)


# ------------------------------------------------------------
# 9. DISPLAY SIMULATION RESULTS
# ------------------------------------------------------------

print("\nDYNAMIC PRICING SIMULATION")
print("=" * 60)

print(
    results_df.head(20)
)


# ------------------------------------------------------------
# 10. TOTAL REVENUE
# ------------------------------------------------------------

total_revenue = results_df["revenue"].sum()

print("\nTOTAL REVENUE")
print("=" * 60)

print(round(total_revenue, 2))


# ------------------------------------------------------------
# 11. AVERAGE CONVERSION RATE
# ------------------------------------------------------------

average_conversion = (
    results_df["conversion_rate"].mean()
)

print("\nAVERAGE CONVERSION RATE")
print("=" * 60)

print(
    round(
        average_conversion * 100,
        2
    ),
    "%"
)


# ------------------------------------------------------------
# 12. BEST PRICE
# ------------------------------------------------------------

price_performance = (
    results_df
    .groupby("price")
    .agg(
        total_revenue=("revenue", "sum"),
        average_conversion=(
            "conversion_rate",
            "mean"
        ),
        rounds_used=("round", "count")
    )
    .reset_index()
)


best_price = price_performance.loc[
    price_performance["total_revenue"].idxmax()
]


print("\nBEST PRICE")
print("=" * 60)

print(
    "Price:",
    best_price["price"]
)

print(
    "Revenue:",
    round(
        best_price["total_revenue"],
        2
    )
)

print(
    "Conversion Rate:",
    round(
        best_price["average_conversion"] * 100,
        2
    ),
    "%"
)


# ------------------------------------------------------------
# 13. FINAL BETA POSTERIOR
# ------------------------------------------------------------

posterior = pd.DataFrame({

    "price": prices,

    "alpha": alpha,

    "beta": beta,

    "posterior_mean":
        alpha /
        (alpha + beta)

})


print("\nFINAL BETA POSTERIOR")
print("=" * 60)

print(posterior)


# ------------------------------------------------------------
# 14. FINAL RECOMMENDED PRICE
# ------------------------------------------------------------

recommended_index = np.argmax(
    posterior["posterior_mean"].values
)

recommended_price = prices[
    recommended_index
]


print("\nRECOMMENDED PRICE")
print("=" * 60)

print(
    recommended_price
)


# ------------------------------------------------------------
# 15. COMPETITIVE SHOCK ANALYSIS
# ------------------------------------------------------------

shock_analysis = (
    results_df
    .groupby("competitor_price")
    .agg(
        average_price=("price", "mean"),
        average_conversion=(
            "conversion_rate",
            "mean"
        ),
        total_revenue=("revenue", "sum")
    )
    .reset_index()
)


print("\nCOMPETITIVE SHOCK ANALYSIS")
print("=" * 60)

print(shock_analysis)


# ------------------------------------------------------------
# 16. FINAL SUMMARY
# ------------------------------------------------------------

print("\nFINAL SUMMARY")
print("=" * 60)

print(
    "Total Revenue:",
    round(total_revenue, 2)
)

print(
    "Average Conversion Rate:",
    round(
        average_conversion * 100,
        2
    ),
    "%"
)

print(
    "Recommended Price:",
    recommended_price
)

print(
    "Simulation Rounds:",
    rounds
)

print(
    "Customers per Round:",
    customers_per_round
)

print("=" * 60)
