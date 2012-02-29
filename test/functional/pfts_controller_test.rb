require 'test_helper'

class PftsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pfts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pft" do
    assert_difference('Pft.count') do
      post :create, :pft => { }
    end

    assert_redirected_to pft_path(assigns(:pft))
  end

  test "should show pft" do
    get :show, :id => pfts(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => pfts(:one).to_param
    assert_response :success
  end

  test "should update pft" do
    put :update, :id => pfts(:one).to_param, :pft => { }
    assert_redirected_to pft_path(assigns(:pft))
  end

  test "should destroy pft" do
    assert_difference('Pft.count', -1) do
      delete :destroy, :id => pfts(:one).to_param
    end

    assert_redirected_to pfts_path
  end
end
