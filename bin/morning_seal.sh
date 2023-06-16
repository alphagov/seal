#!/bin/bash

teams=(
  payments_infrastructure
  security_alerts
  data
  payments_security_experience
  seal_team
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=()

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
