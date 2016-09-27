Gemika::Database.new.rewrite_schema! do

  create_table :users do |t|
    t.string :name
    t.string :email
  end

end
