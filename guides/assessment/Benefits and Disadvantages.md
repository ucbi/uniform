# Benefits and Disadvantages

The Eject System is not for everyone, but it can be very powerful in
environments where a team or developer is tasked with developing a large base
of applications that have many similarities or could share many capabilities.

## Benefits

- **Higher leverage to maintain a portfolio of applications.** There is a sense
  of higher return on investment (ROI) as more and more applications are built.
  When you add a new capability, refactor deprecations, or change an
  implementation, the results are automatically incorporated into all of your
  applications.
- **Reduce dependency drift.** Ejected applications derive their Mix and NPM
  dependencies from the Base Project. This eliminates distractions that come
  from supporting multiple versions across a portfolio. No more grappling with
  missing features or incompatible APIs.
- **Faster feedback.** When you change anything shared, your changes are
  automatically made and tested into all applications that could be impacted.
- **Share capabilities with lower overhead.** Any capability that is developed
  for a specific application can be moved into a Lib Dependency. At that point,
  it's instantly available to all other applications in the portfolio.
- **Defer factoring decisions.** In the interest of the DRY (Don't Repeat
  Yourself) principle, there is a motivation to abstract and modularize the
  moment we start adding a feature. Many advocate for the WET principle (Write
  Everything Twice) by contrast, since making abstractions too early can often
  result in an abstraction that "leaks" or is otherwise ill-suited to the
  specific use case. Since the Eject System lowers the amount of overhead for
  shared internal libraries, there are no distinct packages to create up front
  which makes it much easier to refactor as the API evolves.
- **Global Refactors with peace of mind.** When the entire portfolio of
  applications is managed together, we're free to refactor any interal API and
  know that we've addressed all invocations across the enterprise. With Elixir
  compiler warnings and integration tests, CI builds reveal invocations we fail
  to update. In many cases, this eliminates the burden of maintaining backwards
  compatibility, leading to simpler internal libraries.
- **"Release" an ejected app at any time.** If at any point you need to release
  control of an ejected application to another entity such as a different
  development agency, the ejected codebase is already ready as a standalone
  project.
- **Self-healing properties.** - Since `mix eject` starts by deleting the
  contents of the destination codebase, it's possible to modify an ejected
  codebase temporarily, and then "bring it back in sync" with your Base Project
  by running `mix eject` again. Ejecting an app with `mix eject` is meant to be
  something that can be done over and over without preparation or ceremony.

## Disadvantages

- **Novelty.** When new developers join the team, contributors have to learn
  a new way of working.
- **No contributing to ejected codebases.** Changes made directly to an ejected
  codebase cannot be automatically integrated back into the Base Project, so
  contributors must have access to the entire portfolio.
- **Complications from running multiple apps at once.** Your development
  environment is more complicated when you're running an entire suite of apps
  side-by-side. Teams are required to take a disciplined approach to deal with
  some of these complications.
    - For example, the paths of routes would typically be prefixed with the app
      name (e.g. `localhost:4000/my-app/users` instead of
      `localhost:4000/users`), so that paths in your dev environment don't
      exactly match production. One implication is that if you write links like
      this `<a href="/users">` instead of like this `<a href="<%=
      Routes.users_path(...) %>">` the link will work in development but not
      production.
- **Compilation time.** Full recompiles can take a long time for a large
  portfolio of application. Elixir 1.13 has helped out tremendously in this
  regard. On the other hand, you'll often end up with a full recompile when
  changing something in `config/config.exs` which only has relevance to a
  single application.
- **CI burn rate.** We run Continuous Integration (CI) checks for every ejected
  application whenever a commit is made to the Base Project. We suggest you do,
  too. However, this can burn through an order of magnitude more CI minutes.
