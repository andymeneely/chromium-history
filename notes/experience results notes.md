Here are some notes on interpreting the analysis

-------------------------
--- Spearman Analysis ---
-------------------------
Run: July 2nd, 2015

I'm considering 0.5 to 0.7 as "medium" correlation. These variables are considered for dimensionality reduction, but probably will not be needed.

Anything over 0.7 is worth dimensionality reduction.

* SLOC and churn are very close: 0.866. This is to be expected: big files undergo a lot of change. Given this fact, we'll just choose SLOC as our control to be in line with most other literature.
* SLOC is not strongly correlated with anything else. This is important because it shows the difference between product and process metrics. These are human factors metrics that have a weak connection to the product, but still provide additional information
* One obvious place to cut: time to ownership and commits to ownership. Very closely linked at 0.81. Will need to choose one of those
* No other strong correlations are anywhere - all new information
* The strongest correlations are within categories. There might be opportunity to reduce dimensions with PCA or just variable elimination
* Some that are possibly on the chopping block:
  * Security and security bugs are at 0.62
  * 
