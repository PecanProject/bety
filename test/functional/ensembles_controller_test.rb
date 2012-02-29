require 'test_helper'

class EnsemblesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ensembles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ensemble" do
    assert_difference('Ensemble.count') do
      post :create, :ensemble => { }
    end

    assert_redirected_to ensemble_path(assigns(:ensemble))
  end

  test "should show ensemble" do
    get :show, :id => ensembles(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => ensembles(:one).to_param
    assert_response :success
  end

  test "should update ensemble" do
    put :update, :id => ensembles(:one).to_param, :ensemble => { }
    assert_redirected_to ensemble_path(assigns(:ensemble))
  end

  test "should destroy ensemble" do
    assert_difference('Ensemble.count', -1) do
      delete :destroy, :id => ensembles(:one).to_param
    end

    assert_redirected_to ensembles_path
  end
end
