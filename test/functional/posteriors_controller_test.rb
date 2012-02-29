require 'test_helper'

class PosteriorsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:posteriors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create posterior" do
    assert_difference('Posterior.count') do
      post :create, :posterior => { }
    end

    assert_redirected_to posterior_path(assigns(:posterior))
  end

  test "should show posterior" do
    get :show, :id => posteriors(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => posteriors(:one).to_param
    assert_response :success
  end

  test "should update posterior" do
    put :update, :id => posteriors(:one).to_param, :posterior => { }
    assert_redirected_to posterior_path(assigns(:posterior))
  end

  test "should destroy posterior" do
    assert_difference('Posterior.count', -1) do
      delete :destroy, :id => posteriors(:one).to_param
    end

    assert_redirected_to posteriors_path
  end
end
