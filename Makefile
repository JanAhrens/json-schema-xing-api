all:
	@ruby validate.rb

doc:
	bundle exec ruby render.rb > doc.html
