class FeedbackController < ApplicationController
  def feedback_email
    ContactMailer::feedback_email(params[:feedback_email]).deliver
      respond_to do |format|
        format.js {render :layout =>false}
      end
    end
end
