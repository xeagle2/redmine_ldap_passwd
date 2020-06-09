class AuthSourceLdapPasswd < AuthSourceLdap
  def allow_password_changes?
    self.tls
  end

  def change_user_password(user, password, new_password)
    return false unless AuthSourceLdapPasswd.change_password_allowed?(user)

    attrs = get_user_dn(user.login, password)
    if attrs && attrs[:dn]
      defaults = Redmine::Plugin::registered_plugins[:redmine_ldap_passwd].settings[:default]
      suua = Setting.plugin_redmine_ldap_passwd[:use_user_account].nil? ? defaults[:use_user_account] : Setting.plugin_redmine_ldap_passwd[:use_user_account]
      if suua || ( self.account && self.account.include?("$login") )
        ldap_con = initialize_ldap_con(suua ? Net::LDAP::DN.escape(user.login) : self.account.sub("$login", Net::LDAP::DN.escape(user.login)), password)
      else
        ldap_con = initialize_ldap_con(self.account, self.account_password)
      end

      ops = [[:replace, :unicodePwd, AuthSourceLdapPasswd.str2unicodePwd(new_password)]]
      ldap_con.modify :dn => attrs[:dn], :operations => ops

      result = ldap_con.get_operation_result
      if result.code == 0
        user.passwd_changed_on = Time.now.change(:usec => 0)
        user.save

        return true
      else
        Rails.logger.info "Change password problem: #{result}."
        return result
      end
    end

    false
  end

  def self.str2unicodePwd(str)
    ('"' + str + '"').encode("utf-16le").force_encoding("utf-8")
  end

  def self.change_password_allowed?(user)
    return false if user.nil?
    AuthSourceLdapPasswd.name.eql?(user.auth_source.type)
  end

  def self.is_password_valid(password)
    return false if password.nil? || password.length < 7

    s = 0
    contains = [
        password.match(/\p{Lower}/) ? 1 : 0,
        password.match(/\p{Upper}/) ? 1 : 0,
        password.match(/\p{Digit}/) ? 1 : 0,
        password.match(/[^\\w\\d]+/) ? 1 : 0
    ]
    contains.each { |a| s += a }

    return s >= 3
  end
end
