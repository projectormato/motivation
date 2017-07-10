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
  urls = ['https://pbs.twimg.com/media/DEY9LFsVwAAVE35.jpg',
          'https://pbs.twimg.com/media/DEY9LE4U0AAUA7e.jpg',
          'https://pbs.twimg.com/media/DEY9LFrUwAAOWhH.jpg']
  body = request.body.read
  
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
        type = 'text'
        reply = "default"
        case event.message['text']
        when "こんにちは"
          reply = "こんにちは！"
        when /(.*)が終わった.*/, /(.*)ができた.*/, /(.*)が済んだ.*/
          reply =  "#{$1}が終わったのね、すごい！"
        when "画像で応援して"
          url = urls[rand(3)]
          imessage = {
            type: 'image',
            originalContentUrl: url,
            previewImageUrl: url
          }
        message = {
          type: 'text',
          text: "ふぁいとー！"
        }
          # client.reply_message(event['replyToken'], message)
          client.reply_message(event['replyToken'], imessage)
        when "声で応援して"
          message = {
            type: 'audio',
            originalContentUrl: 'https://projectormato.github.io/test.m4a',
            duration: 10000
          }
          client.reply_message(event['replyToken'], message)
        end
        message = {
          type: 'text',
          text: reply
        }

        #puts message #message出せるかな
        #puts event.message['text'] #送られてきたメッセージ
        # client.push_message(event['source']['userId'], pmessage)
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video #画像やビデオが送られてきたとき
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
        message = {
          type: 'text',
          text: 'これは画像ですね'
        }
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Sticker
        message = {
          type: 'text',
          text: 'これはスタンプですね'
        }
        client.reply_message(event['replyToken'], message)
      end
    end
  }

  "OK"
end

post '/push' do
  id = ENV['UserId']

  pmessage = {
          type: 'text',
          text: "今日のタスクは、ToDoです。応援してる！！"
  }
  client.push_message(id, pmessage)
end 