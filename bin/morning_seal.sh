#!/bin/bash

teams=(
  find-and-view-tech
  FUN-workstream
  govuk-accounts-tech
  govuk-corona-services-tech
  govuk-data-labs
  govuk-pay
  govuk-platform-reliability
  govuk-publishing
  govwifi
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done
