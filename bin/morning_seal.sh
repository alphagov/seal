#!/bin/bash

teams=(
  di-ipv-orange-cri-maintainers
  govuk-accounts-tech
  govuk-datagovuk
  govuk-developers
  govuk-forms
  govuk-frontenders
  govuk-pay
  govuk-platform-security-reliability
  govuk-publishing-experience
  govuk-publishing-platform
  govuk-platform-engineering
  govwifi
  content-interactions-on-platform-govuk
  navigation-and-homepage-govuk
  user-experience-measurement-govuk
  dev-platform-team
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done

morning_quote_teams=(
  fun-workstream-govuk
  fun-workstream-gds-community
  govuk-green-team
  navigation-and-homepage-govuk
  dev-platform-team
)

for team in ${morning_quote_teams[*]}; do
  ./bin/seal.rb $team quotes
done
