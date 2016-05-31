module RedmineLdapPasswd
  module AccountControllerPatch
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        alias_method_chain :lost_password, :extension
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def lost_password_with_extension
        if params[:token]
          @token = Token.find_token("recovery", params[:token].to_s)
          if @token.nil? || @token.expired?
            redirect_to home_url
            return
          end

          @user = @token.user
          unless @user && @user.active?
            redirect_to home_url
            return
          end

          if request.post?
            if params[:new_password_confirmation] != params[:new_password]
              flash.now[:error] = l(:notice_new_password_and_confirmation_different)
            elsif !AuthSourceLdapPasswd.is_password_valid (params[:new_password])
              flash.now[:error] = l(:notice_new_password_format)
            else
              r = @user.auth_source.change_user_password(@user, '', params[:new_password])

              if r == true
                flash[:notice] = l(:notice_account_password_updated)
                redirect_to signin_path
              elsif r == false
                lost_password_without_extension
              else
                flash.now[:error] = r.message
              end

              return
            end
          end

          render :template => "account/password_recovery"
          return
        else
          lost_password_without_extension
        end
      end
    end
  end
end