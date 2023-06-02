#!/bin/bash

teams=(
  di-ipv-orange-cri-maintainers
  govuk-accounts-tech
  govuk-datagovuk
  govuk-developers
  govuk-forms
  govuk-frontenders
  govuk-platform-security-reliability
  govuk-publishing-experience
  govuk-publishing-on-platform-content
  govuk-publishing-platform
  govuk-platform-engineering
  content-interactions-on-platform-govuk
  navigation-and-homepage-govuk
  user-experience-measurement-govuk-robot-invasion
)

for team in ${teams[*]}; do
  ./bin/seal_runner.rb $team dependapanda
done
