require "json"
require "sinatra/base"
require "github-trello/version"
require "github-trello/http"

module GithubTrello
  class Server < Sinatra::Base
    #Recieves payload
    post "/posthook" do
      #Get environment variables for configuration
        oauth_token = ENV["oauth_token"]
        api_key = ENV["api_key"]
        board_id = ENV["board_id"]
        start_list_target_id = ENV["start_list_target_id"]
        finish_list_target_id = ENV['finish_list_target_id']

      #Set up HTTP Wrapper
        http = GithubTrello::HTTP.new(oauth_token, api_key)

      #Get payload
        payload = JSON.parse(params[:payload])

      #Get branch
      branch = payload["ref"].gsub("refs/heads/", "")

      payload["commits"].each do |commit|
        # Figure out the card short id
        match = commit["message"].match(/(\[\s*((start|finish|fix|close)e?s?)?\s*#([0-9]+)\s*\])/i)

        next unless match and match[4].to_i > 0

        results = http.get_card(board_id, match[4].to_i)
        unless results
          puts "[ERROR] Cannot find card matching ID #{match[4]}"
          next
        end

        results = JSON.parse(results)

        # Add the commit comment
        message = "#{commit["author"]["name"]}:\n #{commit["message"]}\n\n[#{branch}] #{commit["url"]}"
        message.gsub!(match[1], "")
        message.gsub!(/\(\)$/, "")

        http.add_comment(results["id"], message)

        # done if no actions
        next unless !match[3].nil?
        
        # Determine action to take
        new_list_id = case match[3].downcase
          when "start" then start_list_target_id
          when "finish", "fix", "close" then finish_list_target_id
        end

        next unless !new_list_id.nil?
        
        #Modify it if needed
        to_update = {}

        unless results["idList"] == new_list_id
         to_update[:idList] = new_list_id
        end

        unless to_update.empty?
         http.update_card(results["id"], to_update)
        end
      end
      ""
    end

    get "/" do
      ""
    end

    def self.http; @http end
  end
end