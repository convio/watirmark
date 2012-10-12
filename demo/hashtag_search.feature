Feature: Searches using the hashtag symbol(#) should return a list of tweets containing that hashtag
  Given I am logged in as a twitter user
  When I enter a search using a hashtag
  Then I expect to see a list of results for that hashtag

  Background:
    Given I go to the home page

  Scenario: Searches should only return results matching the hashtag
    When I search for "#blackbaud"
    Then I should only see tweets containing the term "#blackbaud"

  Scenario: The default size of the list should be 20 items
    When I search for "#blackbaud"
    Then the search should contain 20 results

  Scenario: Scrolling to the end of the list should autoload the next 20 matches
    When I search for "#blackbaud"
    And I scroll to the bottom of the page
    Then the next 20 results should load
    And the search should contain 40 results

  Scenario: Hashtags in tweets should show as links
    When I create a new tweet "This is a tweet with a #test hashtag"
    Then the tweet should contain "#test"

  Scenario: Clicking hashtags in tweets should show search results for the hashtag
    When I create a new tweet "This is a tweet to follow with a #test hashtag"
    And I click the hashtag "#test" in the last tweet
    Then I should only see tweets containing the term "#test"

  Scenario: Multiple hashtags should return results containing *all* hashtags defined (AND search)
    When I search for "#blackbaud #winning"
    Then I should only see tweets containing the terms "#blackbaud" and "#winning"

  Scenario: Saving a hashtag search should preserve the hashtag in the search
    When I search for "#blackbaud"
    And I save the search
    Then I should see the search in the dropdown saved searches list
    And I should be able to select the search from that list
    And I should only see tweets containing the term "#blackbaud"

  Scenario: New tweets should periodically show 'N new tweets' at the top of the list
    When I search for "#blackbaud"
    And I create a new tweet "This is a tweet with a #test hashtag using the API" using the API
    Then I should see the new tweets header with "1 new tweet"
    When I click the new tweets header
    Then I should see the tweet "This is a tweet with a #test hashtag using the API"

  Scenario: Empty search results should display the "No tweet results" message
    When I search for "#this_is_an_empty_search_test"
    Then I should see the search message "No tweet results for #this_is_an_empty_search_test"

  Scenario: "Top" Tweets should be the default search list
    When I search for "#blackbaud"
    Then the selected search filter should be "Top"

  Scenario: Clicking "Top" should show the most popular tweets on that hashtag
    When I search for "#blackbaud"
    And I select the search filter "All"
    And I select the search filter "Top"
    Then the selected search filter should be "Top"
    And the tweets should pull from the most popular list for "#blackbaud"

  Scenario: Clicking "All" should show the most recent tweets on that hashtag
    When I search for "#blackbaud"
    And I select the search filter "All"
    Then the selected search filter should be "All"
    And the tweets should pull from the full list for "#blackbaud"

  Scenario: Clicking "People you follow" should only show hashtag tweets from your follow list
    When I search for "#blackbaud"
    And I select the search filter "People you follow"
    Then the selected search filter should be "People you follow"
    And the tweets should pull from the people list for "#blackbaud"

  Scenario: Advanced searches should honor a single hashtag

  Scenario: Advanced searches should honor a multiple hashtags

  Scenario: Promoted tweets should show regardless of the search terms

  Scenario: Hitting the enter button should return the same set of results as clicking the looking glass

  Scenario: Searching for a string (not hashtag) should return results matching the hashtag or the string

