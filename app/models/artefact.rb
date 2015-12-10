class Artefact < ActiveRecord::Base
  before_save :upload_to_s3

  attr_accessor :upload

  belongs_to :project

  MAX_FILE_MB   = 10
  MAX_FILE_SIZE = MAX_FILE_MB.megabytes

  validates_presence_of :name, :upload
  validates_uniqueness_of :name

  validate :uploaded_file_size

  private

  def upload_to_s3
    s3 = Aws::S3::Resource.new(region: ENV['S3_REGION'])
    tenant_name = Tenant.find(Thread.current[:tenant_id]).name
    obj = s3.bucket(ENV['S3_BUCKET']).object("#{tenant_name}/#{upload.original_filename}")
    obj.upload_file(upload.path, acl: 'public-read')
    self.key = obj.public_url
  end

  def uploaded_file_size
    if upload && upload.size >= self.class::MAX_FILE_SIZE
      errors.add(:upload, "File must be less than #{self.class::MAX_FILE_MB}MB")
    end
  end
end
