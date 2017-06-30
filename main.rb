require 'sinatra'
require 'line/bot'

# 微小変更部分！確認用。
get '/' do
  "Hello world"
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_token = ENV['LINE_CHANNEL_TOKEN']
  }
end

post '/callback' do
  body = request.body.read

  File.open("log.txt", "a") do |f| #ログが欲しい
  f.puts("入力された値は" + body + "でした")
  end
  
  #puts body #body出せるかな
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text #文章が送られてきた時

        message = {
          type: 'text',
          text: 'こんにちは'
        }
        File.open("log.txt", "a") do |f| #ログが欲しい
          f.puts("入力された文字列は" + event.text + "でした")
          f.puts("入力されたidは" + event.id + "でした")
        end

        #puts message #message出せるかな
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video #画像やビデオが送られてきたとき
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
        message = {
          type: 'text',
          text: 'これは画像ですね'
        }
        puts message #message出せるかな
        client.reply_message(event['replyToken'], message)
      end
    end
  }

  "OK"
end