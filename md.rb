require "twitter"
require "rss"
require "nokogiri"

ATOM_URL = 'http://mefideleted.blogspot.com/feeds/posts/default'

def reasons 
	feed = RSS::Parser.parse(ATOM_URL, false)

	hash = feed.entries.each_with_object({}) do |entry, hash| 		
		content = Nokogiri::HTML(entry.content.content)
		content.css('span.reason').text =~ /(.*) (-- .*$)/
		reason = $1
		post_id = content.css('div.mefipost > a:first-of-type').text		
		hash[post_id] = reason
	end
end

reasons.keys.sort.each {|k| puts "#{k}: #{reasons[k]}"}