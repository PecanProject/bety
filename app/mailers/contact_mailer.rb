class ContactMailer < ActionMailer::Base
  def contact_email(email_params)
    @email_body = email_params[:body]
    @sender_name = email_params[:name]
    mail(:to => "betydb@gmail.com",
         :subject => email_params[:subject],
         :from => email_params[:name] + " <" + email_params[:address] + ">",
         :date => Time.now)
  end
end
