#!/bin/bash

teams=(
  govuk-accounts
  govuk-data-labs
  govuk-explore-devs
  govuk-explore-navigation
  govuk-platform-health
  govuk-step-by-step
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
