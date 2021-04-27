#!/bin/bash

teams=(
  digitalmarketplace-team
  govuk-accounts
  govuk-data-labs
  govuk-explore-navigation
  govuk-frontend-a11y
  govuk-platform-health
  govuk-step-by-step
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
