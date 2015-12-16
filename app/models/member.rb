# Organisation member
class Member < ActiveRecord::Base
  belongs_to :user
  acts_as_tenant

  DEFAULT_ADMIN = {
    first_name: 'Organisation',
    last_name:  'Admin'
  }

  def self.create_new_member(user, params)
    # add any other initialization for a new member
    user.create_member(params)
  end

  def self.create_org_admin(user)
    new_member = create_new_member(user, DEFAULT_ADMIN)
    if new_member.errors.any?
      fail ArgumentError, new_member.errors.full_messages.uniq.join(', ')
    end

    new_member
  end
end
