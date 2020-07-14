#!/bin/bash

teams=(
  design-system-dev
  digitalmarketplace
  govuk-accounts-tech
  govuk-corona-product
  govuk-corona-services
  govuk-coronavirus-notifications
  govuk-data-labs
  govuk-frontend-a11y
  govuk-pay
  govuk-platform-health
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done
