class EnablePostGisExension < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'postgis'
  end
end
