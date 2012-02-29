require 'test_helper'

class TestCasesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:test_cases)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create test_case" do
    assert_difference('TestCase.count') do
      post :create, :test_case => { }
    end

    assert_redirected_to test_case_path(assigns(:test_case))
  end

  test "should show test_case" do
    get :show, :id => test_cases(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => test_cases(:one).to_param
    assert_response :success
  end

  test "should update test_case" do
    put :update, :id => test_cases(:one).to_param, :test_case => { }
    assert_redirected_to test_case_path(assigns(:test_case))
  end

  test "should destroy test_case" do
    assert_difference('TestCase.count', -1) do
      delete :destroy, :id => test_cases(:one).to_param
    end

    assert_redirected_to test_cases_path
  end
end
