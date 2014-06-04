class ContactMailer < ActionMailer::Base
  def contact_email(email_params)
    @email_body = email_params[:body]
    @sender_name = email_params[:name]
    mail(:to => "betydb@gmail.com",
         :subject => email_params[:subject],
         :from => email_params[:name] + " <" + email_params[:address] + ">",
         :date => Time.now)
  end

  def signup_email(user)
  	@user = user
  	@url = root_path

  	email_from = "#{@user[:name]} <#{@user[:email]}>"
	email_to = User.where(page_access_level: 1).map! do |attributes|
		"#{attributes.name} < #{attributes.email}>"
	end
	email_to << email_from

    mail(:to => email_to,
         :from => email_from,
         :subject => "[BETY] New user signup",
         :date => Time.now)
  end

  def admin_approval(user)
  	@user = user
  	@url = root_path

  	email_from = "#{@user[:name]} <#{@user[:email]}>"
	email_to = User.where(page_access_level: 1).map! do |attributes|
		"#{attributes.name} < #{attributes.email}>"
	end

    mail(:to => email_to,
         :from => email_from,
         :subject => "[BETY] Access request",
         :date => Time.now)
  end
end
