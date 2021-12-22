All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

### Breaking changes

- Remove no longer supported ruby versions (2.3.8)

### Compatible changes

- test against ActiveRecord 7.0

## 0.6.1 - 2021-04-20

### Compatible changes

- fix deprecation warning for Bundler.with_clean_env on Bundler >= 2

## 0.6.0 - 2021-04-20

### Compatible changes

- add Ruby 3 compatibility
- drop Ruby 2.2 support

## 0.5.0 - 2020-10-09

### Compatible changes

- add support for github actions instead of travis
- add method to migrate travis to github actions workflow

## 0.4.0 - 2019-08-07

### Compatible changes

- Move gemfiles to project root
- Added support to read the `include` option from the `travis.yml` file. All combinations defined in the include option
  are added to the existing matrix. If no matrix exist, these are the only ones that are run.

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
      - rvm: 2.6.3
        gemfile: gemfiles/Gemfile3
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
