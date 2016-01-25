class Api::E1::BaseController < Api::BaseController

  self.responder = proc do |controller, resources, options|
    resource = resources.last
    request = controller.request
    if request.get?
      controller.render meta: { URI: request.url }, json: resource
    elsif request.post? or request.put?
      if resource.errors.any?
        render json: {:status => 'failed', :errors => resource.errors}
      else
        render json: {:status => 'created', :object => resource}
      end
    end
  end

end
