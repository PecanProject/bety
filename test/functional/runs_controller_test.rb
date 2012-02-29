require 'test_helper'

class RunsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:runs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create run" do
    assert_difference('Run.count') do
      post :create, :run => { }
    end

    assert_redirected_to run_path(assigns(:run))
  end

  test "should show run" do
    get :show, :id => runs(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => runs(:one).to_param
    assert_response :success
  end

  test "should update run" do
    put :update, :id => runs(:one).to_param, :run => { }
    assert_redirected_to run_path(assigns(:run))
  end

  test "should destroy run" do
    assert_difference('Run.count', -1) do
      delete :destroy, :id => runs(:one).to_param
    end

    assert_redirected_to runs_path
  end
end
