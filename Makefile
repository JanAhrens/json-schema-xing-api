all:
	@ruby validate.rb
	find test -name '*.rb' | while read file; do bundle exec ruby $$file; done

doc:
	bundle exec ruby render.rb schemas/users/show.json > doc.html
