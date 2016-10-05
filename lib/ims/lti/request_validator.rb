module IMS::LTI
  # A mixin for OAuth request validation
  module RequestValidator

    attr_reader :oauth_signature_validator

    # Validates and OAuth request using the OAuth Gem - https://github.com/oauth/oauth-ruby
    #
    # To validate the OAuth signatures you need to require the appropriate
    # request proxy for your application. For example:
    #
    #    # For a sinatra app:
    #    require 'oauth/request_proxy/rack_request'
    #
    #    # For a rails app:
    #    require 'oauth/request_proxy/action_controller_request'
    # @return [Bool] Whether the request was valid
    def valid_request?(request, handle_error=true)
      #todo: handle JWT case
      if using_jwt?
        valid_jwt_request?(handle_error)
      else
        valid_oath_request?(request, handle_error)
      end
    end

    def valid_jwt_request?(handle_error=true)
      JWT.decode(@jwt, @consumer_secret)
      true
    rescue JWT::VerificationError
      if handle_error
        false
      else
        raise $!
      end
    end

    def valid_oath_request?(request, handle_error=true)
      begin
        @oauth_signature_validator = OAuth::Signature.build(request, :consumer_secret => @consumer_secret)
        @oauth_signature_validator.verify() or raise OAuth::Unauthorized
        true
      rescue OAuth::Signature::UnknownSignatureMethod, OAuth::Unauthorized
        if handle_error
          false
        else
          raise $!
        end
      end
    end

    # Check whether the OAuth-signed request is valid and throw error if not
    #
    # @return [Bool] Whether the request was valid
    def valid_request!(request)
      valid_request?(request, false)
    end

    # convenience method for getting the oauth nonce from the request
    def request_oauth_nonce
      @oauth_signature_validator && @oauth_signature_validator.request.oauth_nonce
    end

    # convenience method for getting the oauth timestamp from the request
    def request_oauth_timestamp
      @oauth_signature_validator && @oauth_signature_validator.request.oauth_timestamp
    end

  end
end