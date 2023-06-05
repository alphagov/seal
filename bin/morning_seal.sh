#!/bin/bash

teams=(
  di-ipv-orange-cri-maintainers
  govuk-accounts-tech
  govuk-datagovuk
  govuk-developers
  govuk-forms
  govuk-pay
  govuk-platform-security-reliability
  govuk-publishing-components
  govuk-publishing-experience
  govuk-publishing-on-platform-content
  govuk-publishing-platform
  govuk-platform-engineering
  govwifi
  content-interactions-on-platform-govuk
  navigation-and-homepage-govuk
  user-experience-measurement-govuk
  dev-platform-team
)

for team in ${teams[*]}; do
  ./bin/seal_runner.rb $team
done

morning_quote_teams=(
  fun-workstream-govuk
  fun-workstream-gds-community
  govuk-green-team
  navigation-and-homepage-govuk
  dev-platform-team
  user-experience-measurement-govuk
)

for team in ${morning_quote_teams[*]}; do
  ./bin/seal_runner.rb $team quotes
done
