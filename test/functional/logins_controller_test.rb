require 'test_helper'

class LoginsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:logins)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create login" do
    assert_difference('Login.count') do
      post :create, :login => { }
    end

    assert_redirected_to login_path(assigns(:login))
  end

  test "should show login" do
    get :show, :id => logins(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => logins(:one).to_param
    assert_response :success
  end

  test "should update login" do
    put :update, :id => logins(:one).to_param, :login => { }
    assert_redirected_to login_path(assigns(:login))
  end

  test "should destroy login" do
    assert_difference('Login.count', -1) do
      delete :destroy, :id => logins(:one).to_param
    end

    assert_redirected_to logins_path
  end
end
