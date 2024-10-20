json.extract! post, :id, :title, :content, :thumbnail_url, :background_url, :author_id, :category_id, :created_at, :updated_at
json.url post_url(post, format: :json)
