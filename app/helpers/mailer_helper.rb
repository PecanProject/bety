module MailerHelper
  def user_name_or_login(user)
	user[:name].blank? ? user[:login] : user[:name]
  end	
end
