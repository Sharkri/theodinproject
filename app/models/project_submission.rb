class ProjectSubmission < ApplicationRecord
  include Discard::Model

  before_update do
    self.discard_at = nil if repo_url_changed? || live_preview_url_changed?
  end

  acts_as_votable

  belongs_to :user
  belongs_to :lesson
  has_many :flags, dependent: :destroy

  validates :repo_url, url: true
  validates :live_preview_url, url: true, allow_blank: true
  validate :live_preview_allowed
  validates :repo_url, presence: { message: 'Required' }
  validates :user_id, uniqueness: { scope: :lesson_id, message: 'You have already submitted a project for this lesson' }

  scope :only_public, -> { where(is_public: true, discarded_at: nil) }
  scope :not_removed_by_admin, -> { where(discarded_at: nil) }
  scope :created_today, -> { where('created_at >= ?', Time.zone.now.beginning_of_day) }
  scope :discardable, -> { not_removed_by_admin.where(discard_at: ..Time.zone.now) }

  attribute :liked, :boolean, default: false

  def like!(user = nil)
    liked_by(user) if user

    self.liked = true
  end

  def unlike!(user = nil)
    unliked_by(user) if user

    self.liked = false
  end

  private

  def live_preview_allowed
    return if live_preview_url.blank?

    unless lesson && lesson.has_live_preview?
      errors.add(:live_preview_url, 'Live preview is not allowed for this project')
    end
  end
end
