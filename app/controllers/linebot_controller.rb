class LinebotController < ApplicationController
  # LINE Messaging APIのRuby SDKを読み込むためのコード
  require 'line/bot'

  # callback メソッド は、LINEのWebhookから送られてくるイベントを処理するためのアクション
  def callback
    # LINEサーバーから送られてきたリクエストの内容（メッセージやイベント情報）を読み取る
    body = request.body.read
    # リクエストの署名を取得（リクエストが正当なものであるか確認）
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    # LINEサーバーからのリクエストが改ざんされていないかどうかを検証
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    # bodyから送られてきたイベントを解析し、events配列を取得
    events = client.parse_events_from(body)

    # イベントごとの処理
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Location
          # LINEの位置情報から緯度経度を取得
          latitude = event.message['latitude']
          longitude = event.message['longitude']
          appId = "4118aed3340b1ff4b0a9953dc3c81f00"
          url= "http://api.openweathermap.org/data/2.5/forecast?lon=#{longitude}&lat=#{latitude}&APPID=#{appId}&units=metric&mode=xml"
         # XMLをパースしていく
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherdata/forecast/time[1]/'
          nowWearther = doc.elements[xpath + 'symbol'].attributes['name']
          nowTemp = doc.elements[xpath + 'temperature'].attributes['value']
          case nowWearther
          # 条件が一致した場合、メッセージを返す処理。絵文字も入れています。
          when /.*(clear sky|few clouds).*/
            push = "現在地の天気は晴れです\u{2600}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(scattered clouds|broken clouds|overcast clouds).*/
            push = "現在地の天気は曇りです\u{2601}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(rain|thunderstorm|drizzle).*/
            push = "現在地の天気は雨です\u{2614}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(snow).*/
            push = "現在地の天気は雪です\u{2744}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          when /.*(fog|mist|Haze).*/
            push = "現在地では霧が発生しています\u{1F32B}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          else
            push = "現在地では何かが発生していますが、\nご自身でお確かめください。\u{1F605}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          end

          message = {
            type: 'text',
            text: push
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    # リクエストが正常に処理されたことをLINEサーバーに通知するために、HTTP 200 (OK) ステータスを返す
    head :ok
    
  end

  # LINE Messaging API クライアントを作成
  def client
    # @client ||= は、クライアントを一度だけ作成し、以降は再利用するためのコード
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
  
end
