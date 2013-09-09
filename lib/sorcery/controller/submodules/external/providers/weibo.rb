module Sorcery
  module Controller
    module Submodules
      module External
        module Providers
          # This module adds support for OAuth with weibo.com.
          # When included in the 'config.providers' option, it adds a new option, 'config.weibo'.
          # Via this new option you can configure Weibo specific settings like your app's key and secret.
          #
          #   config.weibo.key = <key>
          #   config.weibo.secret = <secret>
          #   ...
          #
          module Weibo
            def self.included(base)
              base.module_eval do
                class << self
                  attr_reader :weibo                           # access to weibo_client.

                  def merge_weibo_defaults!
                    @defaults.merge!(:@weibo => WeiboClient)
                  end
                end
                merge_weibo_defaults!
                update!
              end
            end

            module WeiboClient
              include Base::BaseClient
              class << self
                attr_accessor :key,
                              :secret,
                              :callback_url,
                              :auth_path,
                              :token_path,
                              :site,
                              :scope,
                              :user_info_path,
                              :user_info_mapping,
                              :state
                attr_reader   :access_token

                include Protocols::Oauth2

                def init
                  @site           = "https://api.weibo.com/"
                  @uid_path       = "/account/get_uid.json"
                  @user_info_path = "/users/show.json"
                  @scope          = "email"
                  @auth_path      = "/oauth2/authorize"
                  @token_path     = "/oauth2/access_token"
                  @mode           = :query
                  @parse          = :json
                  @param_name     = "access_token"
                  @user_info_mapping = {}
                end

                def get_user_hash(access_token)
                  uid_response = access_token.get(@uid_path)
                  uid = JSON.parse(uid_response.body)['uid']
                  user_hash = {uid: uid}
                  response = access_token.get(@user_info_path + "?uid=#{uid}")
                  user_hash[:user_info] = JSON.parse(response.body)
                  user_hash[:user_info]['email'] = "#{uid}@weibo.thunderboltlabs.com" # waiting on email privileges
                  user_hash
                end

                def has_callback?
                  true
                end

                # calculates and returns the url to which the user should be redirected,
                # to get authenticated at the external provider's site.
                def login_url(params,session)
                  self.authorize_url({:authorize_url => @auth_path})
                end

                # tries to login the user from access token
                def process_callback(params,session)
                  args = {}
                  args.merge!({:code => params[:code]}) if params[:code]
                  options = {
                    :token_url    => @token_path,
                    :token_method => :post,
                    :param_name   => @param_name,
                    :mode         => @mode,
                    :parse        => @parse
                  }
                  return self.get_access_token(args, options)
                end

              end
              init
            end

          end
        end
      end
    end
  end
end
