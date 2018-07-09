#!/bin/bash

teams=(
  design-system-dev
  govuk-data-informed
  govuk-datagovuk-tech
  govuk-licensing
  govuk-platform-health
  govuk-content-pages
  govuk-single-taxonomy
  re-infra-internal
  re-tools-internal
)

for team in ${teams[*]}; do
  ./bin/seal.rb $team
done
