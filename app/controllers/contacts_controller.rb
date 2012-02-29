class ContactsController < ApplicationController

  layout 'application'

  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def send_mail
    Contact::deliver_contact_email(params[:email])
    respond_to do |format|
      format.html # index.html.erb
    end
  end

end
