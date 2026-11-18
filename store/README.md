# store — the curated storefront

KDE Discover already is the store. What we add is a featured listing, which is a
single configuration file plus one JSON document. No code, no custom storefront.

## The mechanism

`/usr/share/discover/featuredurlrc`, shipped by `halcora-branding` and dropped
into the ISO via `airootfs`:

    [Software]
    FeaturedListingURL=https://<our-host>/featured.json

Discover fetches that URL and populates its "Editor's Choice" section from it.
The schema reference is KDE's own live listing:

    https://autoconfig.kde.org/discover/featured-5.9.json

## Why not write a store

Because a storefront is a *policy* surface, not a program, and Discover's is
already the best-maintained one on Linux. Our job is the curation: a list of
applications that a Windows refugee can recognise or immediately understand,
which is a content problem, not a code problem.

## Open questions

- **How much of the package catalogue to expose.** ADR-9 leans towards showing
  only Flatpak in the UI and keeping pacman for our own packages, because a
  user who has never encountered a Python dependency should not meet one by
  accident.
- **Hosting.** Static hosting of one JSON file. Trivial; not yet chosen.
- **The featured list itself.** Phase 4 content work: browsers, media players,
  office, image viewing, a notes app. Deliberately not a long tail — twelve good
  entries beat four hundred.

## Not yet written

Nothing — but nothing is verified either. `featured.json` and `featuredurlrc`
exist, modelled on KDE's own live listing
(`https://autoconfig.kde.org/discover/featured-5.9.json`), which is a plain JSON
array of `appstream://` ids. Nobody has loaded them in Discover.

The URL is `file:///usr/share/halcora/featured.json`, so no hosting is needed.
That works only because the file ships with `halcora-branding`; if the list ever
needs to change without a package update, it has to move to a URL and be hosted.

The twelve entries are chosen for recognisability rather than completeness: a
Windows user should see names they know. Every id assumes a Flatpak remote is
enabled, which is Discover's job and not this file's.
