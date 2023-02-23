#!/usr/bin/env Rscript

require(tidyverse)

read_delim('portfolio.tsv') %>%
  ggplot(aes(x=date, y=usd_value)) +
    geom_line() + 
    ggtitle('Historical value of ETH in USD') +
    xlab('') +
    ylab('') +
    theme_classic() +
    theme(aspect.ratio=1/2)
