class Admin::UsersController < ApplicationController
  before_action :authenticate_user!

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @users = policy_scope(User).order(created_at: :desc)
    authorize @users
  end

  def promote_to_teacher
    user = User.find(params[:id])
    authorize user
    user.update(role: :teacher)
    redirect_to admin_users_path, notice: "Użytkownik został awansowany na nauczyciela"
  end

  def demote_to_student
    user = User.find(params[:id])
    authorize user
    user.update(role: :student)
    redirect_to admin_users_path, notice: "Użytkownik został zmieniony na ucznia"
  end
end
