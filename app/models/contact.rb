class Contact < ActionMailer::Base
  def contact_email(email_params)
    email_params[:to_address] = "betydb@gmail.com" if email_params[:to_address].nil?
    @recipients = email_params[:to_address] 
    @from = email_params[:name] + " <" + email_params[:address] + ">"
    @subject = email_params[:subject]
    @sent_on = Time.now
    @body["email_body"] = email_params[:body]
    @body["email_name"] = email_params[:name]
    content_type "text/html"
  end
end
