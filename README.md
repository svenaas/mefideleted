## MeFi Deleted

A simple Twitter bot written to tweet MetaFilter post deletion reasons at [@mefideleted](https://twitter.com/mefideleted)

This bot was written to run at [Heroku](http://heroku.com/) and may be used as a simple example or starting point for other projects.

## Elements

Despite the small amount of code involved this application brings together a large number of technologies and services:

1. **HTTP** retrieval and posting of content

2. **RSS** to retrieve the list of deleted posts.

3. **Nokogiri** to parse HTML in the RSS feed and extract the deletion reasons.

4. **Twitter** to post the extracted deletion reason.

5. **Redis** to keep track of which reasons have already been tweeted.

6. **TwitLonger** to post deletion reasons exceeding 140 characters. 

7. **OAuth** (specifically **OAuth Echo**) to authenticate the Twitter user and application to TwitLonger.

8. **Heroku** for hosting, and of course

9. **Git** and **GitHub** for both source code management and deployment.

## Requirements for Deploying Something Like This

1. [Twitter account](#twitter-account)

2. [Twitter application](#twitter-application)

3. [Twitter application keys](#twitter-application-keys)

4. [TwitLonger API Key](#twitlonger-api-key)

5. [Heroku account](#heroku-account)

### Twitter Account

You'll probaby want a _new_ Twitter account for your bot.

### Twitter Application

Log into Twitter using the account that the bot will use. Then sign into https://dev.twitter.com/ and then register your new Twitter appication at https://apps.twitter.com/.

**Note:** If your bot is going to post then you're going to need to give your application write access to the Twitter account, and as of this writing (2014) Twitter won't let you do this unless your Twitter account has a mobile phone number associated with it. Twitter probably won't let you associate a mobile phone number that's already associated with another Twitter account. Catch-22! Fortunately, you can request write access via http://support.twitter.com/ — do this from your bot's Twitter account, but tell them who you really are and let them know you're not to anything underhanded.

### Twitter Application keys

You'll find the keys `CONSUMER_KEY` and `CONSUMER_SECRET` in the "Keys and Access Tokens" tab of your app's page at https://apps.twitter.com/. The other two keys you need, `OAUTH_TOKEN` and `OAUTH_TOKEN_SECRET`, won't get generated until you set the necessary privilige level for your app and press the "Create my access token" button at the bottom of the "Keys and Access Tokens" tab.

### TwitLonger API key

Some of the messages this app posts are longer than 140 characters. I chose to use TwitLonger when necessary for these longer messages. API keys can be requested at http://api.twitlonger.com/. 

### Heroku Account

In my use this application does not require more than a free tier of service from Heroku, but your use may differ. This app also uses two Heroku add-ons, both also at their free tiers:

- [Redis To Go](https://addons.heroku.com/redistogo) as a simple key/value data store.

- [Heroku Scheduler](https://addons.heroku.com/scheduler) to run the app every 10 minutes.

## Deployment

After you've created your application in Heroku you'll need to add Heroku as a Git remote from your working directory: 

    heroku git:remote -a mefideleted

If you need Heroku addons you can add them at this time as well: 

    heroku addons:add scheduler

    heroku addons:add redistogo

In order to authenticate and post to Twitter this app needs to present several keys. Rather than store them in the code (which would be insecure) this app is written to depend on finding these keys as the server environment variables `CONSUMER_KEY`, `CONSUMER_SECRET`, `OAUTH_TOKEN`, and `OAUTH_TOKEN_SECRET`. You'll find the values of these keys at https://apps.twitter.com/ for your particular application. You set them in Heroku like this:

    heroku config:set CONSUMER_KEY=[your key value]

We do the same thing with the TwitLonger API key and the Redis To Go URL with the environment variables `TWITLONGER_API_KEY` and `REDISTOGO_URL`.

The current local repository can be depoyed to Heroku via git:

    git push heroku master

From your application's administration in Heroku you can then open up Heroku Scheduler and add a job to run it at the desired interval. To make @mefideleted work a Heroku Scheduler job calls `ruby md.rb run` once every 10 minutes.

## License

MeFi Deleted is released under the [MIT License](http://www.opensource.org/licenses/MIT).