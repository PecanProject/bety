require 'test_helper'

class LikelihoodsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:likelihoods)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create likelihood" do
    assert_difference('Likelihood.count') do
      post :create, :likelihood => { }
    end

    assert_redirected_to likelihood_path(assigns(:likelihood))
  end

  test "should show likelihood" do
    get :show, :id => likelihoods(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => likelihoods(:one).to_param
    assert_response :success
  end

  test "should update likelihood" do
    put :update, :id => likelihoods(:one).to_param, :likelihood => { }
    assert_redirected_to likelihood_path(assigns(:likelihood))
  end

  test "should destroy likelihood" do
    assert_difference('Likelihood.count', -1) do
      delete :destroy, :id => likelihoods(:one).to_param
    end

    assert_redirected_to likelihoods_path
  end
end
