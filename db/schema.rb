# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160502193738) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "formulas", id: false, force: :cascade do |t|
    t.string   "sku_parent"
    t.string   "sku_child"
    t.integer  "requerimiento"
    t.float    "precio"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "formulas", ["sku_parent", "sku_child"], name: "index_formulas_on_sku_parent_and_sku_child", unique: true, using: :btree

  create_table "info_grupos", force: :cascade do |t|
    t.string   "id_grupo"
    t.string   "id_banco"
    t.string   "id_almacen"
    t.integer  "numero"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "order_ftps", force: :cascade do |t|
    t.string   "file_name"
    t.string   "order_id"
    t.integer  "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.string   "_id",                             null: false
    t.string   "canal",                           null: false
    t.string   "proveedor",                       null: false
    t.string   "cliente",                         null: false
    t.integer  "sku",                             null: false
    t.integer  "cantidad",                        null: false
    t.integer  "cantidadDespachada",              null: false
    t.integer  "precioUnitario",                  null: false
    t.datetime "fechaEntrega",                    null: false
    t.datetime "fechaDespachos",     default: [],              array: true
    t.string   "estado",                          null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "product_stores", id: false, force: :cascade do |t|
    t.integer  "product_id"
    t.integer  "store_id"
    t.integer  "qty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "product_stores", ["product_id", "store_id"], name: "index_product_stores_on_product_id_and_store_id", unique: true, using: :btree
  add_index "product_stores", ["product_id"], name: "index_product_stores_on_product_id", using: :btree
  add_index "product_stores", ["store_id"], name: "index_product_stores_on_store_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "sku"
    t.string   "nombre"
    t.string   "unidades"
    t.float    "costo_produccion_unitario"
    t.float    "lote_produccion"
    t.float    "tiempo_medio_produccion"
    t.float    "precio_unitario"
    t.string   "tipo"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "stores", force: :cascade do |t|
    t.string   "_id"
    t.boolean  "pulmon"
    t.boolean  "despacho"
    t.boolean  "recepcion"
    t.integer  "totalSpace"
    t.integer  "usedSpace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.boolean  "admin",                  default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  add_foreign_key "product_stores", "products"
  add_foreign_key "product_stores", "stores"
end
