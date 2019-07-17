Feature: Alert status setting
  As a user which uses noch on my code
  When I define an alert
  I want to set the alert satus

Scenario: Status OK
  Given I required noch on my code
  When I call ok! method
  Then alert status should change to 'ok'

Scenario: Status warning
  Given I required noch on my code
  When I call warning! method
  Then alert status should change to 'warning'

Scenario: Status critical
  Given I required noch on my code
  When I call critical! method
  Then alert status should change to 'critical'

Scenario: Status skip
  Given I required noch on my code
  When I call skip! method
  Then alert status should change to 'skip'

Scenario Outline: Same status does not notify
  Given I required noch on my code
  When I call '<method>' method
  And I call '<method>' method
  Then nothing should happen
Examples:
  |method   |
  |ok!      |
  |warning! |
  |critical!|
  |skip!    |
  