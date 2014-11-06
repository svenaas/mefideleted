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

uri   = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:url => ENV['REDISTOGO_URL'])

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

# Get the 20 newest followers, ordered from newest to oldest
def followers
  @client.followers.take(20)
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

	# Follow our latest followers
  followers.reverse.each { |f| @client.follow(f) }
end	

# Print usage instructions
def usage 
  puts "Usage:"
  puts "  ea.rb run        - normal execution      (may post to Twitter)"
  puts "  ea.rb list       - list deletion reasons"
  puts "  ea.rb followers  - list 20 newest followers"
end

if ARGV.size != 1
  usage
elsif ARGV[0] == 'run'
  run
elsif ARGV[0] == 'list'
  list
elsif ARGV[0] == 'followers'
  followers.each {|f| puts "@#{f.username}"}
else 
  usage
end