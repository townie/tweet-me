require 'dotenv'
require 'twitter'

class Api

    def self.financial_users
      users = %w(
          Chase
          BofA_News
          GoldmanSachs
          CitizensBank
          jpmorgan
          MorganStanley
          MerrillLynch
          DeutscheBank
          WSJ
          Citibank
          Barclays
          BarclaysUK
          RBSGroup
          Citi
          UBS
        )
    end

    def client
      current ||= ::Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['CONSUMER_KEY']
        config.consumer_secret     = ENV['CONSUMER_SECRET']
        config.access_token        = ENV['ACCESS_TOKEN']
        config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
      end
    end

    def build_set_of_users_history(users, output= "/tmp/tweet_history_#{Time.now.to_i}.csv")
      users.each do |user|
        build_user_history(user, output)
      end
    end

    def build_user_history(user, output = "/tmp/history_#{user}_#{Time.now.to_i}.csv")
      data = get_all_tweets(user)
      CSV.open(output, "a+") do |csv|
        data.each do |tweet|
          csv << [tweet.text] unless tweet.retweet?
        end
      end
    end

    def collect_with_max_id(collection=[], max_id=nil, &block)
      response = yield(max_id)
      collection += response
      response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
    end

    def get_all_tweets(user)
      collect_with_max_id do |max_id|
        options = {count: 200, include_rts: true}
        options[:max_id] = max_id unless max_id.nil?
        count = 2
        begin
          client.user_timeline(user, options)
        rescue => e
          sleep(5.minutes) if e.is_a? ::Twitter::Error::TooManyRequests
          retry unless count <= 0
          count -= 1
        end
      end
    end
end
api = Api.new
api.get_all_tweets(Api.financial_users)
