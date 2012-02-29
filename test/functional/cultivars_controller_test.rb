require 'test_helper'

class CultivarsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cultivars)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create cultivar" do
    assert_difference('Cultivar.count') do
      post :create, :cultivar => { }
    end

    assert_redirected_to cultivar_path(assigns(:cultivar))
  end

  test "should show cultivar" do
    get :show, :id => cultivars(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => cultivars(:one).to_param
    assert_response :success
  end

  test "should update cultivar" do
    put :update, :id => cultivars(:one).to_param, :cultivar => { }
    assert_redirected_to cultivar_path(assigns(:cultivar))
  end

  test "should destroy cultivar" do
    assert_difference('Cultivar.count', -1) do
      delete :destroy, :id => cultivars(:one).to_param
    end

    assert_redirected_to cultivars_path
  end
end
