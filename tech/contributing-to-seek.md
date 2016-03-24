---
title: contributing to seek
layout: page
redirect_from: "/contributing-to-seek.html"
---

# Contributing to SEEK

We welcome all sorts of contributions to SEEK,  
* **Non-developer contributions.** These are contributions that can be made by anyone
  using SEEK.
  * *Vote and comment other feature requests:* Contact us to get a user within the JIRA issue tracker. This enables you to upvote or downvote features. This helps us in the development process.
  * *Documentation:* Are you reading the documentation and feel something could/should be better explained? Please contact us and/or contribute a fix to the text.
  * *Reporting errors:* We are also thankful if you spot errors or broken links.
* **Developer contributions** These are contributions that can be made by other software
  developers.
  * *Code tidying & bug fixes:* Refactoring to improve quality is always welcome and a good way of starting contributing. They
  * *New features, major improvements, new subsystems:* All of these need communication to check if they can be built in without breaking other efforts.

## Before you start

When considering building or suggesting contribution, please do the following:

1. Read our JIRA issue tracker in order to check that your planned contribution is new.
2. If the contribution is *not new* then *vote the feature on JIRA*
3. If the contribution is *new*, then please contact us.

If you are interested contributing, please first look at our [JIRA issue tracker](http://fair-dom.org/issues), either to find something you can contribute, or whether your
idea already exists. **Before starting** you should also always [Contact Us](/contacting-us.html) first - it is quite possible work is already in progress or we have ideas, and we wouldn't want your
effort to be wasted.

We will work hard to ensure quick communication. For your orientation, please see the following timeline:


### A contribution timeline

For issuing a **bug report**, **feature request** or a **contribution suggestion**, please give a 5-10 line document
* A short description of the feature, bug
* Which version of SEEK are you using? / URL of the SEEK
* Do you want to contribute to the development? When/where?
* Do you want to contribute design or testing work?
* Can you point us to resources, like e.g. source code or tools related to your proposal?

 Within **2 work days** you will receive a receipt, stating that and who will be processing your request. Unless otherwise stated, you will receive within **7 work days** an answer that contains *questions about your suggestion* and/or *an estimation* when we assume that we will start and finish implementing the feature, or maybe feedback that states that we think the feature is already covered. Features in SEEK are implemented in a sprint.

If we decide to implement a feature, we will keep you in the loop: We will:

* Invite you to the virtual development sprint planning meeting in which the feature will be discussed by the developers.
* Invite you to look at intermediate versions of the feature, as well as the final version.

## Changing and contributing code

The SEEK source code is available on GitHub at [https://github.com/seek4science/seek](https://github.com/seek4science/seek)

The easiest way to contribute code (for both us and you) is to do so through GitHub. You can do so by creating a forked repository. Make you changes on a branch within your forked repository.
For large changes you would be advised to link your repository to [Code Climate](https://codeclimate.com) and [Travis](https://travis-ci.org) (see below).

Once you have finished making your changes and wish to contribute them, you can do so by issuing a pull request.

If contributing through GitHub is unfamiliar to you, please read [Contributing to Open Source on GitHub](https://guides.github.com/activities/contributing-to-open-source/)

For small changes emailing a patch file may be suitable.

## Quality control

For a contribution to be accepted, we do have a few requirements.

  * Code should follow the [Ruby Style Guidelines](https://github.com/bbatsov/ruby-style-guide). Our gems include the tool [Rubocop](https://github.com/bbatsov/rubocop), which can be used to check against the guidelines and (with care) automatically fix some issues.
  * Where practical, tests should be added to cover your changes, and all existing tests should pass. The continuous integration tool: [Travis](https://travis-ci.org/seek4science/seek) is useful to checking your tests as your work. _Be pragmatic, don't spend 2 days writing tests for a 5 minute 2 line fix!_
  * We will check quality using [Code Climate](https://codeclimate.com/github/seek4science/seek) for complexity or duplication. You can use [Rubycritic](https://github.com/whitesmith/rubycritic) to check on your local machine.
  * Code should be clear, and in some cases we may request some documentation.