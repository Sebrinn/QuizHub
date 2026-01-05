# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# db/seeds.rb
puts "=== Tworzenie użytkownika admina ==="

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@quizhub.pl')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'Admin123!')

admin = User.find_by(email: admin_email)

if admin
  puts "Admin już istnieje: #{admin.email}"
  puts "  Aktualizowanie danych..."

  update_data = {
    first_name: 'Admin',
    last_name: 'System',
    role: 2,
    password: admin_password,
    password_confirmation: admin_password,
    confirmed_at: Time.current
  }

  admin.assign_attributes(update_data)

  if admin.save
    puts "Admin zaktualizowany"
  else
    puts "Błąd aktualizacji admina: #{admin.errors.full_messages.join(', ')}"
  end
else
  puts "Tworzenie nowego admina..."

  admin = User.new(
    email: admin_email,
    password: admin_password,
    password_confirmation: admin_password,
    first_name: 'Admin',
    last_name: 'System',
    role: 2,
    confirmed_at: Time.current
  )

  if admin.save
    puts "Admin utworzony: #{admin.email}"
    puts "  Imię: #{admin.first_name} #{admin.last_name}"
    puts "  Rola: #{admin.role}"
  else
    puts "Błąd tworzenia admina: #{admin.errors.full_messages.join(', ')}"
  end
end

puts "=== Seed ukończony ==="
