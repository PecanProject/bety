require 'test_helper'

class PriorsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:priors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create prior" do
    assert_difference('Prior.count') do
      post :create, :prior => { }
    end

    assert_redirected_to prior_path(assigns(:prior))
  end

  test "should show prior" do
    get :show, :id => priors(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => priors(:one).to_param
    assert_response :success
  end

  test "should update prior" do
    put :update, :id => priors(:one).to_param, :prior => { }
    assert_redirected_to prior_path(assigns(:prior))
  end

  test "should destroy prior" do
    assert_difference('Prior.count', -1) do
      delete :destroy, :id => priors(:one).to_param
    end

    assert_redirected_to priors_path
  end
end
