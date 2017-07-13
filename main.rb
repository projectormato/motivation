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
  urls = #画像のURLたち 
        ['https://pbs.twimg.com/media/DEY9LFsVwAAVE35.jpg',
         'https://pbs.twimg.com/media/DEY9LE4U0AAUA7e.jpg',
         'https://pbs.twimg.com/media/DEY9LFrUwAAOWhH.jpg']
  aid_texts = # 応援する言葉
           ['愛してるよ',
            'よく頑張ってるね、もう一息！',
            'あなたは出来る人！',
            'ちょっと休憩しよう？',
            '頑張れ！ファイト！！',
            '頑張ってください！！！！！']
  praise_texts = #褒める言葉
              ['愛してるよ',
               'さすが！',
               '素晴らしい！！',
               'すごい！',
               'いいね！',
               'ナイス！',
               'よく頑張ったね',
               'お疲れ様！！',
               'さっすがー！']
  scold_texts = #叱る言葉
              ['ダメじゃない！次はしっかりね？',
               '冗談でしょ？応援してるから、しっかりして？',
               'あら･･･次はがんばろうね',
               '仕方ないね、無理せずコツコツいこう！']
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
        reply = "応援してる！"
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
        when /.*応援.*/, /.*辛い.*/, /.*つらい.*/, /.*大変.*/, /.*やばい.*/, /.*助けて.*/, /.*無理.*/, /.*むり.*/
          reply = aid_texts[rand(aid_texts.length)]
        when /.*褒めて.*/,/.*ほめて.*/,/.*頑張.*/, /.*がんば.*/, /.*上手く.*/
          reply = praise_texts[rand(praise_texts.length)]
        when /.*終わってない.*/, /.*おわってない.*/, /.*出来てない.*/, /.*できてない.*/, /.*済んでない.*/
          reply = scold_texts[rand(scold_texts.length)]
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
  ptext = Time.now.month.to_s + "月"+ Time.now.day.to_s + "日" + ((Time.now.hour+10)%24).to_s + "時までのタスク、終わった？"
  pmessage = {
          type: 'text',
          text: ptext
  }
  client.push_message(id, pmessage)
end 