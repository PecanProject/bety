require 'test_helper'

class TraitsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:traits)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trait" do
    assert_difference('Trait.count') do
      post :create, :trait => { }
    end

    assert_redirected_to trait_path(assigns(:trait))
  end

  test "should show trait" do
    get :show, :id => traits(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => traits(:one).to_param
    assert_response :success
  end

  test "should update trait" do
    put :update, :id => traits(:one).to_param, :trait => { }
    assert_redirected_to trait_path(assigns(:trait))
  end

  test "should destroy trait" do
    assert_difference('Trait.count', -1) do
      delete :destroy, :id => traits(:one).to_param
    end

    assert_redirected_to traits_path
  end
end
