# frozen_string_literal: true

Fabricator(:user_role) do
  name        'MyString'
  color       ''
  permissions 0
end

Fabricator(:moderator_role, :from => :user_role) do
  name 'fake moderator'
  permissions UserRole::Flags::DEFAULT |
    UserRole::Flags::CATEGORIES[:moderation]
    .map { |p| UserRole::FLAGS[p] }
    .reduce(&:|)
end
