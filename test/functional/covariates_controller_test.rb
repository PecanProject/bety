require 'test_helper'

class CovariatesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:covariates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create covariate" do
    assert_difference('Covariate.count') do
      post :create, :covariate => { }
    end

    assert_redirected_to covariate_path(assigns(:covariate))
  end

  test "should show covariate" do
    get :show, :id => covariates(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => covariates(:one).to_param
    assert_response :success
  end

  test "should update covariate" do
    put :update, :id => covariates(:one).to_param, :covariate => { }
    assert_redirected_to covariate_path(assigns(:covariate))
  end

  test "should destroy covariate" do
    assert_difference('Covariate.count', -1) do
      delete :destroy, :id => covariates(:one).to_param
    end

    assert_redirected_to covariates_path
  end
end
