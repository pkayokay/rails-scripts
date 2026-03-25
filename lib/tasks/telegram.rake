namespace :telegram do
  desc "Send a Telegram notification after deploy with commit info"
  task deploy_notify: :environment do
    require "net/http"
    require "json"

    bot_token = ENV["TELEGRAM_BOT_TOKEN"]
    chat_id = ENV["TELEGRAM_CHAT_ID"]
    github_token = ENV["GITHUB_TOKEN"]
    repo = ENV["GITHUB_REPO"]

    unless bot_token && chat_id && github_token && repo
      puts "Skipping deploy notification: missing environment variables."
      next
    end

    http = Net::HTTP.new("api.github.com", 443)
    http.use_ssl = true
    headers = {"Authorization" => "Bearer #{github_token}", "Accept" => "application/vnd.github+json"}

    # Get the latest push activity to detect branch and commit
    activity_request = Net::HTTP::Get.new("/repos/#{repo}/activity?activity_type=push&direction=desc&per_page=1", headers)
    activity_response = http.request(activity_request)
    activity = JSON.parse(activity_response.body).first

    branch = activity["ref"].sub("refs/heads/", "")
    commit_sha = activity["after"]
    commit_short = commit_sha[0, 7]

    # Get commit details for the message
    commit_request = Net::HTTP::Get.new("/repos/#{repo}/commits/#{commit_sha}", headers)
    commit_response = http.request(commit_request)
    commit_data = JSON.parse(commit_response.body)
    commit_message = commit_data["commit"]["message"].lines.first.strip
    commit_url = "https://github.com/#{repo}/commit/#{commit_sha}"

    text = <<~MSG
      ✅ *Deployed!*

      *Branch:* `#{branch}`
      *Commit:* [#{commit_short}](#{commit_url})
      *Message:* #{commit_message}
    MSG

    uri = URI("https://api.telegram.org/bot#{bot_token}/sendMessage")
    response = Net::HTTP.post_form(uri, {
      chat_id: chat_id,
      text: text,
      parse_mode: "Markdown",
      disable_web_page_preview: true
    })

    if response.is_a?(Net::HTTPSuccess)
      puts "Telegram deploy notification sent."
    else
      puts "Telegram notification failed: #{response.body}"
    end
  end
end
