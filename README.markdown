This repository aims to contain a complete [JSON schema](http://json-schema.org) definition of
the [XING API](https://dev.xing.com/docs/resources), along with test-data.

The schema files can be checked against the fixture files by executing
the `validation.rb` file. It has some dependencies, that can be
installed by running [Bundler](http://bundler.io/).  There is a Makefile that automates
this.

    bundle install
    make

The this repository is heavily inspired by the
[Balanced API Specification repository](https://github.com/balanced/balanced-api). Thank
you for providing such an inspiring resource publicly!

# Resources

* [Understanding JSON Schema](https://spacetelescope.github.io/understanding-json-schema)
* [draft-zyp-json-schema-04](http://tools.ietf.org/id/draft-zyp-json-schema-04.txt)
* [draft-fge-json-schema-validation-00](http://tools.ietf.org/id/draft-fge-json-schema-validation-00.txt)
* [json-schema.org](http://json-schema.org/)
