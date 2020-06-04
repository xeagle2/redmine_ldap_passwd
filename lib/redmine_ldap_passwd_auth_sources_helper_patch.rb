module RedmineLdapPasswd
  module AuthSourcesHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        if Rails::VERSION::MAJOR >= 5
          alias_method :auth_source_partial_name_without_ignored_passwd, :auth_source_partial_name
          alias_method :auth_source_partial_name, :auth_source_partial_name_with_ignored_passwd
        else
          alias_method :auth_source_partial_name, :ignored_passwd
        end
      end
    end

    module InstanceMethods
      # Make sure AuthSourceLdapPasswd is loaded with the same form as AuthSourceLdap
      def auth_source_partial_name_with_ignored_passwd(auth_source)
        "form_#{auth_source.class.name.underscore}".chomp('_passwd')
      end
    end
  end
end