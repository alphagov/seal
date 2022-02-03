#!/bin/bash

teams=(
  find-and-view-tech
  govuk-accounts
  govuk-corona-services-tech
  govuk-data-labs
  govuk-platform-reliability
)

for team in ${teams[*]} ; do
  ./bin/seal.rb $team quotes
done
