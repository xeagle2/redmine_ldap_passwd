module RedmineLdapPasswd
  module MyControllerPatch
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        alias_method_chain :password, :extension
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def password_with_extension
        @user = User.current

        unless @user.change_password_allowed?
          flash[:error] = l(:notice_can_t_change_password)
          redirect_to my_account_path
          return
        end

        if request.post?
          if !@user.check_password?(params[:password])
            flash.now[:error] = l(:notice_account_wrong_password)
          elsif params[:password] == params[:new_password]
            flash.now[:error] = l(:notice_new_password_must_be_different)
          elsif params[:new_password_confirmation] != params[:new_password]
            flash.now[:error] = l(:notice_new_password_and_confirmation_different)
          elsif AuthSourceLdapPasswd.change_password_allowed?(@user)
            if AuthSourceLdapPasswd.is_password_valid (params[:new_password])
              r = @user.auth_source.change_user_password(@user, params[:password], params[:new_password])

              if r == true
                session[:ctime] = User.current.passwd_changed_on.utc.to_i
                flash[:notice] = l(:notice_account_password_updated)
                redirect_to my_account_path
              elsif r == false
                password_without_extension
              else
                flash.now[:error] = r.message
              end
            else
              flash.now[:error] = l(:notice_new_password_format)
            end
          else
            password_without_extension
          end
        end
      rescue Net::LDAP::LdapError => e
        raise AuthSourceException.new(e.message)
      end
    end
  end
end