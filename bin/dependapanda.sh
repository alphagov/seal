#!/bin/bash

teams=(
  di-ipv-orange-cri-maintainers
  govuk-accounts-tech
  govuk-datagovuk
  govuk-developers
  govuk-forms
  govuk-frontenders
  govuk-platform-reliability
  govuk-publishing-experience
  govuk-publishing-platform
  govuk-replatforming
  interaction-and-personalisation-govuk
  navigation-and-homepage-govuk
  user-experience-measurement-govuk
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team dependapanda
done
