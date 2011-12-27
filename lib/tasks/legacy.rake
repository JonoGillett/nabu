namespace :import do

  desc 'Load database from old PARADISEC system'
  task :load_db do
    system 'echo "DROP DATABASE paradisec_legacy" | mysql -u root'
    system 'echo "CREATE DATABASE paradisec_legacy" | mysql -u root'
    system "mysql -u root paradisec_legacy < #{Rails.root}/db/legacy/paradisecDump.sql"
  end

  desc 'Import users into NABU from paradisec_legacy DB'
  task :users => :environment do
    require 'mysql2'
    client = Mysql2::Client.new(:host => "localhost", :username => "root")
    client.query("use paradisec_legacy")
    users = client.query("SELECT * FROM users")
    users.each do |user|
      next if user['usr_deleted'] == 1
      first_name, last_name = user['usr_realname'].split(/ /)
      if last_name.blank?
        first_name, last_name = user['usr_realname'].split(/./)
      end
      if last_name.blank?
        first_name = user['usr_realname']
        last_name = 'unknown'
      end
      access = user['usr_access'] == 'administrator' ? true : false
      email = user['usr_email']
      if email.blank?
        email = user['usr_id'].to_s+'@example.com'
      end
      password = 'asdfgj'
      new_user = User.new :first_name => first_name,
                          :last_name => last_name,
                          :email => email,
                          :password => password,
                          :password_confirmation => password
      new_user.admin = access
      if !new_user.valid?
        puts "Error parsing User #{user['usr_id']}"
      end
      new_user.save!
    end
  end

  desc 'Import contacts into NABU from paradisec_legacy DB (do users first)'
  task :contacts => :environment do
    require 'mysql2'
    client = Mysql2::Client.new(:host => "localhost", :username => "root")
    client.query("use paradisec_legacy")
    users = client.query("SELECT * FROM contacts")
    users.each do |user|
      next if user['cont_collector'].blank? && user['cont_collector_surname'].blank?
      last_name, first_name = user['cont_collector'].split(/, /)
      if first_name.blank?
        first_name, last_name = user['cont_collector'].split(/ /)
      end
      if last_name.blank?
        first_name = user['cont_collector']
        last_name = user['cont_collector_surname']
      end
      if user['cont_email']
        email = user['cont_email'].split(/ /)[0]
      end
      if email.blank?
        email = user['cont_id'].to_s + 'cont@example.com'
      end
      address = user['cont_address1']
      if user['cont_address1'] && user['cont_address2']
        address = user['cont_address1'] + ',' + user['cont_address2']
      end

      # identify if this user already exists in DB
      cur_user = User.first(:conditions => ["first_name = ? AND last_name = ?", first_name, last_name])
      if cur_user
        cur_user.email = email
        cur_user.address = address
        cur_user.country = user['cont_country']
        cur_user.phone = user['cont_phone']
        cur_user.save!
        puts "saved existing user " + cur_user.email
      else
        password = 'asdfgj'
        new_user = User.new :first_name => first_name,
                            :last_name => last_name,
                            :email => email,
                            :password => password,
                            :password_confirmation => password,
                            :address => address,
                            :country => user['cont_country'],
                            :phone => user['cont_phone']
        new_user.admin = false
        if !new_user.valid?
          puts "Error parsing contact #{user['cont_id']}"
          puts first_name + " " + last_name
        end
        new_user.save!
        puts "saved new user " + new_user.email
      end
    end
  end

  desc 'Import universities into NABU from paradisec_legacy DB'
  task :universities => :environment do
    require 'mysql2'
    client = Mysql2::Client.new(:host => "localhost", :username => "root")
    client.query("use paradisec_legacy")
    universities = client.query("SELECT * FROM universities")
    universities.each do |uni|
      next if uni['uni_description'].empty?
      new_uni = University.new :name => uni['uni_description']
      new_uni.save!
    end
  end

  desc 'Import countries into NABU from ethnologue DB'
  task :countries => :environment do
    require 'iconv'
    data = File.open("#{Rails.root}/data/CountryCodes.tab", "rb").read
    data = Iconv.iconv('UTF8', 'ISO-8859-1', data).first.force_encoding('UTF-8')
    data.each_line do |line|
      next if line =~ /^CountryID/
      code, name, area = line.split("\t")
      Country.create! :name => name
    end
  end

  desc 'Import languages into NABU from ethnologue DB'
  task :languages => :environment do
    require 'iconv'
    data = File.open("#{Rails.root}/data/LanguageIndex.tab", "rb").read
    data = Iconv.iconv('UTF8', 'ISO-8859-1', data).first.force_encoding('UTF-8')
    data.each_line do |line|
      next if line =~ /^LangID/
        code, country_code, name_type, name = line.strip.split("\t")
      next unless name_type == "L"
      Language.create! :code => code, :name => name
    end
  end

  desc 'Import discourse_types into NABU from paradisec_legacy DB'
  task :discourse_types => :environment do
    require 'mysql2'
    client = Mysql2::Client.new(:host => "localhost", :username => "root")
    client.query("use paradisec_legacy")
    discourses = client.query("SELECT * FROM discourse_types")
    discourses.each do |discourse|
      disc_type = DiscourseType.new :name => discourse['dt_name']
      disc_type.save!
    end
  end

  desc 'Import fields_of_research into NABU from ANDS DB'
  task :fields_of_research => :environment do
    require 'iconv'
    data = File.open("#{Rails.root}/data/ANDS_RFCD.txt", "rb").read
    data = Iconv.iconv('UTF8', 'ISO-8859-1', data).first.force_encoding('UTF-8')
    data.each_line do |line|
      id, name = line.split("-")
      id.strip!
      name.strip!
      FieldOfResearch.create! :identifier => id, :name => name
    end
  end


# - import collection
# - import items
# - import content essences
end