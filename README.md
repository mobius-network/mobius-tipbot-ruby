# DApp Store TipBot

# Usage:

1. Setup TipBot account. It will hold money before withdrawals.
2. Setup TipBot owner account. It will hold tips.
3. Setup Redis.
4. Setup Slack app and get the token.

# Run:

MOBIUS_TIPBOT_REDIS_URL="redis://localhost:6379/8" MOBIUS_TIPBOT_SLACK_API_TOKEN=<Slack API token> MOBIUS_TIPBOT_APP_PRIVATE_KEY=<TipBot account private key> MOBIUS_TIPBOT_CREDIT_ADDRESS=<TipBot owner public key> bundle exec ruby slack.rb
