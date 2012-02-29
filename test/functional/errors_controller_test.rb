require 'test_helper'

class ErrorsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:errors)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create error" do
    assert_difference('Error.count') do
      post :create, :error => { }
    end

    assert_redirected_to error_path(assigns(:error))
  end

  test "should show error" do
    get :show, :id => errors(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => errors(:one).to_param
    assert_response :success
  end

  test "should update error" do
    put :update, :id => errors(:one).to_param, :error => { }
    assert_redirected_to error_path(assigns(:error))
  end

  test "should destroy error" do
    assert_difference('Error.count', -1) do
      delete :destroy, :id => errors(:one).to_param
    end

    assert_redirected_to errors_path
  end
end
