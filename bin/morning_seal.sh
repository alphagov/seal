#!/bin/bash

teams=(
  github_bots
  payments_infrastructure
  data
  payments_security_experience
  seal_team
  data_science_engineers
  security_alerts
  pricing_and_lending
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=()

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
