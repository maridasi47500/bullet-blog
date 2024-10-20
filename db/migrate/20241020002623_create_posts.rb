class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :content
      t.string :thumbnail_url
      t.string :background_url
      t.integer :author_id
      t.integer :category_id

      t.timestamps
    end
  end
end
