Rails.application.routes.draw do

  # ルーティング（LINEプラットフォームから送信されるリクエストを受信できるように設定）
  post '/callback' => 'line_bot#callback'
end
