# Seal

## What is it?

This is a Slack bot that publishes a team's pull requests to their Slack Channel, once provided the organisation name, team names and respective repos.

![image](https://github.com/binaryberry/seal/blob/master/images/readme/informative.png)
![image](https://github.com/binaryberry/seal/blob/master/images/readme/angry.png)

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

Another option, which is 12-factor-app ready is to use ENV variables for basically everything.
In that case you don't need a config file at all.

Divider is ',' (comma) symbol.

In your shell profile, put in:

```sh
export SEAL_ORGANISATION="your_github_organisation"
export GITHUB_TOKEN="get_your_github_token_from_yourgithub_settings"
export GITHUB_API_ENDPOINT="your_github_api_endpoint" # OPTIONAL If you are using a Github Enterprise instance
export SLACK_WEBHOOK="get_your_incoming_webhook_link_for_your_slack_group_channel"
export SLACK_CHANNEL="#whatever-channel-you-prefer"
export GITHUB_USE_LABELS=true
export GITHUB_EXCLUDE_LABELS="[DO NOT MERGE],Don't merge,DO NOT MERGE,Waiting on factcheck,wip"
export GITHUB_REPOS="myapp,anotherrepo" # Repos you want to be notified about
export COMPACT=true # Use a more compact version of the seal output
export SEAL_QUOTES="Everyone should have the opportunity to learn. Don’t be afraid to pick up stories on things you don’t understand and ask for help with them.,Try to pair when possible."
```

- To get a new `GITHUB_TOKEN`, head to: https://github.com/settings/tokens
- To get a new `SLACK_WEBHOOK`, head to: https://slack.com/services/new/incoming-webhook

### Bash scripts

In your forked repo, include your team names in the appropriate bash script. Ex. `bin/morning_seal.sh`

### Local testing

To test the script, create a private Slack channel e.g. "#angry-seal-bot-test-abc" and update `@team_channel` on [this line in slack_poster.rb](https://github.com/alphagov/seal/blob/main/lib/slack_poster.rb#L120) to the one you created (also remove the `if` statement).
Then log in to Heroku (credentials can be found in [govuk-secrets](https://github.com/alphagov/govuk-secrets)) and under the "Deploy" tab, you can deploy your branch which should be in the drop down list of branches in the "Manual deploy" section. Under the "More" drop down located in the top right, select "Run console" where you can run `./bin/seal_runner.rb your_team_name`, and you should see the post in your test channel (assuming you have included it in the list of teams in [morning_seal.sh](https://github.com/alphagov/seal/blob/main/bin/morning_seal.sh)).

If you don't want to post github pull requests but a random quote from your team's quotes config, run `./bin/seal_runner.rb your_team_name quotes`

### Slack configuration

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

When that works, you can push the app to Heroku and add the GITHUB_TOKEN and SLACK_WEBHOOK environment variables to heroku.

Use the Heroku scheduler add-on to create repeated tasks - I set the seal to run at 9.30am every morning (the seal won't post on weekends). The scheduler is at [https://scheduler.heroku.com/dashboard](https://scheduler.heroku.com/dashboard) and the command to run is `bin/seal_runner.rb your_team_name bot_animal`

Any questions feel free to contact me on Twitter - my handle is binaryberry

## Deployment

Heroku will deploy the main branch automatically.

## How to run the tests?

Just run `rspec` in the command line.

## Tips

How to list your organisation's repositories modified within the last year:

In `irb`, from the folder of the project, run:

```ruby
require 'octokit'
github = Octokit::Client.new(:access_token => ENV['GITHUB_TOKEN'], auto_pagination: true)
response = github.repos(org: ENV['SEAL_ORGANISATION'])
repo_names = response.select { |repo| Date.parse(repo.created_at.to_s) > (Date.today - 365) }.map(&:name)
```

## Licence

[MIT License](LICENCE)
