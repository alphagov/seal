#!/bin/bash

teams=(
  github_bots
  payments_infrastructure
  data
  cash_advance_1
  seal_team
  security_alerts
  pricing_and_lending
  card_2
  plus
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=()

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
