# Seal

## What is it?

This is a Slack bot that publishes a team's pull requests, Dependabot updates, security alerts, and inspirational quotes to their Slack Channel. Once provided with the organization name, team names, and respective repositories, it posts messages as various animal characters such as the Seal and Dependapanda.

![image](https://github.com/alphagov/seal/blob/main/images/readme/informative.png)
![image](https://github.com/alphagov/seal/blob/main/images/readme/angry.png)

## How to use it?

### Config

Fork the repo and add/change the config files that relate to your github organisation. For example, the alphagov config file is located at [config/alphagov.yml](config/alphagov.yml) and the config for scheduled daily visits can be found in [bin](bin)

Include your team's name, repos and the Slack channel you want to post to.

> If your team is part of the GOV.UK programme, you do not need to add a list of repos to config/alphagov.yml.
> The [Developer docs repos.json](https://docs.publishing.service.gov.uk/repos.json) is now the single source of truth for information about GOV.UK repositories and which team is responsible for them.

In your shell profile, put in:

```sh
export SEAL_ORGANISATION="your_github_organisation"
export GITHUB_TOKEN="get_your_github_token_from_yourgithub_settings"
export SLACK_WEBHOOK="get_your_incoming_webhook_link_for_your_slack_group_channel"
export GITHUB_API_ENDPOINT="your_github_api_endpoint" # OPTIONAL If you are using a Github Enterprise instance
```

### Env variables

```sh
export SEAL_ORGANISATION="your_github_organisation"
export GITHUB_TOKEN="get_your_github_token_from_yourgithub_settings"
export GITHUB_API_ENDPOINT="your_github_api_endpoint" # OPTIONAL If you are using a Github Enterprise instance
export SLACK_WEBHOOK="get_your_incoming_webhook_link_for_your_slack_group_channel"
export SLACK_CHANNEL="#whatever-channel-you-prefer"
export GITHUB_USE_LABELS=true
export GITHUB_SECURITY_ALERTS=true
export GITHUB_EXCLUDE_LABELS="[DO NOT MERGE],Don't merge,DO NOT MERGE,Waiting on factcheck,wip"
export GITHUB_REPOS="myapp,anotherrepo" # Repos you want to be notified about
export COMPACT=true # Use a more compact version of the seal output
export SEAL_QUOTES="Everyone should have the opportunity to learn. Don't be afraid to pick up stories on things you don't understand and ask for help with them.,Try to pair when possible."
```

- To get a new `GITHUB_TOKEN`, head to: https://github.com/settings/tokens
- To get a new `SLACK_WEBHOOK`, head to: https://slack.com/services/new/incoming-webhook

### Bash scripts

You will find several bash scripts in the bin directory, such as morning_seal.sh, afternoon_seal.sh, and dependapanda.sh. These scripts are responsible for running the Seal at different times of the day and for different purposes:

- [morning_seal.sh](https://github.com/alphagov/seal/blob/main/bin/morning_seal.sh): Runs the Seal bot in the morning, posting about old and recent pull requests by team members and also quotes.
- [afternoon_seal.sh](https://github.com/alphagov/seal/blob/main/bin/afternoon_seal.sh): Runs the Seal bot in the afternoon, posting quotes.
- [dependapanda.sh](https://github.com/alphagov/seal/blob/main/bin/dependapanda.sh): Runs the Dependapanda bot in the morning, posting about Dependabot pull requests and security information.

To customize when and which bots post to your team channel, add or remove your team name in the bash scripts above. The team name should correspond to a key in [config/alphagov.yml](https://github.com/alphagov/seal/blob/main/config/alphagov.yml), which should have a `channel` property denoting the name of your team's Slack channel.

### Local testing

To test the script, create a private Slack channel e.g. "#angry-seal-bot-test-abc" and update `@team_channel` on [this line in slack_poster.rb](https://github.com/alphagov/seal/blob/main/lib/slack_poster.rb#L120) to the one you created (also remove the `if` statement).
Then log in to Heroku (credentials can be found in [govuk-secrets](https://github.com/alphagov/govuk-secrets)) and under the "Deploy" tab, you can deploy your branch which should be in the drop down list of branches in the "Manual deploy" section. Under the "More" drop down located in the top right, select "Run console" where you can run `./bin/seal_runner.rb your_team_name`, and you should see the post in your test channel (assuming you have included it in the list of teams in [morning_seal.sh](https://github.com/alphagov/seal/blob/main/bin/morning_seal.sh)).

If you don't want to post github pull requests but a random quote from your team's quotes config, run `./bin/seal_runner.rb your_team_name quotes`

### Slack configuration

The morning_seal.sh and dependapanda.sh scripts run every weekday morning, while the afternoon_seal.sh script runs every weekday afternoon. The scheduler is at https://scheduler.heroku.com/dashboard, and the command to run is bin/seal_runner.rb your_team_name bot_animal.

You should also set up the following custom emojis in Slack:

- :informative_seal:
- :angrier_seal:
- :seal_of_approval:
- :happyseal:
- :halloween_informative_seal:
- :halloween_angrier_seal:
- :halloween_seal_of_approval:
- :festive_season_informative_seal:
- :festive_season_angrier_seal:
- :festive_season_seal_of_approval:
- :manatea:

You can use the images in images/emojis that have the corresponding names.

## Deployment

Heroku will deploy the main branch automatically.

## How to run the tests?

Just run `bundle exec rspec` in the command line.

## Licence

[MIT License](LICENCE)