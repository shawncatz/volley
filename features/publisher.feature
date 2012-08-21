
# Built these tests as a starting point
# duplicates some of the tests in spec/publisher_spec
Feature: Publisher
  In order to store artifacts
  I want to be able to manage files with a publisher

  Background:
    Given I have a publisher with an empty repository

  Scenario: Empty publisher
    When I request a list of projects from the publisher
    Then I should see an empty list

  Scenario: Publish multiple artifacts
    When I publish the artifact test/trunk/1
    Then there should be 1 projects in the publisher
    And the test project should have 1 branches
    When I publish the artifact test/staging/2
    Then there should be 1 projects in the publisher
    And the test project should have 2 branches

  Scenario: Publish and retrieve artifact
    When I publish the artifact test/trunk/1
    Then there should be 1 projects in the publisher
    And the test project should have 1 branches
    When I deploy the artifact test/trunk/1
    Then I should not receive an exception

  Scenario: Latest artifacts
    Given I have a populated repository
    Then the test project should have 3 branches
    And the latest of test/trunk should be 7
    And the latest of test/staging should be 5

  Scenario: Duplicate Artifact
    Given I have a populated repository
    When I publish a duplicate artifact test/staging/12
    Then I should not receive an exception

# TODO: make this work
#  Scenario: Duplicate Artifact force
#    Given I have a populated repository
#    When I force publish a duplicate artifact test/staging/12
#    Then I should not receive an exception