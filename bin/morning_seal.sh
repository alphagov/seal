#!/bin/bash

teams=(
  find-and-view-tech
  govuk-accounts-tech
  govuk-datagovuk
  govuk-developers
  govuk-forms
  govuk-frontenders
  govuk-pay
  govuk-platform-reliability
  govuk-publishing-experience
  govuk-publishing-platform
  govuk-replatforming
  govwifi
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=(
  fun-workstream-govuk
  fun-workstream-gds-community
  govuk-green-team
)

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
