require 'test_helper'

class CitationsSitesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:citations_sites)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create citations_site" do
    assert_difference('CitationsSite.count') do
      post :create, :citations_site => { }
    end

    assert_redirected_to citations_site_path(assigns(:citations_site))
  end

  test "should show citations_site" do
    get :show, :id => citations_sites(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => citations_sites(:one).to_param
    assert_response :success
  end

  test "should update citations_site" do
    put :update, :id => citations_sites(:one).to_param, :citations_site => { }
    assert_redirected_to citations_site_path(assigns(:citations_site))
  end

  test "should destroy citations_site" do
    assert_difference('CitationsSite.count', -1) do
      delete :destroy, :id => citations_sites(:one).to_param
    end

    assert_redirected_to citations_sites_path
  end
end
