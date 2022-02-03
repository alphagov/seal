#!/bin/bash

teams=(
  govuk-accounts-tech
  govuk-corona-services-tech
  govuk-data-labs
  find-and-view-tech
  govuk-pay
  govuk-platform-reliability
  govuk-publishing
  govwifi
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done
