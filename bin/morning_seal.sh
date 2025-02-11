#!/bin/bash

teams=(
  github_bots
  payments_infrastructure
  data
  ewa_core
  ewa_modelling
  seal_team
  security_alerts_web_and_be
  security_alerts_app
  card_2
  ewa_progression
  ufu
  marketplace
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=()

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
