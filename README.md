# SVCJrw

R-Quantlets zur Analyse von Kryptowährungen mit Fokus auf Marktkapitalisierung, Index-Performance und Parameterschätzungen eines SVCJ-Modells (*Stochastic Volatility with Correlated Jumps*).

Das Repository enthält mehrere eigenständige R-Skripte, Datendateien und Visualisierungen, die im Kontext des Projekts **SVCJrw** veröffentlicht wurden.

## Überblick

| Quantlet | Inhalt |
| --- | --- |
| `SVCJrw_CC_market_caps` | Analyse der Entwicklung des Kryptowährungsmarktes: Anzahl aktiver Coins und Verteilung der Marktkapitalisierung über die Zeit. |
| `SVCJrw_Indices_SharpeR` | Berechnung von Momenten, Sharpe Ratios und Probabilistic Sharpe Ratios für verschiedene Kryptowährungsindizes. |
| `SVCJrw_estimate_parameters` | Rolling-Window-Schätzung der SVCJ-Parameter für CRIX und Erzeugung von `param_t_all.rda`. |
| `SVCJrw_graph_parameters` | Visualisierung von SVCJ-Parameterschätzungen für unterschiedliche Rolling-Window-Längen. |
| `SVCJrw_clustered_parameters` | Clustering ausgewählter SVCJ-Parameterpaare mittels k-means und Visualisierung dynamischer Muster. |

## Repository-Struktur

```text
.
├── data/
│   └── crix_data.csv
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
├── SVCJrw_estimate_parameters/
│   ├── SVCJrw_estimate_parameters.R
│   ├── svcj_model.R
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
```

## Reproduktion

Die Skripte laufen relativ zum Repository und schreiben die reproduzierten Grafiken in die jeweiligen Quantlet-Ordner.

```r
install.packages(c(
  "quantmod", "moments", "corrplot", "xtable",
  "RColorBrewer", "viridis", "ggplot2", "gridExtra"
))
source("reproduce.R")
```

Hinweise:

- `data/crix_data.csv` enthält die CRIX-Zeitreihe (`date`, `price`) vom 31.07.2014 bis 19.04.2020. Diese Zeitreihe stimmt im gemeinsamen Zeitraum exakt mit den CRIX-Werten in `SVCJrw_clustered_parameters/clustering_data.csv` überein.
- `SVCJrw_estimate_parameters` rekonstruiert die Rolling-Window-Parameterschätzung. Ein voller Lauf mit 150/300/600-Tage-Fenstern, Schrittweite 2 und `N = 5000`, `burn-in = 1000` ist sehr rechenintensiv. Für einen Smoke-Test:

```bash
SVCJRW_WINDOWS=150 SVCJRW_MAX_WINDOWS=1 SVCJRW_ITERATIONS=6 SVCJRW_BURN_IN=2 Rscript SVCJrw_estimate_parameters/SVCJrw_estimate_parameters.R
```

- `SVCJrw_CC_market_caps` benötigt die CoinGecko-Rohdatei, die nicht im Repository enthalten ist. Lege sie als `SVCJrw_CC_market_caps/test.csv` oder `SVCJrw_CC_market_caps/20210605_test.csv` ab oder setze `SVCJRW_MARKET_CAPS_CSV=/pfad/zur/datei.csv`.
- Die GIF-Erzeugung in `SVCJrw_clustered_parameters` ist optional und benötigt zusätzlich `gganimate`, `gifski` und `hrbrthemes`. Wenn diese Pakete fehlen, werden die statischen Cluster-Plots trotzdem reproduziert.
- Die Cluster-Plots orientieren sich am Paper: `mu/beta` und `sigma_y/sigma_v` werden jeweils mit `k = 3` geclustert.
