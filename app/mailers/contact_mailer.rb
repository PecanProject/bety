class ContactMailer < ActionMailer::Base
  def contact_email(email_params)
    @email_body = email_params[:body]
    @sender_name = email_params[:name]
    mail(:to => CONFIG[:admin_email],
         :subject => email_params[:subject],
         :from => email_params[:name] + " <" + email_params[:address] + ">",
         :date => Time.now)
  end

  def feedback_email(email_params)
    @email_body = email_params[:feedback_text]
    @sender_name = email_params[:sender]
    @sender_email = email_params[:sender_email]
    @problem_location = email_params[:location]
    @type = email_params[:type]

    mail(:to => admins,
         :subject => "[BETY][#{@type}] #{email_params[:feedback_subject]}",
         :from => "#{@sender_name}<#{@sender_email}>",
         :date => Time.now)
  end

  def signup_email(user, url)
    @user = user
    @url = url

    email_from = "#{@user[:name]} <#{@user[:email]}>"

    email_to = admins
    email_to << email_from

    mail(:to => email_to,
         :from => email_from,
         :subject => "[BETY] New user signup",
         :date => Time.now)
  end

  def apikey_email(user)
    @user = user
    email_to = "#{@user[:name]} <#{@user[:email]}>"
    email_from = "BETYdb: <#{CONFIG[:admin_email]}>"

    mail(:to => email_to,
         :from => email_from,
         :subject => "[BETYdb] API key created",
         :date => Time.now)
  end

  def admin_approval(user, url)
    @user = user
    @url = url

    email_from = "#{@user[:name]} <#{@user[:email]}>"

    mail(:to => admins,
         :from => email_from,
         :subject => "[BETY] Access request",
         :date => Time.now)
  end



  private

  # Return a list of administrator e-mail address comprising all registered
  # users with page_access_level 1 together with the administration e-mail
  # address specified in the customization configuration file.
  def admins
    admins = User.where(page_access_level: 1).map! do |attributes|
      "#{attributes.name} < #{attributes.email}>"
    end
    admins << CONFIG[:admin_email]
    admins.uniq! # remove duplicates

    return admins
  end

end
