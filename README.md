# SVCJrw

R-Quantlets zur Analyse von Kryptowährungen mit Fokus auf Marktkapitalisierung, Index-Performance und Parameterschätzungen eines SVCJ-Modells (*Stochastic Volatility with Correlated Jumps*).

Das Repository enthält mehrere eigenständige R-Skripte, Datendateien und Visualisierungen, die im Kontext des Projekts **SVCJrw** veröffentlicht wurden.

## Überblick

| Quantlet | Inhalt |
| --- | --- |
| `SVCJrw_CC_market_caps` | Analyse der Entwicklung des Kryptowährungsmarktes: Anzahl aktiver Coins und Verteilung der Marktkapitalisierung über die Zeit. |
| `SVCJrw_Indices_SharpeR` | Berechnung von Momenten, Sharpe Ratios und Probabilistic Sharpe Ratios für verschiedene Kryptowährungsindizes. |
| `SVCJrw_graph_parameters` | Visualisierung von SVCJ-Parameterschätzungen für unterschiedliche Rolling-Window-Längen. |
| `SVCJrw_clustered_parameters` | Clustering ausgewählter SVCJ-Parameterpaare mittels k-means und Visualisierung dynamischer Muster. |

## Repository-Struktur

```text
.
├── SVCJrw_CC_market_caps/
│   ├── SVCJrw_CC_market_caps.R
│   ├── active_coins.png
│   ├── sorted_market_caps_over_time.png
│   └── metainfo.txt
├── SVCJrw_Indices_SharpeR/
│   ├── SVCJrw_Indices_SharpeR.R
│   ├── all_indices.rda
│   ├── daily_sums_n.csv
│   ├── daily_sums_n.rda
│   ├── normed_indices.png
│   ├── corrplot_indices_blue.png
│   └── metainfo.txt
├── SVCJrw_graph_parameters/
│   ├── SVCJrw_graph_parameters.R
│   ├── param_t_all.rda
│   ├── *.png
│   └── metainfo.txt
└── SVCJrw_clustered_parameters/
    ├── SVCJrw_clustered_parameters.R
    ├── clustering_data.csv
    ├── gif_data.Rda
    ├── *.png / *.gif
    └── metainfo.txt
