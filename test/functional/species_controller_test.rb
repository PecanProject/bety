require 'test_helper'

class SpeciesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:species)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create specie" do
    assert_difference('Specie.count') do
      post :create, :specie => { }
    end

    assert_redirected_to specie_path(assigns(:specie))
  end

  test "should show specie" do
    get :show, :id => species(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => species(:one).to_param
    assert_response :success
  end

  test "should update specie" do
    put :update, :id => species(:one).to_param, :specie => { }
    assert_redirected_to specie_path(assigns(:specie))
  end

  test "should destroy specie" do
    assert_difference('Specie.count', -1) do
      delete :destroy, :id => species(:one).to_param
    end

    assert_redirected_to species_path
  end
end
