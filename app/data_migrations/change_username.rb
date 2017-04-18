require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeUsername < MongoidMigrationTask
  def migrate
    old_user_oimid = ENV['old_user_oimid']
    new_user_oimid = ENV['new_user_oimid']
    user = User.where(oim_id:old_user_oimid).first
    if user.nil?
      puts "No user was found with given hbx_id"
    else
      user.update_attributes(oim_id:new_user_oimid)
      puts "update the user from #{old_user_oimid} to #{new_user_oimid}"
    end
  end
end
