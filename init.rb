require 'redmine'

require_dependency 'redmine_ldap_passwd_my_controller_patch'
require_dependency 'redmine_ldap_passwd_auth_sources_helper_patch'
require_dependency 'redmine_ldap_passwd_account_controller_patch'

Redmine::Plugin.register :redmine_ldap_passwd do
  name 'Redmine LDAP Change Password'
  author 'Yura Zaplavnov'
  description 'The plugin extends AuthSourceLdap to introduce the ability to recover or change user password.'
  version '3.0.1'
  url 'https://github.com/xeagle2/redmine_ldap_passwd'
  author_url 'https://github.com/xeagle2'
end

require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

if Rails::VERSION::MAJOR >= 5
  ActiveSupport::Reloader.to_prepare do
    MyController.send(:include, RedmineLdapPasswd::MyControllerPatch)
    AuthSourcesHelper.send(:include, RedmineLdapPasswd::AuthSourcesHelperPatch)
    AccountController.send(:include, RedmineLdapPasswd::AccountControllerPatch)
  end
elsif Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    MyController.send(:include, RedmineLdapPasswd::MyControllerPatch)
    AuthSourcesHelper.send(:include, RedmineLdapPasswd::AuthSourcesHelperPatch)
    AccountController.send(:include, RedmineLdapPasswd::AccountControllerPatch)
  end
else
  Dispatcher.to_prepare do
    MyController.send(:include, RedmineLdapPasswd::MyControllerPatch)
    AuthSourcesHelper.send(:include, RedmineLdapPasswd::AuthSourcesHelperPatch)
    AccountController.send(:include, RedmineLdapPasswd::AccountControllerPatch)
  end
end