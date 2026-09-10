# Business Insights — E-Commerce Sales & Customer Analytics

*Generated from the pipeline in this repo (`notebooks/02_eda.ipynb`, `sql/06_advanced_analysis.sql`). Numbers below come from the generated dataset — re-run the pipeline after swapping in real transaction data and these will update automatically.*

## 1. Discounting is eroding margin without a clear volume payoff

| Discount level | Units sold | Net revenue | Profit margin |
|---|---|---|---|
| 0% | 19,320 | ₹34.96 Cr | **31.6%** |
| 5% | 6,413 | ₹11.14 Cr | 28.0% |
| 10% | 6,225 | ₹10.18 Cr | 24.3% |
| 15% | 6,551 | ₹9.98 Cr | 19.5% |
| 20% | 6,213 | ₹8.76 Cr | 14.4% |
| 25% | 6,627 | ₹9.06 Cr | **9.0%** |

Full-price orders are both the highest-volume *and* the highest-margin segment. Once a discount is applied, unit volume flattens out to roughly the same level (~6,200–6,600 units) regardless of whether the discount is 5% or 25% — but profit margin falls in a straight line from 28% down to 9%.

**Recommendation:** the deeper discount tiers (20–25%) are not buying meaningfully more volume than the shallower ones (5–10%). Cap routine promotions at ~10% and reserve steeper discounts for genuine clearance/inventory situations rather than standard promotions.

## 2. Revenue is concentrated in a minority of customers

**1,423 customers (40.4% of the customer base) generate ~80% of total revenue.**

This is a stronger-than-typical concentration and means broad, undifferentiated marketing spend is inefficient — a meaningful share of the customer base contributes very little revenue.

**Recommendation:** prioritize retention and account-management effort on the top 2 RFM tiers rather than spreading marketing budget evenly across the customer base.

## 3. RFM segmentation reveals a real "Champions vs. Lost" value gap

| Segment | Customers | % of base | Avg. lifetime spend |
|---|---|---|---|
| Champions | 796 | 22.6% | ₹6,16,706 |
| Loyal Customers | 558 | 15.8% | ₹2,70,290 |
| Potential Loyalists | 425 | 12.1% | ₹1,36,653 |
| At Risk | 335 | 9.5% | ₹1,30,897 |
| New Customers | 274 | 7.8% | ₹81,321 |
| Needs Attention | 237 | 6.7% | ₹73,229 |
| Lost Customers | 898 | 25.5% | ₹63,983 |

Champions spend **~9.6x** more on average than Lost Customers, and Champions + Loyal Customers together (38.4% of customers) likely account for the bulk of the revenue identified in the Pareto check above.

**Recommendation:** build a lightweight loyalty/retention program targeted at "Potential Loyalists" and "At Risk" — these are the segments most likely to move up a tier with the right nudge (they already show above-average recency or frequency, just not both).

## 4. Category and geography

Revenue is fairly evenly spread across categories rather than concentrated
in one or two — Sports (₹13.3 Cr), Fashion (₹13.1 Cr), and Beauty (₹12.5 Cr)
lead, but Home & Kitchen (₹10.2 Cr) and Electronics (₹10.6 Cr) aren't far
behind. No single category dominates, which means category-specific
promotions need to be evaluated on their own margin profile rather than
assuming the top-revenue category is automatically the priority.

Geographically, revenue is similarly distributed rather than concentrated
in 1-2 states — Gujarat (₹9.4 Cr), Tamil Nadu, and Maharashtra lead, with
Karnataka trailing at ₹6.9 Cr. This spread suggests the customer base
is genuinely national rather than clustered around a couple of metro hubs.

---

## Recommendations summary

1. Cap standard promotional discounts around 10%; reserve deeper discounts for genuine clearance.
2. Shift retention budget toward the top 40% of customers by spend rather than even distribution.
3. Launch a targeted win-back or loyalty nudge for "Potential Loyalists" and "At Risk" segments.
4. Monitor category-level profit margin alongside revenue — a category leading on revenue is not necessarily leading on profit.
5. Track the Pareto ratio (currently ~40% of customers → 80% of revenue) over time as a health metric for customer-base diversification.
