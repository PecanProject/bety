require 'test_helper'

class YieldsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:yields)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create yield" do
    assert_difference('Yield.count') do
      post :create, :yield => { }
    end

    assert_redirected_to yield_path(assigns(:yield))
  end

  test "should show yield" do
    get :show, :id => yields(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => yields(:one).to_param
    assert_response :success
  end

  test "should update yield" do
    put :update, :id => yields(:one).to_param, :yield => { }
    assert_redirected_to yield_path(assigns(:yield))
  end

  test "should destroy yield" do
    assert_difference('Yield.count', -1) do
      delete :destroy, :id => yields(:one).to_param
    end

    assert_redirected_to yields_path
  end
end
