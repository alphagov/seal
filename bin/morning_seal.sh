#!/bin/bash

teams=(
  design-system-dev
  digitalmarketplace
  govuk-corona-product
  govuk-coronavirus-notifications
  govuk-data-labs
  govuk-frontend-a11y
  govuk-data-informed
  govuk-searchandnav
  govuk-licensing
  govuk-pay
  govuk-platform-health
  govuk-pub-workflow
  govuk-taxonomy
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done
