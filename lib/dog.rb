class Dog
  attr_accessor :id, :name, :breed
  def initialize(id:nil, name:, breed:)
    self.id = id
    self.name = name
    self.breed = breed
  end

  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.create_table
    sql = <<-SQL
            create table if not exists #{self.table_name} (
                id Integer primary key,
                name text,
                breed text
            )
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<-SQL
                drop table if exists #{self.table_name}
    SQL

    DB[:conn].execute(sql)
  end

  def save
    if self.id
      self.update
    else
      sql = <<-SQL
        INSERT INTO #{self.class.table_name} (name, breed)
        VALUES (?, ?)
      SQL

      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.class.table_name}").flatten.first
    end
    self
  end

  def self.create(dog_ash)
    #tdog = DB[:conn].execute("Select * from #{self.table_name} WHERE name = ? and breed = ?")
    tdog = self.new(dog_ash)
    tdog.save
  end

  def self.new_from_db(row)
    self.new(id: row[0], name: row[1], breed:row[2])
  end

  def self.find_by_id(id)
    sql = <<-SQL
        select * from #{self.table_name} where id = ?
    SQL

    DB[:conn].execute(sql, id).map do |d|
      self.new_from_db(d)
    end.first
  end

  def self.find_by_name(name)
    sql = <<-SQL
        select * from #{self.table_name} where name = ?
    SQL

    DB[:conn].execute(sql, name).map do |d|
      self.new_from_db(d)
    end.first
  end

  def self.find_or_create_by(name:, breed:)
    tdog = DB[:conn].execute("Select * from #{self.table_name} WHERE name = ? and breed = ?", name, breed)
    if !tdog.empty?
      tdog_r = tdog.first
      tdog = self.new(id:tdog_r[0], name:tdog_r[1], breed:tdog_r[2])
    else
      tdog = self.create(name: name, breed: breed)
    end
    tdog
  end

  def update
    sql = <<-SQL
              update #{self.class.table_name} set name = ?, breed = ? where id = ?
    SQL

    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end
end
