require 'test_helper'

class TraitDatasControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trait_datas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trait_data" do
    assert_difference('TraitData.count') do
      post :create, :trait_data => { }
    end

    assert_redirected_to trait_data_path(assigns(:trait_data))
  end

  test "should show trait_data" do
    get :show, :id => trait_datas(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => trait_datas(:one).to_param
    assert_response :success
  end

  test "should update trait_data" do
    put :update, :id => trait_datas(:one).to_param, :trait_data => { }
    assert_redirected_to trait_data_path(assigns(:trait_data))
  end

  test "should destroy trait_data" do
    assert_difference('TraitData.count', -1) do
      delete :destroy, :id => trait_datas(:one).to_param
    end

    assert_redirected_to trait_datas_path
  end
end
