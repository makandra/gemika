All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

### Breaking changes

-

### Compatible changes

- Move gemfiles to project root
- Added support to read the `include` option from the `travis.yml` file.

  Example:

  ```
  rvm:
    - 2.1.8
    - 2.3.1

  gemfile:
    - gemfiles/Gemfile1
    - gemfiles/Gemfile2

  matrix:
    include:
      - rvm: 2.1.8
        gemfile: gemfiles/Gemfile1
      - rvm: 2.3.1
        gemfile: gemfiles/Gemfile2
  ```

## 0.3.4 - 2018-08-29

### Compatible changes

- Print a warning instead of crashing when `database.yml` is missing.


## 0.3.3 - 2018-08-01

### Compatible changes

- Add support for sqlite3.


## 0.3.2 - 2016-09-28

### Compatible changes

- Remove some debug output.


## 0.3.1 - 2016-09-28

### Compatible changes

- `rake current_rspec` no longer does a second unnecessary `bundle exec` call


## Older releases

Please check commits.
