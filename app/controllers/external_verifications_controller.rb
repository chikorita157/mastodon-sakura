# frozen_string_literal: true

class ExternalVerificationsController < ApplicationController
  before_action :set_pack
  before_action :authenticate_user!
  before_action :require_unconfirmed_or_pending!

  skip_before_action :require_functional!

  def first
    redirect_to root_path unless ['anilist', 'myanimelist'].include?(params[:type].to_s) && params[:next]
    redirect_to root_path if params[:type] == 'myanimelist' && !params.key?(:challenge)
    external_verification = ExternalVerification.where(account_id: current_account.id).first_or_initialize(account_id: current_account.id)
    external_verification.challenge = params[:challenge].to_s if params[:challenge]
    external_verification.external_type = params[:type].to_s
    external_verification.save!

    sleep(4) # TODO: adjust this so that the database is ready before callback

    redirect_to Base64.decode64(params[:next].to_s)
  end

  def save
    redirect_to root_path unless ['anilist', 'myanimelist'].include?(params[:id].to_s) && params[:code]
    external_verification = ExternalVerification.find_by(account_id: current_account.id, external_type: params[:id].to_s)
    redirect_to root_path unless external_verification
    base_url = "https://#{ENV.fetch('LOCAL_DOMAIN', nil)}"
    if params[:id] == 'anilist'
      conn = Faraday.new({ url: 'https://anilist.co' })
      post_data = {
        grant_type: 'authorization_code',
        client_id: ENV.fetch('ANILIST_ID', nil),
        client_secret: ENV.fetch('ANILIST_SECRET', nil),
        redirect_uri: "#{base_url}/external_verification/anilist",
        code: params[:code].to_s,
      }
      response = conn.post('/api/v2/oauth/token', post_data.to_json, { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
      redirect_to root_path unless response.success?
      json = JSON.parse(response.body)
      access_token = "Bearer #{json['access_token']}"
      response = Faraday.post('https://graphql.anilist.co', { query: 'query {
                  Viewer {
                    id
                    createdAt
                  }
                }' }.to_json, {
                  'Authorization' => access_token,
                  'Content-Type' => 'application/json',
                  'Accept' => 'application/json',
                })
      redirect_to root_path unless response.success?
      json = JSON.parse(response.body)['data']['Viewer']
      external_id = json['id']
      joined_at = Time.at(json['createdAt']).to_date
      today = Date.current
      account_days = (today - joined_at).to_i
      if account_days >= 90
        external_verification.external_id = external_id # prevent other accounts from using the same ID
        external_verification.save!
        current_user.approved = true
        current_user.save!

        sleep(4) # TODO: adjust this so that the database is ready before callback
      end
      redirect_to root_path
    elsif params[:id] == 'myanimelist'
      conn = Faraday.new(url: 'https://myanimelist.net')
      response = conn.post '/v1/oauth2/token' do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form({ grant_type: 'authorization_code',
                                         client_id: ENV.fetch('MAL_ID', nil),
                                         client_secret: ENV.fetch('MAL_SECRET', nil),
                                         code: params[:code].to_s,
                                         redirect_uri: "#{base_url}/external_verification/myanimelist",
                                         code_verifier: external_verification.challenge })
      end
      redirect_to root_path unless response.success?
      json = JSON.parse(response.body)
      access_token = "Bearer #{json['access_token']}"
      conn = Faraday.new(url: 'https://api.myanimelist.net')
      response = conn.get '/v2/users/@me?fields=anime_statistics' do |req|
        req.headers['Authorization'] = access_token
      end
      redirect_to root_path unless response.success?
      json = JSON.parse(response.body)
      external_id = json['id']
      joined_at = Date.iso8601(json['joined_at'])
      today = Date.current
      account_days = (today - joined_at).to_i
      if account_days >= 90
        external_verification.external_id = external_id # prevent other accounts from using the same ID
        external_verification.save!
        current_user.approved = true
        current_user.save!

        sleep(4) # TODO: adjust this so that the database is ready before callback
      end

      redirect_to root_path
    end
  end

  private

  def require_unconfirmed_or_pending!
    redirect_to root_path if current_user.confirmed? && current_user.approved?
  end

  def set_pack
    use_pack 'auth'
  end
end
