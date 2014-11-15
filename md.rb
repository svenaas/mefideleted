require "twitter"
require "rss"
require "nokogiri"
require "redis"
require "net/http"
require "openssl"
require "base64"
require "securerandom"

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
	uri = URI.parse('http://api.twitlonger.com/2/posts')
	request = Net::HTTP::Post.new(uri.path)
    #request.content_type = 'application/json'
    request.content_type = 'application/x-www-form-urlencoded'
    request['X-API-KEY'] = ENV["TWITLONGER_API_KEY"]
    request['X-Auth-Service-Provider'] = 'https://api.twitter.com/1.1/account/verify_credentials.json'

    # Oh, the fun that is OAuth:
    oauth_timestamp = Time.now.to_i.to_s
    oauth_nonce = SecureRandom.urlsafe_base64(32)

    key         = ENV["CONSUMER_SECRET"] + '&' + ENV["OAUTH_TOKEN_SECRET"]
    base_string = 'POST&http%3A%2F%2Fapi.twitlonger.com%2F2%2Fposts%26' +     
                  'oauth_consumer_key%3D'     + ENV["CONSUMER_KEY"] + '%26' + 
                  'oauth_nonce%3D'            + oauth_nonce         + '%26' + 
                  'oauth_signature_method%3D' + 'HMAC-SHA1'         + '%26' + 
                  'oauth_timestamp%3D'        + oauth_timestamp     + '%26' + 
                  'oauth_token%3D'            + ENV["OAUTH_TOKEN"]  + '%26' + 
                  'oauth_version%3D'          + '1.0'                

    oauth_signature = sign(key, base_string)

    request['X-Verify-Credentials-Authorization'] = 
    	'OAuth realm="http://api.twitter.com/",' + 
    	'oauth_consumer_key="'     + ENV["CONSUMER_KEY"]         + '",' +
		'oauth_nonce="'            + oauth_nonce                 + '",' +
		'oauth_signature="'        + oauth_signature             + '",' +
		'oauth_signature_method="HMAC-SHA1",' +
		'oauth_token="'            + ENV["OAUTH_TOKEN"]          + '",' +
		'oauth_timestamp="'        + oauth_timestamp             + '",' + 
		'oauth_version="1.0"'     

    #request.body = '{"content":"' + message + '"}'	
    #request.body = '[ {"content":"' + message + '"} ]'	
    #request.body = "content=#{message}"
    request.set_form_data("content" => message)

    require 'pp'
    pp request

	#response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request)}
	http = Net::HTTP.new(uri.hostname, uri.port)
	http.set_debug_output $stderr
	response = http.start {|http| http.request(request)}

	pp response
	pp response.body
end

# See http://stackoverflow.com/a/4758649
def sign( key, base_string )
  digest = OpenSSL::Digest.new( 'sha1' )
  hmac = OpenSSL::HMAC.digest( digest, key, base_string  )
  Base64.encode64( hmac ).chomp.gsub( /\n/, '' )
end

# def twitlonger_test
# 	# http://api.twitlonger.com/docs/endpoints
# 	uri = URI.parse('http://api.twitlonger.com/2/posts/n_1siespo')
# 	request = Net::HTTP::Get.new(uri.path)
#     request['X-API-KEY'] = ENV["TWITLONGER_API_KEY"]
# 	response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request)}
# 	require 'pp'
# 	pp response
# 	pp response.body
# end

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
elsif ARGV[0] == 'test'
  twitlonger("test two")
else 
  usage
end