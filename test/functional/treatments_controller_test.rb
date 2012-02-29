require 'test_helper'

class TreatmentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:treatments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create treatment" do
    assert_difference('Treatment.count') do
      post :create, :treatment => { }
    end

    assert_redirected_to treatment_path(assigns(:treatment))
  end

  test "should show treatment" do
    get :show, :id => treatments(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => treatments(:one).to_param
    assert_response :success
  end

  test "should update treatment" do
    put :update, :id => treatments(:one).to_param, :treatment => { }
    assert_redirected_to treatment_path(assigns(:treatment))
  end

  test "should destroy treatment" do
    assert_difference('Treatment.count', -1) do
      delete :destroy, :id => treatments(:one).to_param
    end

    assert_redirected_to treatments_path
  end
end
