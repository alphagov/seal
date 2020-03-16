#!/bin/bash

teams=(
  govuk-corona-product
  govuk-coronavirus-notifications
  govuk-data-informed
  govuk-frontend-a11y
  govuk-licensing
  govuk-platform-health
  govuk-searchandnav
  govuk-step-by-step
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
