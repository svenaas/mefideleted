require "twitter"
require "rss"
require "nokogiri"
require "redis"

ATOM_URL = 'http://mefideleted.blogspot.com/feeds/posts/default'

@client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["CONSUMER_KEY"]
  config.consumer_secret     = ENV["CONSUMER_SECRET"]
  config.access_token        = ENV["OAUTH_TOKEN"]
  config.access_token_secret = ENV["OAUTH_TOKEN_SECRET"]
end

REDIS = Redis.new(:url => URI.parse(ENV["REDISTOGO_URL"]))

# Get the latest deletion reasons from the MeFi Deleted blog's feed
def deletion_reasons 
	feed = RSS::Parser.parse(ATOM_URL, false)

	reasons = feed.entries.each_with_object({}) do |entry, hash| 		
		content = Nokogiri::HTML(entry.content.content)
		content.css('span.reason').text =~ /(.*) (-- .*$)/
		reason = $1
		post_id = content.css('div.mefipost > a:first-of-type').text		
		hash[post_id] = reason
	end
end

# Returns true if the deletion reason for the given post_id has already been tweeted
def tweeted?(post_id)
	REDIS.exists post_id
end

# Records the tweeting of the deletion reason for the given post_id
def tweeted!(post_id)
	# TODO: Add exception handling here
	REDIS.set post_id, true
	return true
end

# Print list of most recent deletion resons
def list	
	reasons = deletion_reasons
	reasons.keys.sort.each {|post_id| puts "#{post_id}}: #{reasons[post_id]}"}
end

def tweet(message)
	# TODO: Add exception handling here
	puts "Tweet: #{message}"
	return true
end

def twitlonger(message)
	# http://api.twitlonger.com/docs/endpoints
	url = URI.parse('http://api.twitlonger.com/2/posts')
    request.content_type = 'application/json'
    request.body = '{"id":5,"amount":5.0,"paid":true}'	
    request['X-API-KEY'] = ENV["TWITLONGER_API_KEY"]
    request['X-Auth-Service-Provider'] = 'https://api.twitter.com/1.1/account/verify_credentials.json'
    request['X-Verify-Credentials-Authorization'] = '' #TODO: Deal with OAUTH from Twitter
    # TODO: Submit message to shorten as form or JSON data (not sure which yet)
	response = Net::HTTP::Post.new(url.path)
end

def run
	reasons = deletion_reasons

	# Check each of the latest deletion reasons to see whether we've 
	# tweeted it already, and tweet the first one we haven't tweeted.
	reasons.keys.sort.each do |post_id|
		unless tweeted?(post_id)
			if tweet(reasons[post_id])
				tweeted!(post_id) 
				break
			end
		end
	end
end	

# Print usage instructions
def usage 
  puts "Usage:"
  puts "  ea.rb run        - normal execution      (may post to Twitter)"
  puts "  ea.rb list       - list deletion reasons"
end

if ARGV.size != 1
  usage
elsif ARGV[0] == 'run'
  run
elsif ARGV[0] == 'list'
  list
else 
  usage
end