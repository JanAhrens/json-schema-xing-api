all:
	@ruby validate.rb

doc:
	bundle exec ruby render.rb schemas/users/show.json > doc.html
