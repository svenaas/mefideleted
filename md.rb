require "twitter"
require "rss"
require "nokogiri"
require "redis"
require "net/http"
require "openssl"
require "base64"
require "securerandom"
require 'cgi'

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

    request['X-API-KEY'] = ENV["TWITLONGER_API_KEY"]
    request['X-AUTH-SERVICE-PROVIDER'] = 'https://api.twitter.com/1.1/account/verify_credentials.json'

    # Oh, the fun that is OAuth:
    oauth_timestamp = Time.now.to_i.to_s
    oauth_nonce = SecureRandom.hex(16)

    key         = ENV["CONSUMER_SECRET"] + '&' + ENV["OAUTH_TOKEN_SECRET"]

    params      = 'oauth_consumer_key='     + ENV["CONSUMER_KEY"]  + '&' + 
                  'oauth_nonce='            + oauth_nonce          + '&' + 
                  'oauth_signature_method=' + 'HMAC-SHA1'          + '&' + 
                  'oauth_timestamp='        + oauth_timestamp      + '&' + 
                  'oauth_token='            + ENV["OAUTH_TOKEN"]   + '&' + 
                  'oauth_version='          + '1.0' 

	base_string = 'POST' + '&' + CGI::escape(uri.to_s) + '&' + CGI::escape(params)
    oauth_signature = sign(key, base_string)

    puts
    puts "key:  " + key
    puts
    puts "base: " + base_string
    puts
    puts "sig:  " + oauth_signature
    puts

    auth_header = 
    	'OAuth ' + 
    	'oauth_consumer_key="'     + ENV["CONSUMER_KEY"]          + '", ' +
		'oauth_nonce="'            + oauth_nonce                  + '", ' +
		'oauth_signature="'        + CGI::escape(oauth_signature) + '", ' +
		'oauth_signature_method="HMAC-SHA1", ' +
		'oauth_timestamp="'        + oauth_timestamp              + '", ' + 
		'oauth_token="'            + ENV["OAUTH_TOKEN"]           + '", ' +
		'oauth_version="1.0"'    

	request['X-VERIFY-CREDENTIALS-AUTHORIZATION'] = auth_header

    request.set_form_data("content" => message)

    require 'pp'
    puts "\nREQUEST\n\n"
    pp request

	#response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(request)}
	http = Net::HTTP.new(uri.hostname, uri.port)

	http.set_debug_output $stderr

	response = http.start {|http| http.request(request)}

	puts "\nRESPONSE\n\n"
	pp response
	puts "\nRESPONSE BODY\n\n"
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

def credentials_test
	uri = URI.parse('https://api.twitter.com/1.1/account/verify_credentials.json')
	
	request = Net::HTTP::Get.new(uri.path)

    # Oh, the fun that is OAuth:
    oauth_timestamp = Time.now.to_i.to_s
    oauth_nonce = SecureRandom.hex(16)

    key         = ENV["CONSUMER_SECRET"] + '&' + ENV["OAUTH_TOKEN_SECRET"]

    params      = 'oauth_consumer_key='     + ENV["CONSUMER_KEY"] + '&' + 
                  'oauth_nonce='            + oauth_nonce         + '&' + 
                  'oauth_signature_method=' + 'HMAC-SHA1'         + '&' + 
                  'oauth_timestamp='        + oauth_timestamp     + '&' + 
                  'oauth_token='            + ENV["OAUTH_TOKEN"]  + '&' + 
                  'oauth_version='          + '1.0'                

	base_string = 'GET' + '&' + CGI::escape(uri.to_s) + '&' + CGI::escape(params)
    oauth_signature = sign(key, base_string)

    auth_header = 
    	'OAuth ' + 
    	'oauth_consumer_key="'     + ENV["CONSUMER_KEY"]          + '", ' +
		'oauth_nonce="'            + oauth_nonce                  + '", ' +
		'oauth_signature="'        + CGI::escape(oauth_signature) + '", ' +
		'oauth_signature_method="HMAC-SHA1", ' +
		'oauth_timestamp="'        + oauth_timestamp              + '", ' + 
		'oauth_token="'            + ENV["OAUTH_TOKEN"]           + '", ' +
		'oauth_version="1.0"'     

	request['Authorization'] = auth_header 

	http = Net::HTTP.new(uri.hostname, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_PEER
	#http.ssl_version = :SSLv3

	http.set_debug_output $stderr
	response = http.start {|http| http.request(request)}

	require 'pp'
	pp response
	pp response.body
end

def post_test(message)
	uri = URI.parse('https://api.twitter.com/1.1/statuses/update.json')

	request = Net::HTTP::Post.new(uri.path)

    # Oh, the fun that is OAuth:
    oauth_timestamp = Time.now.to_i.to_s
    oauth_nonce = SecureRandom.hex(16)

    key         = ENV["CONSUMER_SECRET"] + '&' + ENV["OAUTH_TOKEN_SECRET"]

    params      = 'oauth_consumer_key='     + ENV["CONSUMER_KEY"] + '&' + 
                  'oauth_nonce='            + oauth_nonce         + '&' + 
                  'oauth_signature_method=' + 'HMAC-SHA1'         + '&' + 
                  'oauth_timestamp='        + oauth_timestamp     + '&' + 
                  'oauth_token='            + ENV["OAUTH_TOKEN"]  + '&' + 
                  'oauth_version='          + '1.0'               + '&' +
                  'status='                 + URI::encode(message)

	base_string = 'POST' + '&' + CGI::escape(uri.to_s) + '&' + CGI::escape(params)
    oauth_signature = sign(key, base_string)

    auth_header = 
    	'OAuth ' + 
    	'oauth_consumer_key="'     + ENV["CONSUMER_KEY"]          + '", ' +
		'oauth_nonce="'            + oauth_nonce                  + '", ' +
		'oauth_signature="'        + CGI::escape(oauth_signature) + '", ' +
		'oauth_signature_method="HMAC-SHA1", ' +
		'oauth_timestamp="'        + oauth_timestamp              + '", ' + 
		'oauth_token="'            + ENV["OAUTH_TOKEN"]           + '", ' +
		'oauth_version="1.0"'    

	request['Authorization'] = auth_header

    request.set_form_data("status" => message)

    require 'pp'

	http = Net::HTTP.new(uri.hostname, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_PEER	
	http.set_debug_output $stderr
	response = http.start {|http| http.request(request)}

	puts "\nRESPONSE\n\n"
	pp response
	puts "\nRESPONSE BODY\n\n"
	pp response.body
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
elsif ARGV[0] == 'test'
  twitlonger("Test#{Time.now.to_i.to_s}")
elsif ARGV[0] == 'ctest'
  credentials_test
elsif ARGV[0] == 'ptest'
  post_test("Test #{Time.now.to_i.to_s}")
else  
  usage
end