class BotFlowPolicy < ApplicationPolicy
  def index?
    account_user.administrator?
  end

  def show?
    account_user.administrator?
  end

  def create?
    account_user.administrator?
  end

  def update?
    account_user.administrator?
  end

  def publish?
    account_user.administrator?
  end

  def unpublish?
    update?
  end

  def executions?
    show?
  end

  def retry_delivery?
    update?
  end

  def destroy?
    account_user.administrator?
  end
end
