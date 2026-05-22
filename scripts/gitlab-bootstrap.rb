# Ensures a root admin exists and mints an api-scoped PAT for Terraform.
# Run inside the GitLab container: gitlab-rails runner /tmp/gitlab-bootstrap.rb
# Expects PW env var (root password). Prints ONLY the token on stdout.
pw = ENV['PW']

u = User.find_by_username('root')
if u.nil?
  u = User.new(
    username: 'root',
    email: 'admin@lab.local',
    name: 'Administrator',
    password: pw,
    password_confirmation: pw,
  )
  u.admin = true
  u.skip_confirmation!

  # GitLab 17 ties the personal namespace to an Organization.
  if u.respond_to?(:assign_personal_namespace)
    org = if defined?(Organizations::Organization)
            Organizations::Organization.respond_to?(:default_org) ? Organizations::Organization.default_org : Organizations::Organization.first
          end
    org ? u.assign_personal_namespace(org) : u.assign_personal_namespace
  end

  u.save!
  STDERR.puts 'created root user'
end

# no forced password change on first web login
u.update_column(:password_expires_at, nil)

u.personal_access_tokens.where(name: 'tf-bootstrap', revoked: false).each(&:revoke!)
t = u.personal_access_tokens.create!(
  name: 'tf-bootstrap',
  scopes: ['api'],
  expires_at: 30.days.from_now,
)
puts t.token
