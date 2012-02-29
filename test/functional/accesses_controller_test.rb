require 'test_helper'

class AccessesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:accesses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create access" do
    assert_difference('Access.count') do
      post :create, :access => { }
    end

    assert_redirected_to access_path(assigns(:access))
  end

  test "should show access" do
    get :show, :id => accesses(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => accesses(:one).to_param
    assert_response :success
  end

  test "should update access" do
    put :update, :id => accesses(:one).to_param, :access => { }
    assert_redirected_to access_path(assigns(:access))
  end

  test "should destroy access" do
    assert_difference('Access.count', -1) do
      delete :destroy, :id => accesses(:one).to_param
    end

    assert_redirected_to accesses_path
  end
end
