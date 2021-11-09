#!/bin/bash

teams=(
  govuk-accounts-tech
  govuk-corona-products
  govuk-data-labs
  govuk-explore-devs
  govuk-pay
  govuk-platform-health
  govuk-publishing
  govwifi
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done
