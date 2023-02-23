#!/usr/bin/env bash

echo 'date usd_value' > portfolio.tsv
hledger -f portfolio.journal bal --historical \
  assets -X USD -W -e today -X USD --transpose |
  grep '^\s*20' | awk '{print $1, $3}' \
  >> portfolio.tsv
