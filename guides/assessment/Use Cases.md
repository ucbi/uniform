# Use Cases

## From a High Level

Uniform is powerful in scenarios in which you want to:

1. Maintain a portfolio of apps
2. Deploy them separately
3. Keep many aspects of them in sync
4. Share capabilities between apps

This makes Uniform especially powerful for software organizations that do not
have an entire team dedicated to each app.

## Enterprises

In our specific use case, we build and maintain apps across companies for a
large enterprise. The companies have their own distinct branding, themes,
deployment pipelines, and assurance processes. However, they share data access
patterns, UI libraries, authentication mechanisms, and many other common
features.

By leveraging Uniform, we're able to perform a change to our *entire portfolio*
of apps in the same time that it would normally take to make the change to a
single app. For example, when we find a security issue in our shared code
architecture, we patch it once and all apps are instantly updated. What could
have been a lengthy process to audit and patch dozens of apps becomes much
simpler and less time-intensive.

Uniform also helps us accomplish _sharing capabilities_ among apps. While
building a feature for a single app, we might create an "autosuggest" UI
component for suggesting live results as the user types in an input field. With
extremely little effort, by simply moving the component out of `lib/that_app`
into `lib/shared_ui_components`, this component becomes instantly available in
all other apps.

## Agencies

Agencies that build custom apps often find themselves pressed for time as they
try to balance the client's financial constraints with feature wishlists and
the health of the codebase.

Uniform can help an agency leverage as much value as possible from their
portfolio of already-built apps as they start new projects. Instead of
rebuilding core pieces like project boilerplate, authentication systems, or
integrations with third party services, those capabilities are available from
the start. (As long as they're built with sharing in mind.)

Furthermore, since Uniform emits standalone codebases for each app, an agency
is able to leverage this extreme level of reuse while still having separate
codebases that belong to each client.
