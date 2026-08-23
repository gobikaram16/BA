

!pip install numpy pandas scipy
import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import gammaln, betaln

print("All libraries imported successfully!")
data = {
    "customer_id": [1, 2, 3, 4, 5],
    "frequency": [8, 5, 3, 7, 2],
    "recency": [30, 25, 18, 35, 12],
    "T": [45, 40, 30, 50, 20],
    "monetary_value": [120, 80, 60, 150, 40]
}

customers = pd.DataFrame(data)

print(customers)
# ============================================================
# BA TASK 1 - WEEK 1
# Mathematical Customer Lifetime Value (CLV)
# Projection via BG/NBD Model from Scratch
# ============================================================

import numpy as np
import pandas as pd

from scipy.optimize import minimize
from scipy.special import gammaln, betaln


# ============================================================
# 1. CREATE SAMPLE CUSTOMER TRANSACTION DATA
# ============================================================

data = {
    "customer_id": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    "frequency": [8, 5, 3, 7, 2, 10, 4, 6, 1, 9],
    "recency": [30, 25, 18, 35, 12, 40, 22, 28, 10, 38],
    "T": [45, 40, 30, 50, 20, 55, 35, 45, 18, 50],
    "monetary_value": [
        120, 80, 60, 150, 40,
        200, 75, 110, 30, 180
    ]
}

customers = pd.DataFrame(data)

print("CUSTOMER DATA")
print(customers)


# ============================================================
# 2. EXTRACT BG/NBD VARIABLES
# ============================================================

frequency = customers["frequency"].values.astype(float)
recency = customers["recency"].values.astype(float)
T = customers["T"].values.astype(float)

monetary_value = customers["monetary_value"].values.astype(float)


# ============================================================
# 3. BG/NBD LOG-LIKELIHOOD FUNCTION
# ============================================================

def bg_nbd_log_likelihood(params, frequency, recency, T):

    r, alpha, a, b = np.exp(params)

    x = frequency
    tx = recency
    t = T

    # Avoid numerical problems
    alpha_tx = alpha + t
    alpha_recency = alpha + tx

    # First part of BG/NBD likelihood

    log_likelihood = (
        gammaln(r + x)
        - gammaln(r)
        + r * np.log(alpha)
        - (r + x) * np.log(alpha_tx)
    )

    # Beta-function component

    log_likelihood += (
        betaln(a + 1, b + x)
        - betaln(a, b)
    )

    # Additional term for customers with repeat purchases

    repeat_mask = x > 0

    log_likelihood[repeat_mask] += np.log(
        a / (b + x[repeat_mask])
        +
        np.exp(
            betaln(r + x[repeat_mask], 1 + b)
            -
            betaln(r, 1 + b)
            -
            (r + x[repeat_mask])
            * np.log(alpha_recency[repeat_mask])
        )
    )

    return np.sum(log_likelihood)


# ============================================================
# 4. NEGATIVE LOG-LIKELIHOOD
# ============================================================

def negative_log_likelihood(
    params,
    frequency,
    recency,
    T
):

    return -bg_nbd_log_likelihood(
        params,
        frequency,
        recency,
        T
    )


# ============================================================
# 5. INITIAL PARAMETER VALUES
# ============================================================

initial_parameters = np.log([
    1.0,    # r
    1.0,    # alpha
    1.0,    # a
    1.0     # b
])


# ============================================================
# 6. L-BFGS-B OPTIMIZATION
# ============================================================

result = minimize(
    negative_log_likelihood,
    initial_parameters,
    args=(frequency, recency, T),
    method="L-BFGS-B"
)


# ============================================================
# 7. ESTIMATED PARAMETERS
# ============================================================

r, alpha, a, b = np.exp(result.x)

print("\nESTIMATED BG/NBD PARAMETERS")
print("--------------------------------")
print("r     =", r)
print("alpha =", alpha)
print("a     =", a)
print("b     =", b)

print("\nOptimization Status:")
print(result.message)


# ============================================================
# 8. EXPECTED FUTURE PURCHASES
# ============================================================

def expected_purchases(
    frequency,
    recency,
    T,
    r,
    alpha,
    a,
    b,
    future_period
):

    # Transaction rate estimate

    transaction_rate = (
        (r + frequency)
        /
        (alpha + T)
    )

    # Probability that customer is still alive

    dropout_probability = (
        (a + frequency)
        /
        (a + b + frequency)
    )

    expected_transactions = (
        transaction_rate
        * future_period
        * dropout_probability
    )

    return expected_transactions


customers["predicted_purchases"] = expected_purchases(
    frequency,
    recency,
    T,
    r,
    alpha,
    a,
    b,
    future_period=30
)


# ============================================================
# 9. CUSTOMER LIFETIME VALUE
# ============================================================

customers["predicted_CLV"] = (
    customers["predicted_purchases"]
    *
    customers["monetary_value"]
)


# ============================================================
# 10. CUSTOMER SEGMENTATION
# ============================================================

customers["customer_segment"] = np.where(
    customers["predicted_CLV"] >= 500,
    "High Value",
    np.where(
        customers["predicted_CLV"] >= 200,
        "Medium Value",
        "Low Value"
    )
)


# ============================================================
# 11. FINAL CLV REPORT
# ============================================================

print("\nCUSTOMER CLV REPORT")
print("--------------------------------")

print(
    customers[
        [
            "customer_id",
            "frequency",
            "recency",
            "T",
            "monetary_value",
            "predicted_purchases",
            "predicted_CLV",
            "customer_segment"
        ]
    ]
)


# ============================================================
# 12. TOP 5 HIGH-VALUE CUSTOMERS
# ============================================================

top_customers = customers.sort_values(
    by="predicted_CLV",
    ascending=False
).head(5)

print("\nTOP 5 CUSTOMERS BY CLV")
print("--------------------------------")

print(
    top_customers[
        [
            "customer_id",
            "predicted_CLV",
            "customer_segment"
        ]
    ]
)


# ============================================================
# 13. TOTAL EXPECTED CLV
# ============================================================

total_clv = customers["predicted_CLV"].sum()

print("\nTOTAL EXPECTED CLV")
print("--------------------------------")
print(round(total_clv, 2))


# ============================================================
# 14. AVERAGE CUSTOMER CLV
# ============================================================

average_clv = customers["predicted_CLV"].mean()

print("\nAVERAGE CUSTOMER CLV")
print("--------------------------------")
print(round(average_clv, 2))


# ============================================================
# 15. SEGMENT SUMMARY
# ============================================================

segment_summary = (
    customers
    .groupby("customer_segment")
    .agg(
        customer_count=("customer_id", "count"),
        total_clv=("predicted_CLV", "sum"),
        average_clv=("predicted_CLV", "mean")
    )
    .reset_index()
)

print("\nCUSTOMER SEGMENT SUMMARY")
print("--------------------------------")

print(segment_summary)


# ============================================================
# END OF WEEK-1 BA TASK
# ============================================================

