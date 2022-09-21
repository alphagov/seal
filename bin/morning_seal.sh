#!/bin/bash

teams=(
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
  interaction-and-personalisation-govuk
  navigation-and-presentation-govuk
  user-experience-measurement-govuk
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=(
  fun-workstream-govuk
  fun-workstream-gds-community
  govuk-green-team
  navigation-and-presentation-govuk
)

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
