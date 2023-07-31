#!/bin/bash

teams=(
  di-ipv-orange-cri-maintainers
  govuk-accounts-tech
  govuk-datagovuk
  govuk-developers
  govuk-forms
  govuk-platform-security-reliability
  govuk-publishing-access-and-permissions
  govuk-publishing-components
  govuk-publishing-experience
  govuk-publishing-on-platform-content
  govuk-publishing-platform
  govuk-platform-engineering
  content-interactions-on-platform-govuk
  navigation-and-homepage-govuk
  user-experience-measurement-govuk
)

for team in ${teams[*]}; do
  ./bin/seal_runner.rb $team dependapanda
done
