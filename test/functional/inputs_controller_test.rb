require 'test_helper'

class InputsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:inputs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create input" do
    assert_difference('Input.count') do
      post :create, :input => { }
    end

    assert_redirected_to input_path(assigns(:input))
  end

  test "should show input" do
    get :show, :id => inputs(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => inputs(:one).to_param
    assert_response :success
  end

  test "should update input" do
    put :update, :id => inputs(:one).to_param, :input => { }
    assert_redirected_to input_path(assigns(:input))
  end

  test "should destroy input" do
    assert_difference('Input.count', -1) do
      delete :destroy, :id => inputs(:one).to_param
    end

    assert_redirected_to inputs_path
  end
end
