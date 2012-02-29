require 'test_helper'

class CitationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:citations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create citation" do
    assert_difference('Citation.count') do
      post :create, :citation => { }
    end

    assert_redirected_to citation_path(assigns(:citation))
  end

  test "should show citation" do
    get :show, :id => citations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => citations(:one).to_param
    assert_response :success
  end

  test "should update citation" do
    put :update, :id => citations(:one).to_param, :citation => { }
    assert_redirected_to citation_path(assigns(:citation))
  end

  test "should destroy citation" do
    assert_difference('Citation.count', -1) do
      delete :destroy, :id => citations(:one).to_param
    end

    assert_redirected_to citations_path
  end
end
