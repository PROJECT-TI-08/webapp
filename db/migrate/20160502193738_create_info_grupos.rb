class CreateInfoGrupos < ActiveRecord::Migration
  def change
    create_table :info_grupos do |t|
      t.string  :id_grupo
      t.string  :id_banco
      t.string  :id_almacen
      t.integer :numero
      t.timestamps null: false
    end
  end
end
