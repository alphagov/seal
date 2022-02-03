#!/bin/bash

teams=(
  govuk-accounts
  govuk-data-labs
  find-and-view-tech
  govuk-platform-reliability
  govuk-corona-services-tech
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
