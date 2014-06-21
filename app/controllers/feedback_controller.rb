class FeedbackController < ApplicationController
	def feedback_email
		#ContactMailer::feedback_email(params[:feedback_email]).deliver
    	#`echo "rails email test" | mail -s test_email sourgrapes612@hotmail.com`
		respond_to do |format|
			format.js {render :layout =>false}
		end
	end
end
