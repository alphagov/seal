#!/bin/bash

teams=(
  find-and-view-tech
  govuk-accounts-tech
  govuk-corona-services-tech
  govuk-data-labs
  govuk-pay
  govuk-platform-reliability
  govuk-publishing
  govwifi
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=(
  fun-workstream-govuk
  fun-workstream-gds-community
  fun-workstream-test-channel
)

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
